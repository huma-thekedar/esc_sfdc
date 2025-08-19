import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSearchLocation from '@salesforce/apex/addressSearchController.getSearchLocation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import City_FIELD from "@salesforce/schema/Account.BillingCity";
import Country_FIELD from "@salesforce/schema/Account.BillingCountry";
import Zip_FIELD from "@salesforce/schema/Account.BillingPostalCode";
import State_FIELD from "@salesforce/schema/Account.BillingState";
import Street_FIELD from "@salesforce/schema/Account.BillingStreet";
//jobOpening
import City_FIELD_JobOpening from "@salesforce/schema/Job_Opening__c.Address__c";
import Country_FIELD_JobOpening from "@salesforce/schema/Job_Opening__c.Address__c";
import Zip_FIELD_JobOpening from "@salesforce/schema/Job_Opening__c.Address__c";
import State_FIELD_JobOpening from "@salesforce/schema/Job_Opening__c.Address__c";
import Street_FIELD_JobOpening from "@salesforce/schema/Job_Opening__c.Address__c";
import ESCResource from '@salesforce/resourceUrl/ESCResource';
import { loadStyle } from 'lightning/platformResourceLoader';
import getPicklistValues from '@salesforce/apex/NBC_Picklist_Controller.getPicklistValues';
import getRecordTypeOption from '@salesforce/apex/NBC_Picklist_Controller.getRecordTypeNames';
loadStyle(this, ESCResource + '/main.css');

const fields_Account = [City_FIELD, Country_FIELD, Zip_FIELD, State_FIELD, Street_FIELD];
const fields_JobOpening = [
    "Job_Opening__c.Address__City__s","Job_Opening__c.Address__CountryCode__s",
    "Job_Opening__c.Address__PostalCode__s", "Job_Opening__c.Address__StateCode__s",
    "Job_Opening__c.Address__Street__s"
];

export default class AddressSearch extends NavigationMixin(LightningElement) {
    
    show = true;
    @api showForJobOpening = false;
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
                label: { fieldName: 'title' }, // Show Title as text
                name: 'navigateToRecord',
                variant: 'base'  // Makes it look like a hyperlink
            }
        },
        { label: 'Job Title', fieldName: 'jobTitle', type: 'text' },
        { label: 'Source', fieldName: 'leadSource', type: 'text' },
        // { label: 'Status', fieldName: '', type: 'leadstatus' },
        { label: 'Type', fieldName: 'recordTypeName', type: 'text' },
        // {
        //     type: 'action',
        //     typeAttributes: { rowActions: this.getRowActions }
        // }
         { label: 'City', fieldName: 'city', type: 'text' },
         { label: 'Postal Code', fieldName: 'postalCode', type: 'text' }
    ];
    account;
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
    jobTitleValue;
    filteredData = [];
    filterMapMarkers = [];
    connectedCallback() {
        this.getJobTitleOption();
        // this.getRecordTypeOptions();
        console.log('fields' + JSON.stringify(fields_JobOpening));
    }

    get filteredDataLength(){
        return this.mapMarkersList.length == 0 ? true : false;
    }

    getJobTitleOption() {
        getPicklistValues({ objectName: 'ESC_NBC_Prospect__c', fieldName: 'ESC_NBC_Job_Title__c' })
            .then((result) => {
                this.jobTitleOption = result;
            }).catch((err) => {
                console.error(err);
            });
    }
    // getRecordTypeOptions() {
    //     getRecordTypeOption({ objectName: 'ESC_NBC_Prospect__c'})
    //         .then((result) => {
    //             this.recordTypeOptions = result.map(item => ({
    //                 label: item,
    //                 value: item
    //             }));
    //             console.log('recordtypes' + JSON.stringify(this.recordTypeOptions));
    //         }).catch((err) => {
    //             console.error(err);
    //         });
    // }
    jobOpening;
    @track fieldsFinal =
        window.location.href.includes('Account') ? fields_Account : fields_JobOpening;

    @wire(getRecord, {
        recordId: "$recordId",
        fields: "$fieldsFinal"
    })
    wiredRecord({ error, data }) {
        this.show = false;

        console.log('fieldsFinal', JSON.stringify(this.fieldsFinal));
        console.log('showForJobOpening', JSON.stringify(this.showForJobOpening));

        if (data) {
            if (this.recordId  && !this.showForJobOpening) {
                this.account = data;
                this.street = getFieldValue(this.account, Street_FIELD) ? getFieldValue(this.account, Street_FIELD) : '';
                this.city = getFieldValue(this.account, City_FIELD) ? getFieldValue(this.account, City_FIELD) : '';
                this.province = getFieldValue(this.account, State_FIELD) ? getFieldValue(this.account, State_FIELD) : '';
                this.country = getFieldValue(this.account, Country_FIELD) ? getFieldValue(this.account, Country_FIELD) : '';
                this.postalcode = getFieldValue(this.account, Zip_FIELD) ? getFieldValue(this.account, Zip_FIELD) : '';
                this.fetchList();
            } else if (this.recordId  && this.showForJobOpening) {
                console.log('jobOpening', JSON.stringify(data));
                this.jobOpening = data;
                this.street = getFieldValue(this.jobOpening, "Job_Opening__c.Address__Street__s") ? getFieldValue(this.jobOpening, "Job_Opening__c.Address__Street__s") : '';
                this.city = getFieldValue(this.jobOpening, "Job_Opening__c.Address__City__s") ? getFieldValue(this.jobOpening, "Job_Opening__c.Address__City__s") : '';
                this.province = getFieldValue(this.jobOpening, "Job_Opening__c.Address__StateCode__s") ? getFieldValue(this.jobOpening, "Job_Opening__c.Address__StateCode__s") : '';
                this.country = getFieldValue(this.jobOpening, "Job_Opening__c.Address__CountryCode__s") ? getFieldValue(this.jobOpening, "Job_Opening__c.Address__CountryCode__s") : '';
                this.postalcode = getFieldValue(this.jobOpening, "Job_Opening__c.Address__PostalCode__s") ? getFieldValue(this.jobOpening, "Job_Opening__c.Address__PostalCode__s") : '';
                this.fetchList();
            }
        }else if(error) {
            console.error('error', JSON.stringify(error));
        }

        this.show = true;
    }

    get statusOptions() {
        return [
            { label: 'All', value: 'null' },
            { label: 'Active', value: 'true' },
            { label: 'Inactive', value: 'false' },
        ];
    }

    get recordTypeOptions() {
        return [
            { label: 'None', value: 'None' },
            { label: 'Active Prospect', value: 'Active Prospect' },
            { label: 'Incomplete Lead', value: 'Incomplete Lead' }, 
            { label: 'Prospect (Lead database)', value: 'Prospect (Lead database)' },
        ];
    }

    addressInputChange(event) {
        this.street = event.target.street;
        this.city = event.target.city;
        this.country = event.target.country;
        this.province = event.target.province;
        this.postalcode = event.target.postalCode;
        this.datafound = false;
        this.jobTitleValue = 'None';
        this.recordTypeValue = 'None';
        this.fetchList();

    }

    handleRecordTypeChange(event) {
        this.recordTypeValue = event.target.value;
        this.filterData();
    }

    fetchList() {
        console.log('fetchList called');

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
                        console.log('result>> ' + JSON.stringify(result));
                        this.mapMarkers = JSON.parse(result);
                        this.filterMapMarkers = this.mapMarkers;
                        console.log('marker ' + this.mapMarkers.length);
                        this.mapMarkersList = [];
                        if (this.mapMarkers.length > 2) {
                            this.mapMarkersList = this.mapMarkers.slice(2, this.mapMarkers.length);
                            this.datafound = true;
                            this.filteredData = this.mapMarkersList;
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
        this.jobTitleValue = 'None';
        this.recordTypeValue = 'None';
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
       this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, '_blank', 'noopener');
        });
    }
    handleJobTitleChange(event) {
        this.jobTitleValue = event.target.value;
        this.filterData();
    }
    filterData() {
        if(this.filteredData) {
            console.log('filtered data ' + JSON.stringify(this.filteredData));
            console.log('filtered data length ' + JSON.stringify(this.filteredData));
        }
        if (this.jobTitleValue && this.jobTitleValue != 'None') {
            this.filteredData = this.mapMarkersList.filter(item => item.jobTitle === this.jobTitleValue);
            this.filterMapMarkers = this.mapMarkers.filter(item => item.jobTitle === this.jobTitleValue);
        } else {
            this.filteredData = [...this.mapMarkersList]; // If no job title selected, show all data
            this.filterMapMarkers = [...this.mapMarkers];
        }
        if (this.recordTypeValue && this.recordTypeValue != 'None') {
            this.filteredData = this.filteredData.filter(item => item.recordTypeName === this.recordTypeValue);
            this.filterMapMarkers = this.filterMapMarkers.filter(item => item.recordTypeName === this.recordTypeValue);
        }

    }

    handleSelect(event) {
        // // Get the clicked element
        // let clickedElement = event.target;

        // // Check if the clicked element or its parents contain "CNA"
        // while (clickedElement) {
        //     if (clickedElement.innerText && clickedElement.innerText.includes("CNA")) {
        //         console.log("Found CNA in:", clickedElement);
        //         break; // Stop searching once found
        //     }
        //     clickedElement = clickedElement.parentElement; // Move up to the parent
        // }
    }

}