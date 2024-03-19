import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DESCRIPTION_FIELD from '@salesforce/schema/Opportunity.Description';
import NAME_FIELD from '@salesforce/schema/Opportunity.Name';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';

export default class TextNote extends LightningElement {
    @api recordId;
    @track Description;
    @track Name;

    @wire(getRecord, { recordId: '$recordId', fields: [DESCRIPTION_FIELD, NAME_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.Description = data.fields.Description.value;
            this.Name = data.fields.Name.value;
        } else if (error) {
            console.error('Error:', error);
        }
    }

    handleNameChange(event) {
        this.Name = event.target.value;
    }

    handleDescriptionChange(event) {
        this.Description = event.target.value;
    }

    saveRecord() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[DESCRIPTION_FIELD.fieldApiName] = this.Description;
        fields[NAME_FIELD.fieldApiName] = this.Name;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: '상담이 정상적으로 수정되었습니다.',
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating Opportunity',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
    }
}