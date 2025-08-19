import { LightningElement, api, wire } from 'lwc';
import updateToEmployee from '@salesforce/apex/ESC_NBC_ChangeRecordTypeController.updateToEmployee';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class ESC_NBC_markAsEmployeeQuickAction extends LightningElement {
    @api recordId;
    @api 
    invoke(){
        console.log('Quick action invoked!'+ this.recordId);
         updateToEmployee({ recordId: this.recordId })
        .then(() => {
            this.showToast('Success', 'Prospect successfully marked as employee.', 'success');
            setTimeout(() =>{
                window.location.reload()
            },1000);
            this.closeAction();
        })
        .catch(error => {
            console.error('Error details:', JSON.stringify(error));
            this.showToast('Error', error.body?.message || 'Error updating record.', 'error');
            this.closeAction();
        });
    }


    connectedCallback() {
    //console.log('recordId passed to LWC:', this.recordId);

    // if (!this.recordId) {
    //     this.showToast('Error', 'Record Id not received. Did you deploy this as a Quick Action?', 'error');
    //     this.closeAction();
    //     return;
    // }

   
}


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}