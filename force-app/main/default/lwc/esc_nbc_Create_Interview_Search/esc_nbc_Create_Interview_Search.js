import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getActiveJobOpeningsForClient from '@salesforce/apex/ESC_NBC_JobOpeningController.getActiveJobOpeningsForClient';
import getContactsForClient from '@salesforce/apex/ESC_NBC_JobOpeningController.getContactsForClient';
import getJobOpeningInfo from '@salesforce/apex/ESC_NBC_JobOpeningController.getJobOpeningInfo'

export default class Esc_nbc_Create_Interview_Search extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api recordTypeName;
    @api sObjectName;
    hideClientSearch = false;

    @track launchedFromProspect = false;
    @track launchedFromJobOpening = false;

    @api prospectId;
    @api jobOpeningId;
    //@api jobOpeningName;
    @api defaultRecordName;

    @track jobOpeningName = '';
    @track launchedFromInterview = false;

    @track interviewerName = '';
    @track allInterviewers = [];
    @track filteredInterviewers = [];
    @track showInterviewerSuggestions = false;
    interviewerNameDisabled = true;

    clientFilter = {
        criteria: [
            {
                fieldPath: 'ESC_NBC_Active__c',
                operator: 'eq',
                value: true,
            },
        ],
        filterLogic: '1',
    };

    get disableJobOpening() {
        if (this.objectApiName == 'Job_Opening__c') {
            this.jobOpeningId = this.recordId;
            this.hideClientSearch = true;
        }
        return this.objectApiName == 'Job_Opening__c' || !this.accountId;
    }

    // get launchedFromProspect() {
    //     console.log('launched from prospect->', this.recordId)
    //     if (this.objectApiName == 'ESC_NBC_Prospect__c') {
    //         this.prospectId = this.recordId;
            
    //     }
    //     return this.objectApiName == 'ESC_NBC_Prospect__c';
    // }

    get isInterviewRecordType() {
        return this.recordTypeName == 'Interview';
    }

    prospectFilter = {
        criteria: [
            {
                fieldPath: 'ESC_NBC_RecordType_Name__c',
                operator: 'eq',
                value: 'Active Prospect',
            },
        ],
        filterLogic: '1',
    };

    get jobOpeningfilter() {
        return {
            criteria: [
                {
                    fieldPath: 'Client__c',
                    operator: 'eq',
                    value: this.accountId ? this.accountId : null,
                },
                {
                    fieldPath: 'Status__c',
                    operator: 'eq',
                    value: 'Active',
                },
            ],
            filterLogic: '1 AND 2',
        };
    }

    get interviewerFilter() {
        return {
            criteria: [
                {
                    fieldPath: 'AccountId',
                    operator: 'eq',
                    value: this.accountId ? this.accountId : null,
                },
            ],
            filterLogic: '1',
        };
    }

    value;
    @api accountId;
    //@track accountId;
    
    @api contactId;


    jobOpeningDisabled = true;
    interviewerNameDisabled;

    // New props for custom job opening input
    //@track jobOpeningName = '';
    @track allJobOpenings = [];
    @track filteredJobOpenings = [];
    @track showJobSuggestions = false;

    handleValueChange(event) {
        let value = event.detail.recordId;
        this.value = value;
        let objectName = event.target.label;

        if (objectName === 'Client') {
            this.accountId = value;

            if (value) {
                this.jobOpeningDisabled = false;
                this.interviewerNameDisabled = false;
                this.fetchJobOpenings(value);
                this.fetchInterviewers(value);
            } else {
            this.jobOpeningDisabled = true;
            this.jobOpeningName = '';
            this.jobOpeningId = null;
            this.filteredJobOpenings = [];
            this.allJobOpenings = [];
            this.showJobSuggestions = false;

            this.interviewerNameDisabled = true;
            this.interviewerName = '';
            this.contactId = null;
            this.filteredInterviewers = [];
            this.allInterviewers = [];
            this.showJobSuggestions = false;
            this.showInterviewerSuggestions = false;

            }
        } else if (objectName == 'Prospect') {
            this.prospectId = value || this.prospectId;
        } else if (objectName == 'Job Opening') {
            this.jobOpeningId = value || this.jobOpeningId;
        } else if (objectName == 'Interviewer Name') {
            this.contactId = value;
        }

        ["accountId", "prospectId", "jobOpeningId", "contactId"].forEach((loc) =>
            this.dispatchEvent(new FlowAttributeChangeEvent(loc, this[loc]))
        );

        console.log('value: ' + value);
        console.log('objectname: ' + objectName);
    }

    /*fetchJobOpenings(clientId) {
        getActiveJobOpeningsForClient({ clientId })
            .then((data) => {
                this.allJobOpenings = data;
                this.filteredJobOpenings = data;
            })
            .catch((error) => {
                console.error('Error fetching job openings:', error);
                this.allJobOpenings = [];
                this.filteredJobOpenings = [];
            });
    }*/

            fetchJobOpenings(clientId) {
                getActiveJobOpeningsForClient({ clientId })
                    .then((data) => {
                        this.allJobOpenings = data;
                        this.filteredJobOpenings = data;

                        // Ensure UI preselects the job opening if it exists
                        if (this.jobOpeningId && this.launchedFromJobOpening) {
                            const matched = data.find(job => job.Id === this.jobOpeningId);
                            if (matched) {
                                this.jobOpeningName = matched.Name;
                            }
                        }
                    })
                    .catch((error) => {
                        console.error('Error fetching job openings:', error);
                        this.allJobOpenings = [];
                        this.filteredJobOpenings = [];
                    });
            }



    fetchInterviewers(clientId) {
        getContactsForClient({ clientId })
            .then((data) => {
                this.allInterviewers = data;
                this.filteredInterviewers = data;
            })
            .catch((error) => {
                console.error('Error fetching interviewers:', error);
                this.allInterviewers = [];
                this.filteredInterviewers = [];
            });
    }

    handleJobInputChange(event) {
        this.jobOpeningName = event.target.value;
        this.filterJobSuggestions();
    }

    handleJobInputFocus() {
        this.showJobSuggestions = true;
        this.filterJobSuggestions(); // show all if nothing typed
    }

    filterJobSuggestions() {
        const term = this.jobOpeningName.toLowerCase();
        this.filteredJobOpenings = this.allJobOpenings.filter(
            job => job.Name.toLowerCase().includes(term)
        );
    }

    handleJobSelect(event) {
        const jobId = event.currentTarget.dataset.id;
        const jobName = event.currentTarget.dataset.name;

        this.jobOpeningId = jobId;
        this.jobOpeningName = jobName;
        console.log()
        this.showJobSuggestions = false;

        this.dispatchEvent(new FlowAttributeChangeEvent('jobOpeningId', this.jobOpeningId));

        const inputEl = this.template.querySelector('.search-input');
        if (inputEl) {
            inputEl.setCustomValidity('');
            inputEl.reportValidity();
        }



         const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputField) => {
            
            if(inputField.name == 'jobOpening'){
                if(!this.jobOpeningId){
                    inputField.setCustomValidity("Job Opening is required.");
                }else inputField.setCustomValidity("");
            }
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);
    }

    /*connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);

        if (this.objectApiName === 'ESC_NBC_Prospect__c') {
            this.launchedFromProspect = true;
            this.prospectId = this.recordId;
        } else if (this.objectApiName === 'Job_Opening__c') {
            this.launchedFromJobOpening = true;
            this.jobOpeningId = this.recordId;
        }

        if (!this.accountId) {
            this.jobOpeningDisabled = true;
            this.interviewerNameDisabled = true;
        }
        
        
        setTimeout(() => {
            this.template.addEventListener('mousedown', this.handleInsideClick);
        }, 0);
        document.addEventListener('mousedown', this.handleOutsideClick);

        ["accountId", "prospectId", "jobOpeningId"].forEach((loc) =>
        this.dispatchEvent(new FlowAttributeChangeEvent(loc, this[loc]))
        );

    }*/

        /*connectedCallback() {
            const urlParams = new URLSearchParams(window.location.search);

            if (this.objectApiName === 'ESC_NBC_Prospect__c') {
                this.launchedFromProspect = false;
                this.prospectId = this.recordId;
            } else if (this.objectApiName === 'Job_Opening__c') {
                this.launchedFromJobOpening = true;
                this.jobOpeningId = this.recordId;
            }

            // Fetch Job Opening info if launched from Job Opening record
            if (this.launchedFromJobOpening && this.jobOpeningId) {
                console.log('inside if job opening of launching from job opening')
                console.log('jobOpeningId:: ' , this.jobOpeningId)
                console.log('this.launchedFromJobOpening: ' , this.launchedFromJobOpening)
            
                getJobOpeningInfo({ jobOpeningId: this.jobOpeningId })
                    .then((job) => {
                        console.log('insde getJobOpeningInfo --->> ',job.Client__c)
                        this.jobOpeningName = job.Name;
                        this.jobOpeningId = job.Id;
                        this.accountId = job.Client__c;

                        this.jobOpeningDisabled = false;
                        this.interviewerNameDisabled = false;

                        this.fetchJobOpenings(this.accountId);
                        // Fetch interviewer suggestions now that account is known
                        
                        this.fetchInterviewers(this.accountId);

                        // Notify Flow of updated values
                        ["accountId", "jobOpeningId"].forEach((loc) =>
                            this.dispatchEvent(new FlowAttributeChangeEvent(loc, this[loc]))
                        );
                    })
                    .catch((err) => {
                        console.error('Error fetching Job Opening info:', err);
                    });
            } else {
                // If accountId is not already set, disable related fields
                if (!this.accountId) {
                    console.log('in the else condition')
                    this.jobOpeningDisabled = true;
                    this.interviewerNameDisabled = true;
                }

                // Dispatch Flow attributes as usual
                ["accountId", "prospectId", "jobOpeningId"].forEach((loc) =>
                    this.dispatchEvent(new FlowAttributeChangeEvent(loc, this[loc]))
                );
            }

            // Suggestion box listeners
            setTimeout(() => {
                this.template.addEventListener('mousedown', this.handleInsideClick);
            }, 0);
            document.addEventListener('mousedown', this.handleOutsideClick);
        }*/

        connectedCallback() {
            const urlParams = new URLSearchParams(window.location.search);

            if (this.objectApiName === 'ESC_NBC_Prospect__c') {
                this.launchedFromProspect = true;  
                this.prospectId = this.recordId;
                console.log('launchedFromProspect?', this.launchedFromProspect);

            } else if (this.objectApiName === 'Job_Opening__c') {
                this.launchedFromJobOpening = true;
                this.jobOpeningId = this.recordId;
            }

            if (this.launchedFromJobOpening && this.jobOpeningId) {
                getJobOpeningInfo({ jobOpeningId: this.jobOpeningId })
                    .then((job) => {
                        this.jobOpeningName = job.Name;
                        this.jobOpeningId = job.Id;
                        this.accountId = job.Client__c;

                        this.jobOpeningDisabled = false;
                        this.interviewerNameDisabled = false;

                        this.fetchJobOpenings(this.accountId);
                        this.fetchInterviewers(this.accountId);

                        ["accountId", "jobOpeningId"].forEach((loc) =>
                            this.dispatchEvent(new FlowAttributeChangeEvent(loc, this[loc]))
                        );
                    })
                    .catch((err) => {
                        console.error('Error fetching Job Opening info:', err);
                    });
            } else {
                if (!this.accountId) {
                    this.jobOpeningDisabled = true;
                    this.interviewerNameDisabled = true;
                }

                ["accountId", "prospectId", "jobOpeningId"].forEach((loc) =>
                    this.dispatchEvent(new FlowAttributeChangeEvent(loc, this[loc]))
                );
            }

            setTimeout(() => {
                this.template.addEventListener('mousedown', this.handleInsideClick);
            }, 0);
            document.addEventListener('mousedown', this.handleOutsideClick);
        }




    disconnectedCallback() {
        this.template.removeEventListener('mousedown', this.handleInsideClick);
        document.removeEventListener('mousedown', this.handleOutsideClick);
    }


    handleInsideClick = (event) => {
        this._clickedInside = true;
    };

    /*handleOutsideClick = (event) => {
        if (this._clickedInside) {
            this._clickedInside = false;
            return;
        }

        this.showJobSuggestions = false;
    };*/

    handleOutsideClick = () => {
        if (this._clickedInside) {
            this._clickedInside = false;
            return;
        }

        // Hide all dropdowns/suggestion boxes
        this.closeAllSuggestions();
    };
    

    closeAllSuggestions() {
        this.showJobSuggestions = false;
        this.showInterviewerSuggestions = false;
    }


    get prospectCssClass() {
        return this.launchedFromProspect ? 'slds-hide' : '';
    }

    get jobOpeningCssClass() {
        return this.launchedFromJobOpening ? 'slds-hide' : '';
    }


    handleInterviewerInputChange(event) {
        this.interviewerName = event.target.value;
        this.filterInterviewerSuggestions();
    }

    handleInterviewerInputFocus() {
        this.showInterviewerSuggestions = true;
        this.filterInterviewerSuggestions(); // show all if empty
    }

    filterInterviewerSuggestions() {
        const term = this.interviewerName?.toLowerCase() || '';
        this.filteredInterviewers = this.allInterviewers.filter(
            interviewer => interviewer.Name.toLowerCase().includes(term)
        );
    }

    handleInterviewerSelect(event) {
        const contactId = event.currentTarget.dataset.id;
        const contactName = event.currentTarget.dataset.name;

        this.contactId = contactId;
        this.interviewerName = contactName;
        this.showInterviewerSuggestions = false;

        this.dispatchEvent(new FlowAttributeChangeEvent('contactId', this.contactId));
        
        /*const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                if (inputField.name === 'interviewerName') {
                    if (!this.contactId) {
                        inputField.setCustomValidity("Interviewer is required.");
                    } else inputField.setCustomValidity("");
                }
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);*/
    }



    /*get isClientDisabled() {
        return this.launchedFromProspect || this.launchedFromJobOpening;
    }*/

    get isClientDisabled() {
        return this.launchedFromJobOpening; // only disable if launched from Job Opening
    }


    get isJobOpeningDisabled() {
        return this.launchedFromJobOpening || this.jobOpeningDisabled;
    }

    get isProspectDisabled() {
        return this.launchedFromProspect;
    }


}