import { LightningElement, track,api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
//import getRecordTypeName from '@salesforce/apex/ESC_NBC_RecordTypeHelper.getRecordTypeName';

const FIELDS = ['RecordTypeId', 'RecordType.Name'];
export default class LaunchInterviewFlow extends NavigationMixin(LightningElement) {
    @api recordId;          
    @api objectApiName;     
    @api recordTypeId; 
    @api sObjectName;
    @api recordTypeName; 

    flowApiName = 'New_Interview';

    /*@wire(getRecordTypeName, { recordId: '$recordId' })
    wiredRecordTypeName({ error, data }) {
        if (data) {
            this.recordTypeName = data;
            console.log('Record Type Name:', data);
        } else if (error) {
            console.error('Error fetching record type name:', error);
        }
    }*/


        get isRecordTypeInterview() {
            return this.recordTypeName == 'Interview';
        }
        get isRecordTypeSubmission() {
            return this.recordTypeName == 'Submission';
        }

         connectedCallback() {
            // if (this.recordTypeName) {
            //     if (this.recordTypeName === 'Submission') {
            //         return 'New Submission';
            //     } else if (this.recordTypeName === 'Interview') {
            //         return 'New Interview';
            //     } else {
            //         return 'New Record';
            //     }
            // }
        }

        /*fetchRecordTypeName() {
            getRecordTypeName({ recordId: this.recordId })
                .then(result => {
                    this.recordTypeName = result;
                    console.log('Record Type Name:', result);
                })
                .catch(error => {
                    console.error('Error fetching record type name:', error);
                });
        }*/



    get flowInputVariables() {
        const inputs = [];

        if (this.recordId) {
            inputs.push({
                name: 'inputRecordId',
                type: 'String',
                value: this.recordId
            });
        }

        if (this.objectApiName) {
            inputs.push({
                name: 'inputObjectName',
                type: 'String',
                value: this.objectApiName
            });
        }

        if (this.recordTypeId) {
            inputs.push({
                name: 'inputRecordTypeId',
                type: 'String',
                value: this.recordTypeId
            });
        }

        return inputs;
    }
    interviewId;
    recordPageUrl;
    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            const outputVariables = event.detail.outputVariables;
            if(outputVariables) {
                let outputVar = outputVariables[0];
                console.log('Flow completed' + JSON.stringify(outputVar));
                if (outputVar.name == "interviewId") {
                    this.interviewId = outputVar.value;
                    console.log('interviewId>>' + this.interviewId);
                }
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: "Interview record created successfully.",
                    variant: 'success'
                })
            );
            console.log('LWC>>' + this.recordId + '-' + this.sObjectName)
            if (this.recordId) {
                // Navigate to record detail page
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: this.sObjectName, // Replace with actual object
                        actionName: 'view'
                    }
                });
            //    window.setTimeout(function() {
            //         window.location.href = '/' + this.recordId;
            //     }, 20); // 5000 ms = 5 seconds

            } else {
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.interviewId,
                        objectApiName: 'Interview__c',
                        actionName: 'view'
                    }
                }).then((url) => {
                    window.open(url, '_self', 'noopener');
                });
            }
        }
    }

    get cardTitle() {
        if (this.recordTypeId === '012V1000004Wq63IAC') {
            return 'Create Submission';
        } else if (this.recordTypeId === '012V1000004Wq62IAC') {
            return 'Schedule Interview';
        } else {
            return 'New Record';
        }
    }
}