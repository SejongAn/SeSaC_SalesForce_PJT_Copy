trigger CreateContactFromOpportunityTrigger on Opportunity (before insert, before update) {
    List<Contact> newContacts = new List<Contact>();    
    
    if (Trigger.isInsert) {
        // before insert에 대한 처리
        CreateContactFromOpportunityHandler.createContacts_First(Trigger.new, newContacts);
        Id standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
        for (Opportunity opp : Trigger.new) {
            opp.Pricebook2Id = standardPricebookId;
        }
    } else if (Trigger.isUpdate) {
        // before update에 대한 처리
        for (Opportunity updatedOpportunity : Trigger.new) {
            Opportunity oldOpportunity = Trigger.oldMap.get(updatedOpportunity.Id);
            Id simpleRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Simple_consulting' LIMIT 1].Id;
            Id firstRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName ='First_Consulting' LIMIT 1].Id;
            // 레코드 타입이 'A'에서 'B'로 변경된 경우에 대한 조건 추가
            if (oldOpportunity.RecordTypeId == simpleRecordTypeId && updatedOpportunity.RecordTypeId == firstRecordTypeId) {
                CreateContactFromOpportunityHandler.createContacts_Simple(Trigger.new, newContacts);
                
            }

            // 여기에 다른 조건 및 작업을 추가할 수 있습니다.
        }
    }
}