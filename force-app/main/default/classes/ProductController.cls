public with sharing class ProductController {

    @AuraEnabled(cacheable=true)
    public static List<Product2> getTopProducts() {
        // Asset에서 집계를 수행하여 상위 5개의 Product2Id를 조회합니다.
        List<AggregateResult> aggregateResults = [
            SELECT Product2Id, COUNT(Id) quantity
            FROM Asset 
            WHERE Refund__c = false 
            GROUP BY Product2Id 
            ORDER BY COUNT(Id) DESC 
            LIMIT 5
        ];
        
        // Product2Id 리스트를 생성합니다.
        List<Id> topProductIds = new List<Id>();
        for (AggregateResult ar : aggregateResults) {
            topProductIds.add((Id)ar.get('Product2Id'));
        }

        // 상위 5개의 Product2Id 순서대로 Product2 레코드를 조회합니다.
        Map<Id, Product2> productsMap = new Map<Id, Product2>(
            [SELECT Id, Name, DisplayUrl FROM Product2 WHERE Id IN :topProductIds]
        );

        // 정렬된 순서를 유지하기 위해 리스트를 생성합니다.
        List<Product2> orderedProducts = new List<Product2>();
        for (Id productId : topProductIds) {
            if (productsMap.containsKey(productId)) {
                orderedProducts.add(productsMap.get(productId));
            }
        }
        
        return orderedProducts;
    }
}