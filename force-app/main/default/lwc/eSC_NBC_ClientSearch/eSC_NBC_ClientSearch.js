import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSearchLocation from '@salesforce/apex/ESC_NBC_ClientSearchController.getSearchLocation';
import getRecordAddress from '@salesforce/apex/ESC_NBC_ClientSearchController.getRecordAddress';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import City_FIELD from "@salesforce/schema/ESC_NBC_Prospect__c.ESC_NBC_Address__c";
import Country_FIELD from "@salesforce/schema/ESC_NBC_Prospect__c.ESC_NBC_Address__c";
import Zip_FIELD from "@salesforce/schema/ESC_NBC_Prospect__c.ESC_NBC_Address__c";
import State_FIELD from "@salesforce/schema/ESC_NBC_Prospect__c.ESC_NBC_Address__c";
import Street_FIELD from "@salesforce/schema/ESC_NBC_Prospect__c.ESC_NBC_Address__c";
import ESCResource from '@salesforce/resourceUrl/ESCResource';
import { loadStyle } from 'lightning/platformResourceLoader';
loadStyle(this, ESCResource + '/main.css');

const fields = [City_FIELD, Country_FIELD, Zip_FIELD, State_FIELD, Street_FIELD];
export default class ESC_NBC_ClientSearch extends NavigationMixin(LightningElement) {

    show = true;
    showListView = true;
    @api recordId;
    value;
    recordTypeValue= '';
    @track columns = [
        {
            label: 'Name',
            fieldName: 'value',  // Store record ID here
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'name' }, // Show Title as text
                name: 'navigateToRecord',
                variant: 'base'  // Makes it look like a hyperlink
            }
        },
        { label: 'Type', fieldName: 'type', type: 'text' },
        { label: 'Industry', fieldName: 'industry', type: 'text' },
        // { label: 'Status', fieldName: '', type: 'leadstatus' },
        // { label: 'Type', fieldName: 'recordTypeName', type: 'text' },
        // {
        //     type: 'action',
        //     typeAttributes: { rowActions: this.getRowActions }
        // }
    ];
    prospectRecords;
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

    get filteredDataLength(){
        return this.mapMarkersList.length == 0 ? true : false;
    }
    connectedCallback(){
        console.log('RecordId: ' + this.recordId);
        if(this.recordId) {
            this.getRecordLocation();
        }

    }

    getRecordLocation(){
        getRecordAddress({recordId : this.recordId})
        .then(result => {
            console.log('result ' + JSON.stringify(result));
            this.street = result.ESC_NBC_Address__Street__s;
            this.city = result.ESC_NBC_Address__City__s;
            this.province = result.ESC_NBC_Address__StateCode__s;
            this.country = result.ESC_NBC_Address__CountryCode__s;
            this.postalcode = result.ESC_NBC_Address__PostalCode__s;
            this.show = true;
            this.fetchList();
        })
        .catch(error => {
            console.error(error);
        })
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
                        console.log(result);
                        this.mapMarkers = this.mapMarkers.concat(JSON.parse(result));
                        // this.mapMarkers = this.mapMarkers.map((marker) => {
                        //     return {
                        //         ...marker,
                        //         description: `<span class="custom-marker-description" data-id="${marker.value}">Click here to view</span>`
                        //     };
                        // });
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
    handleListClick(event) {
        if (event.target.dataset.id) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.target.dataset.id,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            }).then(generatedUrl => {
                window.open(generatedUrl);
            });
        }
    }


    navigateToRecord(recordId) {
        console.log('recordid ' + recordId);
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        }).then((url) => {
            window.open(url, '_blank', 'noopener');
        });
    }

}