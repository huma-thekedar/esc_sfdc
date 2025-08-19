import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import getSubmissionForProspect from '@salesforce/apex/ESC_NBC_InterviewController.getSubmissionForProspect';
import getInterviewsForProspect from '@salesforce/apex/ESC_NBC_InterviewController.getInterviewsForProspect';
import updateInterviewStatus from '@salesforce/apex/ESC_NBC_InterviewController.updateInterviewStatus'
import getRecordTypeInfoResult from '@salesforce/apex/ESC_NBC_InterviewController.getRecordTypeInfoResult';
import convertToInterview from '@salesforce/apex/ESC_NBC_InterviewController.convertToInterview';
import getContactsForInterviewAccount from '@salesforce/apex/ESC_NBC_InterviewController.getContactsForInterviewAccount'

import NAME_FIELD from '@salesforce/schema/ESC_NBC_Prospect__c.Name';
import { getRecord } from 'lightning/uiRecordApi';

const PASS_LABEL = 'Pass';
const REJECT_LABEL = 'Reject';

export default class Esc_nbc_interviewsDataTable extends NavigationMixin(LightningElement) {

    @api recordId;
    @track options=[];
    value = '';
    @track showRecordTypes = false;
    @track showInterviewFlow = false;
    @track submissions = [];
    @track interviews = [];
    @track decisionedInterviews = [];
    @track showEditModal = false;
    @track selectedInterview;

    @track wiredSubmissionsResult;
    @track wiredInterviewsResult;

    @track showAllSubmission = false;
    @track showAllInterview = false;

    hideCheckbox = false;

    @track draftValues = [];

    interviewColumns;

    @track showInterviewDateModal = false;
    @track interviewDate;
    @track selectedInterviewId;
    @track meetingLink;

    @track interviewerOptions = [];
    @track selectedInterviewerId;
    

    selectedInterviewId;
    selectedStatus;
    showNotesModal = false;
    interviewNotes = '';

    prospectName;

    // Fetch the name of the current Prospect record
    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD] })
    wiredProspect({ error, data }) {
        if (data) {
            this.prospectName = data.fields.Name.value;
        } else if (error) {
            console.error('Error fetching Prospect name:', error);
        }
    }


    connectedCallback() {
        this.getRTInfo();
    }
    get showSpinner() {
        return !this.recordsLoaded;
    }
recordsLoaded =false;

    getRTInfo() {
        getRecordTypeInfoResult()
        .then(result => {
            if (result && result.length) {
                this.options = result.map(record => {
                    const parts = record.split('-');
                    return { label: parts[1], value: parts[0] };
                });
            } else {
                this.options = [];
            }
        }).then(() => {
            this.loadSubmissions();
            }
        )
        .catch(error => {
            console.error('Error fetching record type info:', error);
            this.options = [];
        });
    }

        
     


    submissionColumns = [
       // { label: 'Client Name', fieldName: 'clientName', type: 'text' },
       {
            label: 'Client Name',
            fieldName: 'clientUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'clientName' },
                target: '_blank'
            },
            wrapText: true
        },
        {
            label: 'Position',
            fieldName: 'jobLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'jobPosition' },
                target: '_blank'
            },
            wrapText: true
        },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
       {
            label: 'Actions',
            type: 'button',
            typeAttributes: {
                label: 'Schedule Interview',
                name: 'convertToInterview',
                title: 'Convert Submission to Interview',
                variant: 'brand',
                //iconName: 'utility:briefcase',
                iconPosition: 'left'
            }
        }
    ];


    interviewColumns = [
        //{ label: 'Client Name', fieldName: 'clientName', type: 'text' ,cellAttributes: { class: 'slds-cell-wrap' }},
        {
            label: 'Client Name',
            fieldName: 'clientUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'clientName' },
                target: '_blank'
            },
            cellAttributes: {
                class: 'slds-cell-wrap'
            },
            wrapText: true
        },
        {
            label: 'Position',
            fieldName: 'jobLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'jobPosition' },
                target: '_blank'
            },
            wrapText: true
        },
        /*{
            label: 'Interview Date',
            fieldName: 'Interview_Date__c',
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'short',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                hour12: true
            },
            cellAttributes: { 
                class: 'slds-cell-wrap' ,
                title: { fieldName: 'InterviewDateDisplay' }

            }
        },*/

        {
            label: 'Interview Date',
            fieldName: 'InterviewDateDisplay',
            type: 'text',                      
            cellAttributes: {
                class: 'slds-cell-wrap',
                title: { fieldName: 'InterviewDateDisplay' } 
            },
            wrapText: true
        },

       // { label: 'Interviewer', fieldName: 'interviewerName', type: 'text',cellAttributes: { class: 'slds-cell-wrap' } },
        
        {
            label: 'Interviewer',
            fieldName: 'interviewerUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'interviewerName' },
                target: '_blank' 
            },
            cellAttributes: {
                class: 'slds-cell-wrap'
            },
            wrapText: true
        },

            {
                label: 'Pass',
                type: 'button',
                initialWidth: 100,
                typeAttributes: {
                    label: 'Pass',
                    name: 'markPassed',
                    title: 'Mark Interview as Passed',
                    variant: 'success',
                    iconName: 'utility:check',
                    iconPosition: 'left'
            },
            cellAttributes: { class: 'slds-cell-wrap' },
            
        },
        {
            label: 'Reject',
            type: 'button',
            initialWidth: 100,
            typeAttributes: {
                label: 'Reject',
                name: 'markRejected',
                title: 'Mark Interview as Rejected',
                variant: 'destructive',
                iconName: 'utility:close',
                iconPosition: 'left'
            },
            cellAttributes: { class: 'slds-cell-wrap' }
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'viewRow' },
                    { label: 'Edit', name: 'editRow' }
                ]
            }
        }
    ];

    decisionedColumns = [
        //{ label: 'Client Name', fieldName: 'clientName', type: 'text' },
        {
            label: 'Client Name',
            fieldName: 'clientUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'clientName' },
                target: '_blank'
            },
            wrapText: true
        },
        {
            label: 'Position',
            fieldName: 'jobLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'jobPosition' },
                target: '_blank'
            },
            wrapText: true
        },
        { label: 'Status', fieldName: 'Status__c', type: 'text' ,wrapText: true},
        /*{
            label: 'Interview Date',
            fieldName: 'Interview_Date__c',
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'short',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                hour12: true
            },
            cellAttributes: {
                
                    title: { fieldName: 'InterviewDateDisplay' }
                
            }
            
        },*/

        {
            label: 'Interview Date',
            fieldName: 'InterviewDateDisplay',
            type: 'text',
            cellAttributes: {
                title: { fieldName: 'InterviewDateDisplay' }
            },
            wrapText: true
        },

        //{ label: 'Interviewer', fieldName: 'interviewerName', type: 'text' }
        {
            label: 'Interviewer',
            fieldName: 'interviewerUrl', 
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'interviewerName' },
                target: '_blank' 
            },
            cellAttributes: {
                class: 'slds-cell-wrap'
            },
            wrapText: true
        },
    ];

        loadSubmissions() {
            this.recordsLoaded = false;
            getSubmissionForProspect({ prospectId: this.recordId })
                .then(data => {
                    this.wiredSubmissionsResult = { data };

                    this.submissions = this.sortByInterviewDate(
                        data.map(item => {
                            const clientName = item.Job_Opening__r?.Client__r?.Name || '';
                            const clientId = item.Job_Opening__r?.Client__c;
                            const clientUrl = clientId ? '/' + clientId : '';

                            return {
                                ...item,
                                clientName,
                                clientId,
                                clientUrl,
                                jobPosition: item.Job_Opening__r?.Position__c || '',
                                jobLink: '/' + (item.Job_Opening__r?.Id || '')
                            };
                        })
                    );
                }).then( () => {
                    this.loadInterviews();

                })
                .catch(error => {
                    this.recordsLoaded = true;
                    this.wiredSubmissionsResult = { error };
                    console.error('Submission error:', error);
                });
        }

       loadInterviews() {
        getInterviewsForProspect({ prospectId: this.recordId })
            .then(data => {
                this.wiredInterviewsResult = { data };

                const all = data.map(item => {
                    // Format Interview Date for tooltip/display
                    let formattedDate = '';
                    // if (item.Interview_Date__c) {
                    //     const dateObj = new Date(item.Interview_Date__c);
                    //     formattedDate = dateObj.toLocaleString(undefined, {
                    //         weekday: 'long',
                    //         month: 'short',
                    //         day: '2-digit',
                    //         hour: '2-digit',
                    //         minute: '2-digit',
                    //         hour12: true
                    //     });
                    // }
if (item.Interview_Date__c) {
    const dateObj = new Date(item.Interview_Date__c);
    formattedDate = dateObj.toLocaleString('en-US', {
        timeZone: 'Etc/GMT+7', // Fixed GMT-7 with no daylight saving time
         weekday: 'short',
        month: 'short',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
    });
}


                    // Get Client info for clickable links
                    const clientName = item.Job_Opening__r?.Client__r?.Name || '';
                    const clientId = item.Job_Opening__r?.Client__c;
                    const clientUrl = clientId ? '/' + clientId : '';

                    // Get Interviewer info for clickable link
                    const interviewerName = item.Interviewer_Name__r?.Name || '';
                    const interviewerId = item.Interviewer_Name__c;
                    const interviewerUrl = interviewerId ? '/' + interviewerId : '';

                    return {
                        ...item,
                        interviewerName,
                        interviewerId,
                        interviewerUrl,
                        clientName,
                        clientId,
                        clientUrl,
                        jobPosition: item.Job_Opening__r?.Position__c || '',
                        jobLink: '/' + (item.Job_Opening__r?.Id || ''),
                        InterviewDateDisplay: formattedDate
                    };
                });

                const sortedAll = this.sortByInterviewDate(all);
                this.interviews = sortedAll.filter(i => i.Status__c !== 'Selected' && i.Status__c !== 'Rejected');
                this.decisionedInterviews = sortedAll.filter(i => i.Status__c === 'Selected' || i.Status__c === 'Rejected');
                    this.recordsLoaded = true;

            })
            .catch(error => {
                this.wiredInterviewsResult = { error };
                console.error('Interview error:', error);
            });
    }

    sortByInterviewDate(interviews) {
        // Add sorting logic here if not already defined
        return interviews.sort((a, b) => new Date(a.Interview_Date__c) - new Date(b.Interview_Date__c));
    }



    get submissionCount() {
        return this.submissions?.length || 0;
    }

    get interviewCount() {
        return this.interviews?.length || 0;
    }

    get submissionTitle() {
        return `Submissions (${this.submissionCount})`;
    }

    get interviewTitle() {
        return `Interviews (${this.interviewCount})`;
    }

    

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        console.log('Action Clicked:', actionName);
        switch (actionName) {
            case 'editRow':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        objectApiName: 'Interview__c',
                        actionName: 'edit'
                    }
                });
                break;
            case 'markPassed':
            case 'markRejected':
                this.selectedInterviewId = row.Id;
                this.selectedStatus = actionName === 'markPassed' ? 'Selected' : 'Rejected';
                this.interviewNotes = row.ESC_NBC_Interview_Notes__c || '';
                this.showNotesModal = true;
                break;

            case 'convertToInterview':
                this.openInterviewDateModal(row.Id);
                break;
            
            case 'viewRow':
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        objectApiName: 'Interview__c',
                        actionName: 'view'
                    }
                }).then(url => {
                    window.open(url, '_blank');
                });
                break;

                
            default:
                break;
        }
    }






    closeModal() {
        this.showEditModal = false;
        this.selectedInterview = null;
    }

    handleSuccess() {
        this.showToast('Success', 'Interview updated successfully', 'success');
        this.closeModal();
        return Promise.all([
            // refreshApex(this.wiredSubmissionsResult),
            // refreshApex(this.wiredInterviewsResult)
            this.loadSubmissions()
        ]);
    }

    handleError(event) {
        const error = event.detail;
        this.showToast('Error', error.message || 'Something went wrong', 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }


    get visibleSubmissionRecords() {
    return this.showAllSubmission ? this.submissions : this.submissions.slice(0, 10);
}

    get visibleInterviewRecords() {
        return this.showAllInterview ? this.interviews : this.interviews.slice(0, 10);
    }

    get showViewAllSubmission() {
    return this.submissions.length > 10 && !this.showAllSubmission;
}

    get showViewAllInterview() {
        return this.interviews.length > 10 && !this.showAllInterview;
    }

    handleViewAllSubmission() {
    this.showAllSubmission = true;
}

    handleViewAllInterview() {
        this.showAllInterview = true;
    }

        updateInterviewStatus(interviewId, status) {
            updateInterviewStatus({ interviewId, status })
                .then(() => {
                    this.showToast('Success', 'Interview marked as' +  status, 'success');
                    // return refreshApex(this.wiredInterviewsResult);
                    this.loadInterviews();
                })
                .catch(error => {
                    console.error('Error updating status:', error);
                    this.showToast('Error', 'Failed to update interview status', 'error');
                });
        }



    get visibleDecisionedRecords() {
        return this.decisionedInterviews;
    }

    sortByInterviewDate(records) {
        return records.slice().sort((a, b) => {
            const dateA = a.Interview_Date__c ? new Date(a.Interview_Date__c) : new Date(0);
            const dateB = b.Interview_Date__c ? new Date(b.Interview_Date__c) : new Date(0);
            return dateA - dateB;
        });
    }

    handleSaveNotes() {
        console.log('Saving Notes for:', this.selectedInterviewId, 'Status:', this.selectedStatus);
        updateInterviewStatus({ 
            interviewId: this.selectedInterviewId, 
            status: this.selectedStatus,
            notes: this.interviewNotes

        })
        .then(() => {
            this.showNotesModal = false;
            this.selectedInterviewId = null;
            this.showToast('Success', 'Interview marked as ' + this.selectedStatus, 'success');

            this.selectedStatus = null;
            this.interviewNotes = '';
            // return refreshApex(this.wiredInterviewsResult);
            this.loadSubmissions();
        })
        .catch(error => {
            console.error('Error updating interview:', error);
            this.showToast('Error', 'Failed to update interview', 'error');
        });
    }


    handleNotesChange(event) {
        this.interviewNotes = event.target.value;
    }

    handleCancelNotes() {
        this.showNotesModal = false;
        this.selectedInterviewId = null;
        this.selectedStatus = null;
        this.interviewNotes = '';
    }



    handleNewClick() {
        this.showRecordTypes = true;
    }


    handleRTSelection(event){
        console.log('selected option ->',event.detail.value);
        this.value = event.detail.value;
    }

    closeRecordTypeModal(event){
        this.showRecordTypes = false;
    }

   
        handleNext() {
            const contextObject = {
                attributes: {
                    objectApiName: 'ESC_NBC_Prospect__c',
                    recordId: this.recordId,
                    actionName: 'view'
                }
            };
            const encodedContext = 'a.' + btoa(JSON.stringify(contextObject));

            // Debug logs - confirm these print correctly each time
            console.log('[LWC] handleNext - recordId:', this.recordId);
            console.log('[LWC] handleNext - encoded inContextOfRef:', encodedContext);
            console.log('[LWC] handleNext - recordTypeId:', this.value);
            
            this[NavigationMixin.Navigate]({
                type: 'standard__component',
                attributes: {
                    componentName: 'c__newInterviewWrapper'
                },
                state: {
                    inContextOfRef: encodedContext, 
                    recordTypeId: this.value
                }
            });
        }



    get isSaveDisabled() {
        return this.value === '';
    }


    convertSubmissionToInterview(recordId) {
        console.log('inside conversion --> ',recordId)
        convertToInterview({ interviewId: recordId })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Submission converted to Interview successfully',
                    variant: 'success'
                }));
                // return refreshApex(this.wiredSubmissionsResult);
                this.loadSubmissions();
            })
            .catch(error => {
                console.error('Error converting submission:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to convert submission',
                    variant: 'error'
                }));
            });
    }

    handleInterviewDateChange(event) {
        this.interviewDate = event.detail.value;
    }

    closeInterviewDateModal() {
        this.showInterviewDateModal = false;
        this.selectedInterviewId = null;
        this.interviewDate = null;
    }

    saveInterviewDate() {

            if (!this.interviewDate) {
                this.showToast('Error', 'Please enter an Interview Date.', 'error');
                return;
            }

            // Call Apex to update the record
            convertToInterview({ 
                interviewId: this.selectedInterviewId, 
                interviewDate: new Date(this.interviewDate), 
                zoomMeetingLink: this.meetingLink,
                interviewerContactId: this.selectedInterviewerId
            })
            .then(() => {
                this.showToast('Success', 'Submission converted to Interview successfully.', 'success');
                this.closeInterviewDateModal();

                // Refresh lists to reflect changes
                // return refreshApex(this.wiredSubmissionsResult).then(() => refreshApex(this.wiredInterviewsResult));
                this.loadSubmissions();
            })
            .catch(error => {
                console.error('Error converting submission:', error);
                this.showToast('Error', 'Failed to convert submission', 'error');
            });
        }

    handleNewInterviewCreation() {
        if (!this.recordId || !this.prospectName) {
            console.warn('Missing recordId or prospectName');
            return;
        }

        const shortRecordId = this.recordId.substring(0, 15);
        const encodedName = encodeURIComponent(this.prospectName);

        // Replace this with your Interview's actual field ID if needed
        const saveNewUrl = `/a04/e?CF00NV1000003j64L=${encodedName}&CF00NV1000003j64L_lkid=${shortRecordId}`;

        const context = {
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'ESC_NBC_Prospect__c',
                recordId: shortRecordId,
                actionName: 'view'
            },
            state: {}
        };

        function safeBtoa(str) {
            return btoa(
                encodeURIComponent(str)
                    .replace(/%([0-9A-F]{2})/g, (match, p1) =>
                        String.fromCharCode('0x' + p1)
                    )
            );
        }


        const inContextOfRef = '1.' + safeBtoa(JSON.stringify(context));
        const backgroundContext = `/lightning/r/ESC_NBC_Prospect__c/${this.recordId}/view`;

        const url = `/lightning/o/Interview__c/new` +
            `?navigationLocation=RELATED_LIST` +
            `&saveNewUrl=${encodeURIComponent(saveNewUrl)}` +
            `&nooverride=true` +
            `&useRecordTypeCheck=1` +
            `&inContextOfRef=${inContextOfRef}` +
            `&count=1` +
            `&backgroundContext=${encodeURIComponent(backgroundContext)}`;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }



    handleMeetingLinkChange(event) {
        this.meetingLink = event.target.value;
    }

    openInterviewDateModal(interviewId) {
        this.selectedInterviewId = interviewId;
        this.interviewDate = null;
        this.meetingLink = null;
        this.selectedInterviewerId = null;
        this.interviewerOptions = [];

        getContactsForInterviewAccount({ interviewId })
            .then(result => {
                this.interviewerOptions = result.map(contact => ({ label: contact.Name, value: contact.Id }));
            })
            .catch(error => {
                console.error('Error fetching interviewer contacts:', error);
                this.interviewerOptions = [];
            });

        this.showInterviewDateModal = true;
    }

    handleInterviewerChange(event) {
        this.selectedInterviewerId = event.detail.value;
    }

           // @wire(getInterviewsForProspect, { prospectId: '$recordId' })
        // wiredInterviews(result) {
        //     this.wiredInterviewsResult = result;
        //     const { error, data } = result;
        //     if (data) {
        //         const all = data.map(item => {
        //             // Format Interview Date for tooltip/display
        //             let formattedDate = '';
        //             if (item.Interview_Date__c) {
        //                 const dateObj = new Date(item.Interview_Date__c);
        //                 formattedDate = dateObj.toLocaleString(undefined, {
        //                     weekday: 'long',
        //                     //year: 'numeric',
        //                     month: 'short',
        //                     day: '2-digit',
        //                     hour: '2-digit',
        //                     minute: '2-digit',
        //                     hour12: true
        //                 });
        //             }

        //             // Get Client info for clickable links
        //             const clientName = item.Job_Opening__r?.Client__r?.Name || '';
        //             const clientId = item.Job_Opening__r?.Client__c;
        //             const clientUrl = clientId ? '/' + clientId : '';

        //             // Get Interviewer info for clickable link
        //             const interviewerName = item.Interviewer_Name__r ? item.Interviewer_Name__r.Name : '';
        //             const interviewerId = item.Interviewer_Name__c;
        //             const interviewerUrl = interviewerId ? '/' + interviewerId : '';

        //             return {
        //                 ...item,
        //                 interviewerName,
        //                 interviewerId,
        //                 interviewerUrl,
        //                 clientName,
        //                 clientId,
        //                 clientUrl,
        //                 jobPosition: item.Job_Opening__r?.Position__c || '',
        //                 jobLink: '/' + (item.Job_Opening__r?.Id || ''),
        //                 InterviewDateDisplay: formattedDate
        //             };
        //         });

        //         const sortedAll = this.sortByInterviewDate(all);
        //         this.interviews = sortedAll.filter(i => i.Status__c !== 'Selected' && i.Status__c !== 'Rejected');
        //         this.decisionedInterviews = sortedAll.filter(i => i.Status__c === 'Selected' || i.Status__c === 'Rejected');
        //     } else if (error) {
        //         console.error('Interview error:', error);
        //     }
        // }


}