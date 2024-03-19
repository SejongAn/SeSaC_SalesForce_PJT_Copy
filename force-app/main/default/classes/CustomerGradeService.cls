public without sharing class CustomerGradeService {
    @AuraEnabled(cacheable=true)
    public static Contact getCustomerDetails(Id contactId) {
        return [SELECT Level__c, recent_90Days__c FROM Contact WHERE Id = :contactId LIMIT 1];
    }
}