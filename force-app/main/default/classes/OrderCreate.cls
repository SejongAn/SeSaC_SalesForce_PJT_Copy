public with sharing class OrderCreate {
    
    // 특정 고객 연결된 상담 단계에 있는 Opportunity 목록을 검색
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunities(Id contactId) {
        return [SELECT Id, Name, CloseDate FROM Opportunity WHERE Contact__c = :contactId AND StageName = '상담'];//상담 상태일때만 가져옴
    }

    // 주어진 상담에 대한 상담 관련 제품을 검색
    @AuraEnabled(cacheable=true)
    public static List<OpportunityProductWrapper> getOpportunityProducts(Id opportunityId) {
        List<OpportunityLineItem> items = [SELECT Id, Product2.Name, Name, UnitPrice, Quantity, Product2.Family, ProductCode FROM OpportunityLineItem WHERE OpportunityId = :opportunityId];
        List<OpportunityProductWrapper> wrappedItems = new List<OpportunityProductWrapper>();
        for(OpportunityLineItem item : items) {
            wrappedItems.add(new OpportunityProductWrapper(item.Id, item.Product2.Name, item.UnitPrice, item.Quantity, item.Product2.Family, item.ProductCode));
        }
        return wrappedItems;
    }

    // UI를 위한 OpportunityLineItem의 추가 필드를 포함하는 래퍼 클래스
    public class OpportunityProductWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public Decimal UnitPrice;
        @AuraEnabled public Decimal Quantity;
        @AuraEnabled public String ProductFamily; 
        @AuraEnabled public String ProductCode;

        public OpportunityProductWrapper(Id Id, String Name, Decimal UnitPrice, Decimal Quantity, String ProductFamily, String ProductCode) {
            this.Id = Id;
            this.Name = Name;
            this.UnitPrice = UnitPrice;
            this.Quantity = Quantity;
            this.ProductFamily = ProductFamily; 
            this.ProductCode = ProductCode; 
        }
    }

    // Opportunity와 연관된 Order 레코드를 생성하고, 할인율, 설명, 상태를 적용
    @AuraEnabled
    public static Map<String, Object> createOrder(Id opportunityId, Double discountRate, String description, String status, Id contactId, Date day) {
        
        try {
            Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            Order order = new Order(
            OpportunityId = opportunityId,
            Discount_Rate__c = discountRate,
            AccountId = opp.AccountId,
            EffectiveDate = day,
            Status = 'Order', 
            Contact__c = contactId,
            Description = description
        );
            insert order;

            Map<String, Object> result = new Map<String, Object>();
            result.put('success', true);
            result.put('orderId', order.Id);
            return result;
        } catch (Exception e) {
            // 에러 처리: 에러 메시지를 포함한 Map 반환
            Map<String, Object> errorResult = new Map<String, Object>();
            errorResult.put('success', false);
            errorResult.put('errorMessage', e.getMessage());
            return errorResult;
        }
    }

    // OpportunityLineItem 레코드를 삭제
    @AuraEnabled
    public static void deleteOpportunityLineItem(Id lineItemId) {
        try {
            OpportunityLineItem olt = new OpportunityLineItem();
            olt =  [SELECT Id FROM OpportunityLineItem WHERE Id = :lineItemId LIMIT 1];
            delete olt;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting OpportunityLineItem: ' + e.getMessage());
        }
    }    

    // Opportunity에 특정 제품과 수량으로 새 OpportunityLineItem을 추가
    @AuraEnabled
    public static Id addOpportunityLineItem(Id opportunityId, Id productId, Decimal quantity) {
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opportunityId,
            Product2Id = productId,
            Quantity = quantity
        );
        insert oli;
        return oli.Id;
    }

    // 특정 제품(Product)과 수량을 사용하여 상담(Opportunity)에 새 OpportunityLineItem을 추가    
    @AuraEnabled
    public static String saveProductToOpportunity(Id opportunityId, Id productId, Decimal quantity) {
        try {
            Opportunity opp = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :opportunityId];
            // 해당 제품의 PricebookEntry에서 UnitPrice를 조회
            PricebookEntry pbe = [SELECT UnitPrice FROM PricebookEntry WHERE Product2Id = :productId AND Pricebook2Id = :opp.Pricebook2Id AND IsActive = true LIMIT 1];            
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opportunityId,
                Product2Id = productId,
                Quantity = quantity,
                UnitPrice = pbe.UnitPrice
            );
            insert oli;
            return oli.Id;
        } catch (Exception e) {
            throw new AuraHandledException('제품 추가에 실패했습니다: ' + e.getMessage());
        }
    }    

    // UI 선택을 위해 활성 제품들을 가져옵니다.
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getProductOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Product2 product : [SELECT Id, Name FROM Product2 WHERE IsActive = true]) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', product.Name);
            option.put('value', product.Id);
            options.add(option);
        }
        return options;
    }    

    // 주어진 제품 ID에 대한 제품 세부 정보와 가격을 가져옵니다.
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getProductDetailsWithPrice(Id productId) {
        Product2 product = [SELECT Id, Name, ProductCode, Family FROM Product2 WHERE Id = :productId LIMIT 1];   
        Id standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
        PricebookEntry pricebookEntry = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :productId AND Pricebook2Id = :standardPricebookId LIMIT 1];
        Map<String, Object> productDetails = new Map<String, Object>();
        productDetails.put('product', product);
        productDetails.put('unitPrice', pricebookEntry.UnitPrice);
        
        return productDetails;
    }   
}