import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DESCRIPTION_FIELD from '@salesforce/schema/Case.Description';
import NAME_FIELD from '@salesforce/schema/Case.Subject';
import ID_FIELD from '@salesforce/schema/Case.Id';

export default class TextNote extends LightningElement {
    @api recordId;
    @track Description;
    @track Subject;

    @wire(getRecord, { recordId: '$recordId', fields: [DESCRIPTION_FIELD, NAME_FIELD] })
    wiredCase({ error, data }) {
        if (data) {
            this.Description = data.fields.Description.value;
            this.Subject = data.fields.Subject.value;
        } else if (error) {
            console.error('Error:', error);
        }
    }

    handleSubjectChange(event) {
        this.Subject = event.target.value;
    }

    handleDescriptionChange(event) {
        this.Description = event.target.value;
    }

    saveRecord() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[DESCRIPTION_FIELD.fieldApiName] = this.Description;
        fields[NAME_FIELD.fieldApiName] = this.Subject;

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
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
    }
}