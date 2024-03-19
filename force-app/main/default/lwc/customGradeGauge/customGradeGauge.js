import { LightningElement, api, wire } from 'lwc';
import getCustomerDetails from '@salesforce/apex/CustomerGradeService.getCustomerDetails';

export default class CustomerGradeGauge extends LightningElement {
    @api recordId; // 고객(Contact) 레코드 ID
    customerDetails = {}; // 초기값 설정으로 undefined 방지
    gaugeValue = 0; // 초기 게이지 값 설정
    nextLevelAmount = 0; // 다음 등급까지 필요한 금액
    gaugeColor = 'base'; // 게이지의 기본 색상
    levelIndicator = ''; // 현재 등급 표시

    get formattedRecentPurchase() {
        const recentPurchase = this.customerDetails.recent_90Days__c || 0;
        return new Intl.NumberFormat('ko-KR', { style: 'currency', currency: 'KRW' }).format(recentPurchase);
    }

    get formattedNextLevelAmount() {
        return new Intl.NumberFormat('ko-KR', { style: 'currency', currency: 'KRW' }).format(this.nextLevelAmount);
    }

    @wire(getCustomerDetails, { contactId: '$recordId' })
    wiredCustomerDetails({ error, data }) {
        if (data) {
            console.log(data);
            this.customerDetails = data;
            this.calculateGaugeValues(data.recent_90Days__c);
        } else if (error) {
            console.error('Error fetching customer details:', error);
        }
    }

    calculateGaugeValues(recentPurchase) {
        const maxPurchaseAmount = 5000000; 
        this.gaugeValue = (recentPurchase / maxPurchaseAmount) * 100;
        if(!recentPurchase){
            this.nextLevelAmount = 2000000;
            this.gaugeValue = 0; 
            this.gaugeColor = 'base';
        }else if (recentPurchase == 0) {
            this.levelIndicator = 'D';
            console.log(recentPurchase);
            this.nextLevelAmount = 2000000 - recentPurchase;
            this.gaugeColor = 'base';
        } else if (recentPurchase < 2000000) {
            this.levelIndicator = 'C';
            this.nextLevelAmount = 2000000 - recentPurchase;
            this.gaugeColor = 'base'; 
        } else if (recentPurchase < 5000000) {
            this.levelIndicator = 'B';
            this.nextLevelAmount = 5000000 - recentPurchase;
            this.gaugeColor = 'active-step';
        } else {
            this.levelIndicator = 'A';
            this.nextLevelAmount = 0; 
            this.gaugeValue = 100; 
            this.gaugeColor = 'base-autocomplete';
        }
    }

    get gaugeStyle() {
        return `slds-progress-ring__progress slds-progress-ring_${this.gaugeColor}`;
    }

    get nextLevelMessage() {
        return this.nextLevelAmount > 0 ? `Next level in ₩${this.nextLevelAmount}` : 'Top level achieved';
    }

    get gaugeValueFormatted() {
        return Math.round(this.gaugeValue); 
    }
}