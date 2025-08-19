import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSearchLocation from '@salesforce/apex/ESC_NBC_Job_Controller.getSearchLocation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import City_FIELD from "@salesforce/schema/Job_Opening__c.Address__c";
import Country_FIELD from "@salesforce/schema/Job_Opening__c.Address__c";
import Zip_FIELD from "@salesforce/schema/Job_Opening__c.Address__c";
import State_FIELD from "@salesforce/schema/Job_Opening__c.Address__c";
import Street_FIELD from "@salesforce/schema/Job_Opening__c.Address__c";
import ESCResource from '@salesforce/resourceUrl/ESCResource';
import { loadStyle } from 'lightning/platformResourceLoader';
import getPicklistValues from '@salesforce/apex/NBC_Picklist_Controller.getPicklistValues';
//import ESC_NBC_WrappedHeaderJobSearch from '@salesforce/resourceUrl/ESC_NBC_WrappedHeaderJobSearch';
loadStyle(this, ESCResource + '/main.css');

const fields = [City_FIELD, Country_FIELD, Zip_FIELD, State_FIELD, Street_FIELD];

export default class ESC_NBC_JobSearch extends NavigationMixin(LightningElement) {
    @track jobStatusOptions;
    @track jobStatus = 'None';


    show = true;
    @api showListView = false;
    @api recordId;
    value;
    recordTypeValue= '';
    @track columns = [
        {
            label: 'Name',
            fieldName: 'value',  // Store record ID here
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'jobTitle' }, // Show Title as text
                name: 'navigateToRecord',
                variant: 'base'  // Makes it look like a hyperlink
            },
            wrapText: true
            , hideDefaultActions: true
        },
        { label: 'Posting Date', fieldName: 'jobCreatedDatel', type: 'date',wrapText: true , hideDefaultActions: true},
        { label: 'Client', fieldName: 'ClientName', type: 'text',wrapText: true , hideDefaultActions: true},
        { label: 'City', fieldName: 'addressCity', type: 'text',wrapText: true, hideDefaultActions: true },
        { label: 'State', fieldName: 'addressStateCode', type: 'text',wrapText: true , hideDefaultActions: true},
        { label: 'ZIP Code', fieldName: 'addressPostalCode', type: 'text', wrapText: true, hideDefaultActions: true},
        { label: 'Type', fieldName: 'employmentType', type: 'text' ,wrapText: true, hideDefaultActions: true},
        { label: 'Source', fieldName: 'leadSource', type: 'text',wrapText: true , hideDefaultActions: true},
        { label: 'Status', fieldName: 'leadstatus', type: 'text', wrapText: true, hideDefaultActions: true },

        { label: 'Owner Alias', fieldName: 'ownerName', type: 'text',wrapText: true, hideDefaultActions: true },
    ];
    jobOpening;
    searchmiles = 10;
    street = '';
    city = '';
    country = '';
    province = '';
    postalcode = '';
    latlong;
    zoomLevel = 15;
    mapMarkers = [];
    datafound = false;
    mapMarkersList = [];
    jobTitleOption;
    jobType;
    filteredData = [];
    filterMapMarkers = [];
    connectedCallback() {
        //this.getJobTitleOption();
        this.getJobStatusOptions();
    }

    stylesLoaded = false;

    get filteredDataLength(){
        return this.mapMarkersList.length == 0 ? true : false;
    }

    /*getJobTitleOption() {
        getPicklistValues({ objectName: 'Job_Opening__c', fieldName: 'Employment_Type__c' })
            .then((result) => {
                this.jobTitleOption = result;
            }).catch((err) => {
                console.error(err);
            });
    }*/

    /*getJobStatusOptions() {
        getPicklistValues({ objectName: 'Job_Opening__c', fieldName: 'Status__c' })
            .then((result) => {
                console.log('Picklist Options:', JSON.stringify(result));
                this.jobStatusOptions = result;
            }).catch((err) => {
                console.error('Error fetching Status__c picklist:', err);
            });
    }*/

    getJobStatusOptions() {
        getPicklistValues({ objectName: 'Job_Opening__c', fieldName: 'Status__c' })
            .then((result) => {
                // Always start with 'None'
                let filtered = [{ label: 'None', value: 'None' }];

                // Filter only 'Active' and 'Inactive'
                result.forEach(item => {
                    if (item.value === 'Active' || item.value === 'Inactive') {
                    filtered.push(item);
                    }
                });

                this.jobStatusOptions = filtered;
            })
            .catch((err) => {
             console.error('Error fetching Status__c picklist:', err);
         });
    }


    addressInputChange(event) {
        this.street = event.target.street;
        this.city = event.target.city;
        this.country = event.target.country;
        this.province = event.target.province;
        this.postalcode = event.target.postalCode;
        this.datafound = false;
        this.jobType = 'None';
        this.fetchList();

    }

    handleRecordTypeChange(event) {
        this.recordTypeValue = event.target.value;
        this.filterData();
    }

    fetchList() {
        let completeAdd = [];
        if (this.street) {
            completeAdd.push(this.street);
        }
        if (this.city) {
            completeAdd.push(this.city);
        }
        if (this.province) {
            completeAdd.push(this.province);
        }
        if (this.postalcode) {
            completeAdd.push(this.postalcode);
        }
        if (this.country) {
            completeAdd.push(this.country);
        }
        if (completeAdd.length > 0) {
            this.mapMarkers = [];
            console.log('completeAdd' + completeAdd);
            getSearchLocation({ addressVal: completeAdd.join("+"), miles: this.searchmiles })
                .then((result) => {
                    if (result == "Error") {
                        const event = new ShowToastEvent({
                            message: "Please enter valid address and try again",
                            variant: "error",
                            mode: "sticky"
                        });
                        this.dispatchEvent(event);
                    }
                    else {
                        console.log('result', JSON.stringify(result));
                        this.mapMarkers = JSON.parse(result);
                        this.filterMapMarkers = this.mapMarkers;
                        console.log('marker ' + this.mapMarkers.length);
                        this.mapMarkersList = [];
                        if (this.mapMarkers.length > 2) {
                            this.mapMarkersList = this.mapMarkers.slice(2, this.mapMarkers.length);
                            this.datafound = true;
                            this.filteredData = this.mapMarkersList;

                            this.filterData();
                        }
                        console.log('filterMapMarkers ' + this.filterMapMarkers.length);
                    }

                })
                .catch(error => {
                    console.error(error);
                })
        }
    }

    handleListClick(event) {
        if (event.target.dataset.id) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.target.dataset.id,
                    objectApiName: 'Lead',
                    actionName: 'view'
                }
            }).then(generatedUrl => {
                window.open(generatedUrl);
            });
        }
    }
    milesUpdated(event) {
        this.searchmiles = 0;
        if (event.target.value)
            this.searchmiles = event.target.value;
        this.jobType = 'None';
        this.fetchList();
    }

    getRowActions(row, doneCallback) {
        const actions = [
            { label: 'View', name: 'view' },
            { label: 'Edit', name: 'edit' },
            { label: 'Delete', name: 'delete' }
        ];
        doneCallback(actions);
    }
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log('account'+JSON.stringify(row));

        if (actionName === 'navigateToRecord') {
            console.log('Clicked');
            this.navigateToRecord(row.value); // Navigate using record ID
        } else {
            switch (actionName) {
                case 'view':
                    this.navigateToRecord(row.value);
                    break;
                case 'edit':
                    console.log('Edit action:', row);
                    break;
                case 'delete':
                    console.log('Delete action:', row);
                    break;
            }
        }
    }

    navigateToRecord(recordId) {
        let recordObject;
        if (recordId && recordId.substring(0,3) === '00Q') {
           recordObject = 'Lead';
        } else if (recordId && recordId.substring(0,3) === '001') {
            recordObject = 'Account';
        } else {
            console.log('Unknown object');
        }

       this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: recordObject,
                actionName: 'view'
            }
        }).then((url) => {
            window.open(url, '_blank', 'noopener');
        });
    }
    handleJobTitleChange(event) {
        //this.jobType = event.target.value;
        this.filterData();
    }
    

    handleStatusChange(event) {
    this.jobStatus = event.detail.value;
    this.filterData();
    }

    /*filterData() {
        if(this.filteredData) {
            console.log('filtered data ' + JSON.stringify(this.filteredData));
            console.log('filtered data length ' + JSON.stringify(this.filteredData));
        }
        if (this.jobType && this.jobType != 'None') {
            this.filteredData = this.mapMarkersList.filter(item => item.employmentType === this.jobType);
            this.filterMapMarkers = this.mapMarkers.filter(item => item.employmentType === this.jobType);
        } else {
            this.filteredData = [...this.mapMarkersList]; // If no job title selected, show all data
            this.filterMapMarkers = [...this.mapMarkers];
        }
    }*/

    filterData() {
    console.log('--- Filter Start ---');
    console.log('Selected Job Status:', this.jobStatus);
    console.log('Original Records (mapMarkersList):', JSON.stringify(this.mapMarkersList));

    // Default all data first
    this.filteredData = [...this.mapMarkersList];
    this.filterMapMarkers = [...this.mapMarkers];

    // Apply Job Status filter if selected
    if (this.jobStatus && this.jobStatus !== 'None') {
        const jobStatusLower = this.jobStatus.toLowerCase();

        // Log all leadstatus values (correct lowercase key)
        this.mapMarkersList.forEach((item, index) => {
            console.log(`Record ${index + 1} - leadstatus:`, item.leadstatus);
        });

        this.filteredData = this.mapMarkersList.filter(
            item => item.leadstatus && item.leadstatus.toLowerCase() === jobStatusLower
        );
        this.filterMapMarkers = this.mapMarkers.filter(
            item => item.leadstatus && item.leadstatus.toLowerCase() === jobStatusLower
        );
    }

    console.log('Filtered Data:', JSON.stringify(this.filteredData));
    console.log('--- Filter End ---');
}



    


    handleSelect(event) {
    }

}