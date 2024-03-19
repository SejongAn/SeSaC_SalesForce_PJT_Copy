import { LightningElement, wire, track, api } from 'lwc';
import getOpportunities from '@salesforce/apex/OrderCreate.getOpportunities';
import getOpportunityProducts from '@salesforce/apex/OrderCreate.getOpportunityProducts';
import getProductOptions from '@salesforce/apex/OrderCreate.getProductOptions'; // Apex 메서드를 가져오는 부분
import createOrder from '@salesforce/apex/OrderCreate.createOrder';
import saveProductToOpportunity from '@salesforce/apex/OrderCreate.saveProductToOpportunity';
import deleteOpportunityLineItem from '@salesforce/apex/OrderCreate.deleteOpportunityLineItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import getProductDetailsWithPrice from '@salesforce/apex/OrderCreate.getProductDetailsWithPrice';
export default class OrderCreate extends NavigationMixin(LightningElement) {

    @track opportunityOptions = [];
    @track selectedOpportunityId = '';
    @track opportunityProducts = [];
    @track discountRate = 0;
    @track totalAmount = 0;      //총 제품 금액
    @track discountedAmount = 0; //할인된 최종 금액
    @track discountMoney = 0;    //할인된 금액
    @track orderDate;   //날짜 보여주는 용
    @track minDate;     //형식 다름 주의 이건 내부 날짜
    @track selectedProductDetails = {
        Name: '',
        ProductCode: '',
        Family: ''
    };    
    @track selectedProductPrice = '0';    
    @track formattedTotalAmount = 0;
    @track formattedDiscountedAmount = 0;
    @track formattedDiscountMoney = 0;
    wiredOpportunityProductsResult;
    @track description = '';
    @track status = '구매'; //수정 필요 예시로 띄워둠 apex에서 추가 수정
    @api recordId;
    @track isModalOpen = false;
    @track selectedProductId;
    @track selectedQuantity;
    @track isAddButtonDisabled = true;
    @track productOptions = [];
    
    @wire(getProductOptions)
    wiredProductOptions({ error, data }) {
        if (data) {
            this.productOptions = data.map(product => ({
                label: product.label, // 또는 제품명을 표시하는 데 사용하는 다른 필드
                value: product.value
            }));
        } else if (error) {
            console.error('Error:', error);
        }
    }

    handleQuantityChange(event) {
        this.selectedQuantity = event.detail.value;
    }

    handleProductChange(event) {
        this.selectedProductId = event.detail.value;
        if (this.selectedProductId) {
            getProductDetailsWithPrice({ productId: this.selectedProductId })
                .then(result => {
                    this.selectedProductDetails = result.product;
                    this.selectedProductPrice = this.formatToKRW(result.unitPrice); // 가격 정보 저장
                })
                .catch(error => {
                    console.error('제품 상세 정보 및 가격 조회 중 오류:', error);
                    this.selectedProductDetails = null;
                    this.selectedProductPrice = null;
                });
        } else {
            this.selectedProductDetails = null;
            this.selectedProductPrice = null;
        }
    }    

    actions = [
        { label: 'Delete', name: 'delete' }
    ];

    columns = [
        { label: '제품군', fieldName: 'ProductFamily', type: 'text' },
        { label: '제품 이름', fieldName: 'Name', type: 'text' },
        { label: '제품 코드', fieldName: 'ProductCode', type: 'text' },
        { label: '수량', fieldName: 'Quantity', type: 'number' },
        { label: '가격', fieldName: 'UnitPrice', type: 'currency' },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions.bind(this) },
        },    
    ];
    
    getRowActions(row, doneCallback) {
        const actions = [
            { label: 'Delete', name: 'delete' }
        ];
        doneCallback(actions);
    }

    connectedCallback() {
        if(this.selectedOpportunityId) {
            this.refreshOpportunityLineItems();
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const rowId = event.detail.row.Id;
        console.log(`Action: ${actionName}, Row Id: ${rowId}`);

        if (actionName === 'delete') {
            this.deleteOpportunityProduct(rowId);
        }
    }

    handleAddProductClick() {
        console.log('모달 열기 전 productOptions:', JSON.stringify(this.productOptions));
        this.isModalOpen = true; // 모달 열기
    }
    closeModal() {
        this.isModalOpen = false; // 모달 닫기
    }
    
    saveProduct() {
        console.log(`저장할 제품 ID: ${this.selectedProductId}, 수량: ${this.selectedQuantity}`);
        if(!this.selectedOpportunityId) {
            this.showToast('Error', '상담을 먼저 선택해주세요.', 'error');
            return;
        }            
        saveProductToOpportunity({
            opportunityId: this.selectedOpportunityId,
            productId: this.selectedProductId,
            quantity: Number(this.selectedQuantity) 
        })
        .then(result => {
            console.log('저장 결과:', result);
            this.showToast('Success', '제품이 성공적으로 추가되었습니다.', 'success');
            this.closeModal();
            this.updateOpportunityProductsAndPriceInfo(); // 제품 목록 및 가격 정보 업데이트

        })
        .catch(error => {
            console.error('저장 중 오류:', error);
            this.showToast('Error', '제품 추가 중 오류가 발생했습니다: ' + error.body.message, 'error');
        });
    }        
    deleteOpportunityProduct(lineItemId) {
        deleteOpportunityLineItem({ lineItemId })
            .then(() => {
                this.showToast('Success', '제품을 성공적으로 삭제했습니다.', 'success');
                this.updateOpportunityProductsAndPriceInfo(); // 제품 목록 및 가격 정보 업데이트
            })
            .catch(error => {
                // 에러 핸들링 개선
                console.error('삭제 에러:', error);
                this.showToast('Error', '상품 삭제 에러: ' + (error.body.message || error.message), 'error');
            });
    }
    // 제품 목록 및 가격 정보 업데이트 함수
    updateOpportunityProductsAndPriceInfo() {
        refreshApex(this.wiredOpportunityProductsResult).then(() => {
            getOpportunityProducts({ opportunityId: this.selectedOpportunityId })
            .then(data => {
                this.opportunityProducts = data;
                this.totalAmount = data.reduce((total, product) => total + (product.UnitPrice * product.Quantity), 0);
                // 화면용 금액 업데이트
                this.formattedTotalAmount = this.formatToKRW(this.totalAmount);
                this.calculateDiscountedAmount(); // 가격 정보 업데이트
            })
            .catch(error => {
                console.error('제품 목록 업데이트 중 오류 발생:', error);
            });
        });
    }        
    refreshOpportunityLineItems() {
        refreshApex(this.wiredOpportunityProductsResult).then(() => {
            console.log('상담 제품 새로고침');
        });
    }      
    @wire(getOpportunities, { contactId: '$recordId' })
    wiredOpportunities(result) {
        this.wiredOpportunityResults = result;
        if (result.data) {
            this.opportunityOptions = result.data.map(opportunity => ({ label: opportunity.Name, value: opportunity.Id, closeDate: opportunity.CloseDate }));
        } else if (result.error) {
            this.showToast('Error', result.error.body.message, 'error');
        }
    }

    //여기가 opp골랐을때~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    handleOpportunityChange(event) {
        this.selectedOpportunityId = event.target.value;
        if(this.selectedOpportunityId) {
            this.isAddButtonDisabled = false; // 상담이 선택되면 버튼 활성화
            const selectedOpportunity = this.opportunityOptions.find(
                opp => opp.value === this.selectedOpportunityId
            );
            if (selectedOpportunity && selectedOpportunity.closeDate) {
                //this.orderDate = this.formatDate(selectedOpportunity.closeDate);
                this.minDate = this.formatDateForInput(selectedOpportunity.closeDate); //
            }
        } else {
            this.isAddButtonDisabled = true; // 상담 선택이 해제되면 버튼 비활성화
        }
        getOpportunityProducts({ opportunityId: this.selectedOpportunityId })
            .then(data => {
                this.opportunityProducts = data;
                this.totalAmount = data.reduce((total, product) => total + product.UnitPrice * product.Quantity, 0);
                this.formattedTotalAmount = this.formatToKRW(this.totalAmount);
                this.calculateDiscountedAmount();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleDiscountRateChange(event) {
        this.discountRate = event.target.value;
        this.calculateDiscountedAmount();
    }

    calculateDiscountedAmount() {
        if (this.discountRate > 20) {
            this.showToast('Error', '최대 할인율은 20%입니다.', 'error');
            this.discountRate = 20;
        } else if (this.discountRate < 0) {
            this.showToast('Error', '할인율 음수는 입력 불가능합니다.', 'error');
            this.discountRate = 0;
        }
    
        this.discountedAmount = this.totalAmount * (1 - this.discountRate / 100);
        this.formattedDiscountedAmount= this.formatToKRW(this.discountedAmount);
        this.discountMoney = this.totalAmount - this.discountedAmount;
        this.formattedDiscountMoney = this.formatToKRW(this.discountMoney);
    }

    handleInputChange(event) {
        this.description = event.target.value;
    }

    //주문생성 버튼 
    handleCreateOrder() {
        if(this.discountRate==null){
            this.discountRate=0;
        }
        else {
            this.discountRate=Math.floor(Number(this.discountRate)); //소수점 제거
        }
        if(this.orderDate == null || this.orderDate.trim() === ''){
            this.showToast('Error', '주문 날짜를 입력해주세요.', 'error');
            return; 
        }
        const orderDateObj = new Date(this.orderDate);
        const minDateObj = new Date(this.minDate); 
        const currentDate = new Date();

        // 주문 날짜가 minDate보다 이르면 에러 메시지 표시
        if(orderDateObj < minDateObj) {
            this.showToast('Error', '주문 날짜는 최소 날짜 이후여야 합니다.', 'error');
            return;
        }
        if(orderDateObj > currentDate) {
            this.showToast('Error', '주문 날짜는 오늘을 넘어갈 수 없습니다.', 'error');
            return;
        }
        createOrder({ opportunityId: this.selectedOpportunityId, discountRate: this.discountRate, description: this.description, status: this.status, contactId: this.recordId, day: this.orderDate })
        .then((result) => { //사용은 안해도 일단 넣어둠
            this.refreshPage();
            this.showToast('Success', '판매가 성공적으로 생성되었습니다!', 'success');
        })
        .catch((error) => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
    refreshComponentData() {
        refreshApex(this.wiredOpportunityResults);
    }
    refreshPage() {
        // 현재 페이지의 URL을 사용하여 페이지를 새로 고침
        window.location.reload();
    }
    formatToKRW(value) {
        return new Intl.NumberFormat('ko-KR', { style: 'decimal' }).format(value);
    }
    @wire(getOpportunityProducts, { opportunityId: '$selectedOpportunityId' })
    wiredOpportunityProducts(result) {
        this.wiredOpportunityProductsResult = result; // 결과 저장
        if (result.data) {
            this.opportunityProducts = result.data;
            // 데이터 처리 로직...
        } else if (result.error) {
            // 에러 처리 로직...
        }
    } 
    //날짜
	handleDateChange(event) {
		this.orderDate = event.target.value;
	}

    //데이터 검사용 형식
    formatDateForInput(date) {
        if (date) {
            // UTC 기준으로 날짜 객체 생성
            const d = new Date(date);
            // 연, 월, 일을 UTC 기준으로 추출하여 형식에 맞게 변환합니다.
            const year = d.getUTCFullYear();
            const month = (d.getUTCMonth() + 1).toString().padStart(2, '0'); // 월은 0부터 시작하므로 1을 더해줍니다.
            const day = d.getUTCDate().toString().padStart(2, '0');
            // 'YYYY-MM-DD' 형식으로 문자열을 반환합니다.
            return `${year}-${month}-${day}`;
        }
        return null;
    }
}