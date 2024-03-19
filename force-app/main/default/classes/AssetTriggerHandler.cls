public class AssetTriggerHandler {
    public void getLaptopOrdersForContact(List<Id> contactIds) {
        // Initialize sums for each contact
        Map<Id, Decimal> sumLaptopByContact = new Map<Id, Decimal>();
        Map<Id, Decimal> sumAccessoryByContact = new Map<Id, Decimal>();

        // Query Assets with Refund__c unchecked and include related Order's Discount_Rate__c
        List<Asset> assets = [
            SELECT Id, ContactId, Product2Id, PurchaseDate, Product2.Family, Price, Discount_Rate__c
            FROM Asset
            WHERE ContactId IN :contactIds
            AND Product2.Family IN ('Laptop', 'Accessory')
            AND PurchaseDate >= LAST_N_DAYS:90
            AND Refund__c = false
        ];

        // Process each Asset to sum Laptop and Accessory prices after applying discount rate
        for (Asset asset : assets) {
            Decimal itemPrice = asset.Price;
            Decimal discountRate = (asset.Order__r != null) ? asset.Discount_Rate__c : 0;
            Decimal discountedPrice = itemPrice * (1 - discountRate / 100);

            if (!sumLaptopByContact.containsKey(asset.ContactId)) {
                sumLaptopByContact.put(asset.ContactId, 0);
                sumAccessoryByContact.put(asset.ContactId, 0);
            }

            if (asset.Product2.Family == 'Laptop') {
                sumLaptopByContact.put(asset.ContactId, sumLaptopByContact.get(asset.ContactId) + discountedPrice);
            } else if (asset.Product2.Family == 'Accessory') {
                sumAccessoryByContact.put(asset.ContactId, sumAccessoryByContact.get(asset.ContactId) + discountedPrice);
            }
        }

        // Prepare Contact records for update
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Id contactId : contactIds) {
            Decimal sumLaptop = sumLaptopByContact.containsKey(contactId) ? sumLaptopByContact.get(contactId) : 0;
            Decimal sumAccessory = sumAccessoryByContact.containsKey(contactId) ? sumAccessoryByContact.get(contactId) : 0;
            Contact contact = new Contact(Id = contactId, Laptop90__c = sumLaptop, Accessory90__c = sumAccessory, recent_90Days__c = sumLaptop + sumAccessory);
            contactsToUpdate.add(contact);
        }

        // Update contacts
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
}
