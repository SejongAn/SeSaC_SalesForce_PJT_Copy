public with sharing class ContactAssetsController {
    @AuraEnabled(cacheable=true)
    public static List<Asset> getAssets(Id contactId) {
    return [SELECT Id, Name, Refund__c,PurchaseDate,SerialNumber__c,Product2.Name FROM Asset WHERE ContactId = :contactId AND Refund__c = FALSE ORDER BY PurchaseDate DESC];
    }
    }