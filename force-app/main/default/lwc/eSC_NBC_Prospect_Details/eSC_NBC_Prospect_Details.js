import { LightningElement, api, wire, track } from 'lwc';
import getContactDetails from '@salesforce/apex/ESC_NBC_Prospect_Controller.getContactDetails';
import updateContactDetails2 from '@salesforce/apex/ESC_NBC_Prospect_Controller.updateContactDetails2';
import getPicklistValues from '@salesforce/apex/ESC_NBC_Prospect_Controller.getPicklistValues';
import getUserProfileName from '@salesforce/apex/ESC_NBC_UserController.getUserProfileName';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class ESC_NBC_Prospect_Details extends LightningElement {
    selectedCheckbox = [];
    showEdit  = true;
    @api recordId;
    contact = {};
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
    recordTypeName;
    profileName;

    @wire(getUserProfileName)
    wiredProfile({ error, data }) {
        if (data) {
            this.profileName = data;
            if(this.profileName == 'ESC_NBC_Recruiter' || this.profileName == 'ESC_NBC_SalesRep') {
                this.showEdit = false;
            }
            console.log('Profile Name:', this.profileName);
        } else if (error) {
            console.error('Error retrieving profile name:', error);
        }
    }


    @wire(getContactDetails, { prospectId: '$recordId' })
    wiredContact(result) {
        this.wiredContactResult = result;
        const { data, error } = result;
        if (data) {
            this.contact = data;
            this.contactPhone = this.contact.ESC_NBC_Phone__c;
            this.contactEmail = this.contact.ESC_NBC_Email__c;
            this.prevContactPhone = this.contact.ESC_NBC_Phone__c;
            this.prevContactEmail = this.contact.ESC_NBC_Email__c;
            this.contactName = this.contact.Name;
            this.position = this.contact.ESC_NBC_Job_Title__c || ""; // Ensure it's a string
            this.speciality = this.contact.ESC_NBC_Speciality__c;
            this.recordTypeName = this.contact.RecordType? this.contact.RecordType.Name : null;
            console.log('contact' + JSON.stringify(this.contact));
            if(this.speciality) {
                this.selectedSpecialitis = this.speciality.split(';');
                this.specialitiesForUI = this.speciality.replace(/;/g, ", ");
                if(this.picklistMap){
                    if(this.picklistMap.ESC_NBC_Speciality__c) {
                        const picklistvalues = this.picklistMap.ESC_NBC_Speciality__c.map(eachvalue => ({...eachvalue}));
                        picklistvalues.forEach((element, index) => {
                            if(this.selectedSpecialitis.includes(element.value)){
                                picklistvalues[index].selected = true;
                            }else{
                                picklistvalues[index].selected = false;
                            }
                        });
                        this.picklistMap.ESC_NBC_Speciality__c = picklistvalues;
                        this.specialityPlaceholder = this.selectedSpecialitis.length + '  Selected';
                        console.log('this.selectedSpecialitis>>>' + this.selectedSpecialitis);
                    }
                }
            }
            this.isLoading = false;
            this.hasError = false;
        } else if (error) {
            console.error('Error fetching contact details:', JSON.stringify(error));
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
        if(this.speciality) {
            this.specialitiesForUI = this.speciality.replace(/;/g, ", ");
        }
        else {
            this.specialitiesForUI = '';
        }
        const picklistvalues = this.picklistMap.ESC_NBC_Speciality__c.map(eachvalue => ({...eachvalue}));
        picklistvalues.forEach((element, index) => {
            if(this.selectedSpecialitis.includes(element.value)){
                picklistvalues[index].selected = true;
            }else{
                picklistvalues[index].selected = false;
            }
        });
        this.picklistMap.ESC_NBC_Speciality__c = picklistvalues;
        this.specialityPlaceholder = this.selectedSpecialitis.length + '  Selected';
        console.log('this.selectedSpecialitis>>>' + this.selectedSpecialitis);
        this.servicelinedropdowncss = 'slds-dropdown_left slds-dropdown slds-dropdown_length-5 slds-dropdown_fluid selectbox h-label-value-info';
    }

    connectedCallback() {
        this.fetchContactPicklistDetails();
        console.log('picklistmap>> ' + JSON.stringify('hi'));
    }

    picklistMap = {
        ESC_NBC_Job_Title__c: [],
        ESC_NBC_Speciality__c: []
    };
    fetchContactPicklistDetails() {
        getPicklistValues()
        .then(result => {
            if (result) {
                console.log('Position Picklist:', JSON.stringify(result.ESC_NBC_Job_Title__c));
                console.log('Speciality Picklist:', JSON.stringify(result.ESC_NBC_Speciality__c));
                this.picklistMap.ESC_NBC_Job_Title__c = result.ESC_NBC_Job_Title__c.map(item => ({
                    label: item,     // Use the string itself as the label
                    value: item      // Use the string itself as the value
                }));

                this.picklistMap.ESC_NBC_Speciality__c = result.ESC_NBC_Speciality__c.map(item => ({
                    label: item,     // Use the string itself as the label
                    value: item      // Use the string itself as the value
                }));
                console.log('Position Picklist:', JSON.stringify(this.picklistMap.ESC_NBC_Job_Title__c));
                console.log('Speciality Picklist:', JSON.stringify(this.picklistMap.ESC_NBC_Speciality__c));
            }
            if(this.speciality) {
                this.selectedSpecialitis = this.speciality.split(';');
                this.specialitiesForUI = this.speciality.replace(/;/g, ", ");
                if(this.picklistMap){
                    if(this.picklistMap.ESC_NBC_Speciality__c) {
                        const picklistvalues = this.picklistMap.ESC_NBC_Speciality__c.map(eachvalue => ({...eachvalue}));
                        picklistvalues.forEach((element, index) => {
                            if(this.selectedSpecialitis.includes(element.value)){
                                picklistvalues[index].selected = true;
                            }else{
                                picklistvalues[index].selected = false;
                            }
                        });
                        this.picklistMap.ESC_NBC_Speciality__c = picklistvalues;
                        this.specialityPlaceholder = this.selectedSpecialitis.length + '  Selected';
                        console.log('this.selectedSpecialitis>>>' + this.selectedSpecialitis);
                    }
                }
            }
        })
        .catch(error => {
            console.error('Error fetching contact details: ', JSON.stringify(error));
        });
    }

    // Enable edit mode
    enableEditMode() {
        this.isEditing = true;
        console.log('enable edit ' + this.isEditing);
    }

    // Disable edit mode
    disableEditMode() {
        this.isEditing = false;
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
        try{
            this.specialities = this.getSelectedSpecialities();
            let contactData = {};
            contactData['Id'] = this.recordId;
            contactData['ESC_NBC_Phone__c'] = this.contactPhone;
            contactData['ESC_NBC_Email__c'] = this.contactEmail;
            contactData['ESC_NBC_Job_Title__c'] = this.position;
            contactData['ESC_NBC_Speciality__c'] = this.specialities;
            
            updateContactDetails2({
                prospectData : contactData
            })
                .then((result) => {
                    console.log('Update success'+ result);
                    try{
                        this.error = null;
                        this.showToast('Success', 'Contact updated successfully.', 'success');
                        this.isEditing = false;
                        refreshApex(this.wiredContactResult)
                            .then(() => console.log('updated details successfully'))
                            .catch((error) => console.error('Error:', error));
                    } catch(error) {
                        console.log('error2'+JSON.stringify(error));
                    }
                })
                .catch(error => {
                    console.log('error'+JSON.stringify(error));
                });
            this.isEditing = false; 
        } catch(error) {
             console.log('error1'+JSON.stringify(error));
        }
        
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}