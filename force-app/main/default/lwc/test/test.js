import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import STATUS_FIELD from '@salesforce/schema/Interview__c.Status__c';
   import { CloseActionScreenEvent } from 'lightning/actions';
import ID_FIELD from '@salesforce/schema/Interview__c.Id';

export default class ESC_NBC_Update_Interview_Pass extends LightningElement {
    @api recordId;  // passed automatically by the quick action

    @api invoke() {
        this.handleMarkSelected();

    }
    handleMarkSelected() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = 'Selected';

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Interview marked as Selected',
                        variant: 'success'
                    })
                );
                // close quick action
                this.dispatchEvent(new CustomEvent('close'));
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}