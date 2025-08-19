import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSearchLocation from '@salesforce/apex/ESC_NBC_ClientSearchController.getSearchLocation';
import getLatestJobOpeningsForAccounts from '@salesforce/apex/ESC_NBC_ClientSearchController.getLatestJobOpeningsForAccounts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ESCResource from '@salesforce/resourceUrl/ESCResource';
import { loadStyle } from 'lightning/platformResourceLoader';
import getRecordTypeOption from '@salesforce/apex/NBC_Picklist_Controller.getRecordTypeNames';
loadStyle(this, ESCResource + '/main.css');
//import ESC_NBC_WrappedHeaderTable from '@salesforce/resourceUrl/ESC_NBC_WrappedHeaderTable';
export default class ESC_NBC_Client_Search extends NavigationMixin(LightningElement) {
    
    show = true;
    @api showForJobOpening = false;
    @api showListView = false;
    @api recordId;
    value;
    recordTypeValue= '';
    status = '';
    @track columns = [
       {
            label: 'Name',
            fieldName: 'value',  // Store record ID here
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'name' }, // Show Title as text
                name: 'navigateToRecord',
                variant: 'base',  // Makes it look like a hyperlink
            },
            wrapText: true
        },
        { label: 'Active', fieldName: 'isActive', type: 'text' ,wrapText: true, hideDefaultActions: true},
        { label: 'Billing City', fieldName: 'billingCity', type: 'text',wrapText: true , hideDefaultActions: true},
        { label: 'Billing State', fieldName: 'billingState', type: 'text',wrapText: true, hideDefaultActions: true},
        { label: 'Billing ZIP/ Postal Code', fieldName: 'billingPostalCode', type: 'text',wrapText: true, hideDefaultActions: true},
        { label: 'Sales Owner Name', fieldName: 'salesOwner', type: 'text',wrapText: true , hideDefaultActions: true},
        { label: 'Job Opening', fieldName: 'jobOpening', type: 'text',wrapText: true, hideDefaultActions: true},
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
    filteredData = [];
    filterMapMarkers = [];
    get statusOptions() {
        return [
            { label: 'All', value: 'null' },
            { label: 'Active', value: 'Active' },
            { label: 'Inactive', value: 'Inactive' },
        ];
    }

    connectedCallback() {
        this.getRecordTypeOptions();
    }

    stylesLoaded = false;

    

    get filteredDataLength(){
        return this.mapMarkersList.length == 0 ? true : false;
    }

    getRecordTypeOptions() {
        getRecordTypeOption({ objectName: 'Account'})
        .then((result) => {
            this.recordTypeOptions = result.map(item => ({
                label: item,
                value: item
            }));
            console.log('recordtypes' + JSON.stringify(this.recordTypeOptions));
        }).catch((err) => {
            console.error(err);
        });
    }
    jobOpening;

    addressInputChange(event) {
        this.street = event.target.street;
        this.city = event.target.city;
        this.country = event.target.country;
        this.province = event.target.province;
        this.postalcode = event.target.postalCode;
        this.status= '';
        this.datafound = false;
        this.fetchList();
    }

    handleStatusChange(event) {
        this.status =  event.target.value;
        this.filterData();
    }

    /*fetchList() {
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
    }*/


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
                } else {
                    console.log('result>> ' + JSON.stringify(result));
                    this.mapMarkers = JSON.parse(result);
                    this.filterMapMarkers = this.mapMarkers;
                    console.log('marker ' + this.mapMarkers.length);
                    this.mapMarkersList = [];

                    if (this.mapMarkers.length > 2) {
                        this.mapMarkersList = this.mapMarkers.slice(2, this.mapMarkers.length);

                        const accountIds = this.mapMarkersList.map(item => item.value);
                        // Fetch latest Job Opening name for each Account
                        getLatestJobOpeningsForAccounts({ accountIds: accountIds })
                            .then((jobMap) => {
                                console.log('Job Map:', jobMap);
                                this.filteredData = this.mapMarkersList.map(acc => {
                                    return {
                                        ...acc,
                                        jobOpening: jobMap[acc.value] || 'No job'
                                    };
                                });
                                this.datafound = true;
                            })
                            .catch((error) => {
                                console.error('Error fetching job openings:', error);
                                // Fall back to original mapMarkersList without jobOpening
                                this.filteredData = this.mapMarkersList.map(acc => {
                                    return {
                                        ...acc,
                                        jobOpening: 'No job'
                                    };
                                });
                                this.datafound = true;
                            });
                    }
                    console.log('filterMapMarkers ' + this.filterMapMarkers.length);
                }

            })
            .catch(error => {
                console.error(error);
            });
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
            window.open(generatedUrl, '_blank', 'noopener');
        });
        }
    }

    milesUpdated(event) {
        this.searchmiles = 0;
        if (event.target.value)
            this.searchmiles = event.target.value;
        this.status= '';
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
                objectApiName: 'Account',
                actionName: 'view'
            }
        }).then((url) => {
            window.open(url, '_blank', 'noopener');
        });
    }

    filterData() {
        if(this.filteredData) {
            console.log('filtered data ' + JSON.stringify(this.filteredData));
            if (this.status != 'null') {
                this.filteredData = this.mapMarkersList.filter(item => item.isActive == this.status);
                this.filterMapMarkers = this.mapMarkers.filter(item => item.isActive == this.status);
            } else {
                this.filteredData = [...this.mapMarkersList]; // If no job title selected, show all data
                this.filterMapMarkers = [...this.mapMarkers];
            }
        }
    }
}