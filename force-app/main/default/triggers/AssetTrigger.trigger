trigger AssetTrigger on Asset (after insert, after update, after delete) {
    AssetTriggerHandler handler = new AssetTriggerHandler();

    Set<Id> contactIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Asset asset : Trigger.new) {
            if (asset.Refund__c == false && (asset.Product2.Family == 'Laptop' || asset.Product2.Family == 'Accessory')) {
                if(asset.ContactId != null) {
                    contactIds.add(asset.ContactId);
                }
            }
        }
    }

    if (Trigger.isDelete) {
        for (Asset asset : Trigger.old) {
            if(asset.ContactId != null) {
                contactIds.add(asset.ContactId);
            }
        }
    }

    if (!contactIds.isEmpty()) {
        handler.getLaptopOrdersForContact(new List<Id>(contactIds));
    }
}
