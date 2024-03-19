import { LightningElement, wire, track } from 'lwc';
import getAccountLocations from '@salesforce/apex/AccountController.getAccountLocations';

export default class AccountLocationsMap extends LightningElement {
    @track mapMarkers = [];

    @wire(getAccountLocations)
    wiredAccounts({ error, data }) {
        if (data) {
            this.mapMarkers = data.map(account => {
                return {
                    location: {
                        // Salesforce Account 오브젝트 필드에서 위치 정보를 가져옴
                        City: account.BillingCity,
                        Country: account.BillingCountry
                    },
                    title: account.Name,
                    description: `지점 이름: ${account.Name}`, 
                    icon: 'standard:account'
                };
            });
        } else if (error) {
            this.error = error;
            this.mapMarkers = undefined;
        }
    }
}