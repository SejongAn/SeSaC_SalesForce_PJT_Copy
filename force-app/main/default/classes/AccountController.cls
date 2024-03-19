public with sharing class AccountController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountLocations() {
        return [SELECT Name, BillingCity, BillingCountry 
        FROM Account ];
    }
}