import { LightningElement, api, wire, track } from 'lwc';
import getContactDetails from '@salesforce/apex/ContactController.getContactDetails';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { NavigationMixin } from 'lightning/navigation';

export default class ContactDetailsLCMP extends NavigationMixin(LightningElement){
    @api recordId;
    @track contact;
    wiredContactResult;
    isLoading = true;
    hasError = false;
    subscription = null;
    channelName = '/data/ContactChangeEvent';

    @wire(getContactDetails, { contactId: '$recordId' })
    wiredContact(result) {
        this.wiredContactResult = result;
        const { data, error } = result;
        if (data) {
            this.contact = data;
            this.isLoading = false;
            this.hasError = false;
        } else if (error) {
            console.error('Error fetching contact details:', error);
            this.isLoading = false;
            this.hasError = true;
        }
    }

    connectedCallback() {
        this.registerErrorListener();
        this.registerSubscribe();
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription, () => console.log('Unsubscribed from change events.'));
            this.subscription = null;
        }
    }

    registerSubscribe() {
        const changeEventCallback = (changeEvent) => {
            this.processChangeEvent(changeEvent);
        };

        subscribe(this.channelName, -1, changeEventCallback).then((subscription) => {
            this.subscription = subscription;
        });
    }

    processChangeEvent(changeEvent) {
        try {
            const contact = this.contact;
            const changedFields = changeEvent?.data.payload.ChangeEventHeader?.changedFields || [];
            const recordId = changeEvent?.data.payload.ChangeEventHeader?.recordIds[0];

            // If the recordId matching and there are changes to fields, refresh data
            if (recordId === this.recordId && changedFields.includes('Phone') || changedFields.includes('Email') || changedFields.includes('Position__c') || changedFields.includes('Speciality__c')) {
                refreshApex(this.wiredContactResult)
                    .then(() => console.log('successfully'))
                    .catch((error) => console.error('Error:', error));
            }
        } catch (err) {
            console.error('Error:', err);
        }
    }

    registerErrorListener() {
        onError((error) => {
            console.error('Error: ', JSON.stringify(error));
        });
    }

    handleEditClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Contact',
                actionName: 'edit'
            }
        });
    }
}