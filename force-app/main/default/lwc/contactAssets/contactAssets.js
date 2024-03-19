import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAssets from '@salesforce/apex/ContactAssetsController.getAssets';

export default class ContactAssets extends NavigationMixin(LightningElement) {
@api recordId;
@track searchKey = ''; // 검색어 상태 관리
@track assetCount = 0; // 자산 개수 초기화
@track assets = [];    // 자산 데이터를 저장할 변수 초기화

@track columns = [
    { label: '자산명', fieldName: 'Name', type: 'button', 
      typeAttributes: { label: { fieldName: 'Name' }, variant: 'base' }},
    { label: '제품명', fieldName: 'ProductName', type: 'text' },
    { label: '시리얼 넘버', fieldName: 'SerialNumber__c' },
    { label: '구매일', fieldName: 'PurchaseDate', type: 'date' }
];

@wire(getAssets, { contactId: '$recordId' })
wiredAssets(response) {
    if (response.data) {
        this.assets = response.data;
        this.assetCount = response.data.length; // 쿼리된 자산의 개수 업데이트
    } else if (response.error) {
        // 에러 처리
        this.assets = [];
        this.assetCount = 0;
    }
}

get processedAssets() {
    // 이제 assets 필드를 기반으로 데이터 처리
    return this.assets.map(asset => {
        const { Product2, Id, ...otherProps } = asset;
        return { ProductName: Product2.Name, Id, ...otherProps };
    }).filter(asset => {
        const searchKeyLower = this.searchKey.toLowerCase();
        return !this.searchKey || asset.Name.toLowerCase().includes(searchKeyLower)
               || asset.ProductName.toLowerCase().includes(searchKeyLower)
               || (asset.SerialNumber__c && asset.SerialNumber__c.toLowerCase().includes(searchKeyLower));
    });
}

handleSearch(event) {
    this.searchKey = event.target.value;
}
navigateToRecord(event) {
    const assetId = event.detail.row.Id; // Get the Id of the clicked asset
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: assetId,
            actionName: 'view'
        },
    });
}

}