import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import STATUS_FIELD from '@salesforce/schema/Interview__c.Status__c';
import ID_FIELD from '@salesforce/schema/Interview__c.Id';

export default class ESC_NBC_Update_Interview_Sumitted_To_Client extends LightningElement {
    @api recordId;

    @api invoke() {
        this.handleMarkSubmittedToClient();
    }

    handleMarkSubmittedToClient() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = 'Submission Completed';

        const recordInput = { fields };
        console.log('values are -> ',fields)
        updateRecord(recordInput)
            .then(() => {
                console.log('inside success')
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Interview marked as Submission Completed',
                        variant: 'success'
                    })
                );
                
                this.dispatchEvent(new CustomEvent('close'));
            })
            .catch(error => {
    console.error('Error updating record:', JSON.stringify(error));
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Error',
            message: error.body ? error.body.message : error.message,
            variant: 'error'
        })
    );
});

            /*.catch(error => {
                console.log('inside error')
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });*/
    }
}