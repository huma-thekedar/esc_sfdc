import { LightningElement, api, wire, track } from 'lwc';
import getContactDetails from '@salesforce/apex/ContactController.getContactDetails';
import updateContactDetails2 from '@salesforce/apex/ContactController.updateContactDetails2';
import getPicklistValues from '@salesforce/apex/ContactController.getPicklistValues';
import { refreshApex } from '@salesforce/apex';
// import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { NavigationMixin } from 'lightning/navigation';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NBC_ContactViewButton extends LightningElement {
    selectedCheckbox = [];
    @api recordId;
    @track contact;
    wiredContactResult;
    isLoading = true;
    hasError = false;
    subscription = null;
    channelName = '/data/ContactChangeEvent';
    contactPhone = '';
    contactEmail = '';
    prevContactPhone = '';
    prevContactEmail = '';
    contactName = '';
    position = '';
    specialitiesForUI = '';
    speciality = '';

    isEditing = false;
    error = '';

    selectedmessage = '';
    servicelinedropdowncss = 'slds-dropdown_left slds-dropdown slds-dropdown_length-5 slds-dropdown_fluid selectbox h-label-value-info';
    

    @wire(getContactDetails, { contactId: '$recordId' })
    wiredContact(result) {
        this.wiredContactResult = result;
        const { data, error } = result;
        if (data) {
            this.contact = data;
            this.contactPhone = this.contact.Phone;
            this.contactEmail = this.contact.Email;
            this.prevContactPhone = this.contact.Phone;
            this.prevContactEmail = this.contact.Email;
            this.contactName = this.contact.Name;
            this.position = this.contact.Position__c || ""; // Ensure it's a string
            this.speciality = this.contact.Speciality__c;
            if(this.speciality) {
                this.selectedSpecialitis = this.speciality.split(';');
                this.specialitiesForUI = this.speciality.replace(/;/g, ", ");
                if(this.picklistMap){
                    if(this.picklistMap.Speciality__c) {
                        const picklistvalues = this.picklistMap.Speciality__c.map(eachvalue => ({...eachvalue}));
                        picklistvalues.forEach((element, index) => {
                            if(this.selectedSpecialitis.includes(element.value)){
                                picklistvalues[index].selected = true;
                            }else{
                                picklistvalues[index].selected = false;
                            }
                        });
                        this.picklistMap.Speciality__c = picklistvalues;
                        this.specialityPlaceholder = this.selectedSpecialitis.length + '  Selected';
                        console.log('this.selectedSpecialitis>>>' + this.selectedSpecialitis);
                    }
                }
            }
            this.isLoading = false;
            this.hasError = false;
        } else if (error) {
            console.error('Error fetching contact details:', error);
            this.isLoading = false;
            this.hasError = true;
        }
    }

    showservicelinedropdown = false;

    handleShowdropdown(event) {
        if(event.currentTarget.dataset.id == 'serviceline'){
            let sdd = this.showservicelinedropdown;
            if(sdd){
                this.showservicelinedropdown = false;
            }else{
                this.showservicelinedropdown = true;
            }
        }
    }

    handleleave(event) {
        if(event.currentTarget.dataset.id == 'serviceline'){
            let sddcheck= this.showservicelinedropdown;
            if(sddcheck){
                this.showservicelinedropdown = false;
            }
        }
    }
    selectedSpecialitis=[];
    specialityPlaceholder = '0 Selected';
    handleChange(event) {
        if(!this.selectedSpecialitis.includes(event.target.value)) {
            this.selectedSpecialitis.push(event.target.value);
        }
        else{
            this.selectedSpecialitis = this.selectedSpecialitis.filter( item => item!= event.target.value);
        }
        // this.specialitiesForUI = this.speciality.replace(/;/g, ", ");
        if(this.speciality) {
            this.specialitiesForUI = this.speciality.replace(/;/g, ", ");
        }
        else {
            this.specialitiesForUI = '';
        }
        const picklistvalues = this.picklistMap.Speciality__c.map(eachvalue => ({...eachvalue}));
        picklistvalues.forEach((element, index) => {
            if(this.selectedSpecialitis.includes(element.value)){
                picklistvalues[index].selected = true;
            }else{
                picklistvalues[index].selected = false;
            }
        });
        this.picklistMap.Speciality__c = picklistvalues;
        this.specialityPlaceholder = this.selectedSpecialitis.length + '  Selected';
        console.log('this.selectedSpecialitis>>>' + this.selectedSpecialitis);
        this.servicelinedropdowncss = 'slds-dropdown_left slds-dropdown slds-dropdown_length-5 slds-dropdown_fluid selectbox h-label-value-info';
    }

    connectedCallback() {
        this.fetchContactPicklistDetails();
        console.log('picklistmap>> ' + JSON.stringify('hi'));
    }

    picklistMap = {
        Position__c: [],
        Speciality__c: []
    };
    fetchContactPicklistDetails() {
        getPicklistValues()
        .then(result => {
            if (result) {
                console.log('Position Picklist:', JSON.stringify(result.Position__c));
                console.log('Speciality Picklist:', JSON.stringify(result.Speciality__c));
                this.picklistMap.Position__c = result.Position__c.map(item => ({
                    label: item,     // Use the string itself as the label
                    value: item      // Use the string itself as the value
                }));

                this.picklistMap.Speciality__c = result.Speciality__c.map(item => ({
                    label: item,     // Use the string itself as the label
                    value: item      // Use the string itself as the value
                }));
                console.log('Position Picklist:', JSON.stringify(this.picklistMap.Position__c));
                console.log('Speciality Picklist:', JSON.stringify(this.picklistMap.Speciality__c));
            }
            if(this.speciality) {
                this.selectedSpecialitis = this.speciality.split(';');
                this.specialitiesForUI = this.speciality.replace(/;/g, ", ");
                if(this.picklistMap){
                    if(this.picklistMap.Speciality__c) {
                        const picklistvalues = this.picklistMap.Speciality__c.map(eachvalue => ({...eachvalue}));
                        picklistvalues.forEach((element, index) => {
                            if(this.selectedSpecialitis.includes(element.value)){
                                picklistvalues[index].selected = true;
                            }else{
                                picklistvalues[index].selected = false;
                            }
                        });
                        this.picklistMap.Speciality__c = picklistvalues;
                        this.specialityPlaceholder = this.selectedSpecialitis.length + '  Selected';
                        console.log('this.selectedSpecialitis>>>' + this.selectedSpecialitis);
                    }
                }
            }
        })
        .catch(error => {
            console.error('Error fetching contact details: ', error);
        });
    }
    // callOnce=true;
    // renderedCallback(){
    //     if(this.speciality && this.callOnce) {
    //             this.selectedSpecialitis = this.speciality.split(';');
    //             if(this.picklistMap){
    //                 if(this.picklistMap.Speciality__c) {
    //                     const picklistvalues = this.picklistMap.Speciality__c.map(eachvalue => ({...eachvalue}));
    //                     picklistvalues.forEach((element, index) => {
    //                         if(this.selectedSpecialitis.includes(element.value)){
    //                             picklistvalues[index].selected = true;
    //                         }else{
    //                             picklistvalues[index].selected = false;
    //                         }
    //                     });
    //                     this.picklistMap.Speciality__c = picklistvalues;
    //                     this.specialityPlaceholder = this.selectedSpecialitis.length + '  Selected';
    //                     console.log('this.selectedSpecialitis>>>' + this.selectedSpecialitis);
    //                 }
    //             }
    //         }
    //         this.callOnce = false;
    // }

    // disconnectedCallback() {
    //     if (this.subscription) {
    //         unsubscribe(this.subscription, () => console.log('Unsubscribed from change events.'));
    //         this.subscription = null;
    //     }
    // }

    // registerSubscribe() {
    //     const changeEventCallback = (changeEvent) => {
    //         this.processChangeEvent(changeEvent);
    //     };

    //     subscribe(this.channelName, -1, changeEventCallback).then((subscription) => {
    //         this.subscription = subscription;
    //     });
    // }

    // processChangeEvent(changeEvent) {
    //     try {
    //         const contact = this.contact;
    //         const changedFields = changeEvent?.data.payload.ChangeEventHeader?.changedFields || [];
    //         const recordId = changeEvent?.data.payload.ChangeEventHeader?.recordIds[0];

    //         // If the recordId matching and there are changes to fields, refresh data
    //         if (recordId === this.recordId && changedFields.includes('Phone') || changedFields.includes('Email') || changedFields.includes('Position__c') || changedFields.includes('Speciality__c')) {
    //             refreshApex(this.wiredContactResult)
    //                 .then(() => console.log('successfully'))
    //                 .catch((error) => console.error('Error:', error));
    //         }
    //     } catch (err) {
    //         console.error('Error:', err);
    //     }
    // }

    // registerErrorListener() {
    //     onError((error) => {
    //         console.error('Error: ', JSON.stringify(error));
    //     });
    // }

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
    // @track contactPhone;
    // @track contactEmail;
    // @track isOwner = false;
    // @track isEditable = false; 
    // @track isVisible = false;
    // @track isEditing = false;  // New state to manage view and edit mode
    // isLoading = true;
    // error;
    // @api recordId;
    // recordUrls = null;

    // connectedCallback() {
    //     this.checkOwnership();
    //     setTimeout(() => {
    //         this.isLoading = false;
    //     }, 1000);
    // }

    // fetchContactDetails() {
    //     getContactDetails({ contactId: this.recordId })
    //         .then(contact => {
    //             this.contactPhone = contact.Phone;
    //             this.contactEmail = contact.Email;
    //             this.isVisible = this.isOwner;
    //             this.isEditable = this.isOwner;
    //         })
    //         .catch(error => {
    //             console.log('Error fetching contact:', error);
    //         });
    // }

    // checkOwnership() {
    //     checkIfOwner({ contactId: this.recordId })
    //         .then(ownerCheck => {
    //             this.isOwner = ownerCheck;
    //             this.isEditable = ownerCheck;
    //             this.fetchContactDetails();
    //         })
    //         .catch(error => {
    //             console.log('Error checking ownership:', error);
    //         });
    // }

    // Enable edit mode
    enableEditMode() {
        this.isEditing = true;
        console.log('enable edit ' + this.isEditing);
    }

    // Disable edit mode
    disableEditMode() {
        this.isEditing = false;
        // this.fetchContactDetails(); // Re-fetch contact details to discard any unsaved changes
    }

    handleInputChange(event) {
        let name = event.target.name;
        let value = event.target.value;
        console.log('name' + name + value);
        if(name == 'Phone') {
            this.contactPhone = value;
        } else if(name == 'Email') {
            this.contactEmail = value;
        } else if(name == 'position') {
            this.position = value;
            console.log('called position ' + value);
        }
    }

    getSelectedSpecialities() {
        return this.selectedSpecialitis.join(';');
    }
    specialities;
    saveContact() {
        this.specialities = this.getSelectedSpecialities();
        // if(this.contactPhone !==  this.prevContactPhone || this.prevContactEmail !== this.contactEmail) {  
            updateContactDetails2({ contactId: this.recordId, phone: this.contactPhone, email: this.contactEmail, 
                position: this.position, speciality: this.specialities
            })
                .then((result) => {
                    console.log('result'+ JSON.stringify(result));
                    this.error = null;
                    if(result == null) {
                        this.showToast('Success', 'Contact updated successfully.', 'success');
                        this.isEditing = false;
                        refreshApex(this.wiredContactResult)
                            .then(() => console.log('updated details successfully'))
                            .catch((error) => console.error('Error:', error));
                    }
                    else{
                        this.isEditing = true;
                        if(result['Other Error']) {
                            this.error = 'Invalid Email Address';
                            this.recordUrls = null;
                        }
                        // else{
                        //     this.recordUrls = [];
                        //     for (let key in result) {
                        //         if (result.hasOwnProperty(key)) {
                        //             let recordUrl = window.location.origin + '/' + result[key];
                        //             this.recordUrls.push({ label: key, url: recordUrl });
                        //         }
                        //     }
                        //     this.error = 'Duplicate Record found: ';
                        // }
                    }
                })
                .catch(error => {
                    console.log('error'+JSON.stringify(error));
                });
            this.isEditing = false;
        // }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}