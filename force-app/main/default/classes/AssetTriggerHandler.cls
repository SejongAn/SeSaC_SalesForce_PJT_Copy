public class AssetTriggerHandler {
    public void getLaptopOrdersForContact(List<Id> contactIds) {
        // Initialize sums for each contact
        Map<Id, Decimal> sumLaptopByContact = new Map<Id, Decimal>();
        Map<Id, Decimal> sumAccessoryByContact = new Map<Id, Decimal>();

        // Query Assets with Refund__c unchecked and include related Order's Discount_Rate__c
        //DB에서 원하는 정보 Asset 가져와!!
        List<Asset> assets = [
            SELECT Id, ContactId, Product2Id, PurchaseDate, Product2.Family, Price, Discount_Rate__c
            FROM Asset
            WHERE ContactId IN :contactIds
            AND Product2.Family IN ('Laptop', 'Accessory') //이거 없어도 될거 같은데
            AND PurchaseDate >= LAST_N_DAYS:90 //90일전 이후 
            AND Refund__c = false //환불상태 이라면
        ];

        // Process each Asset to sum Laptop and Accessory prices after applying discount rate
        for (Asset asset : assets) {
            Decimal itemPrice = asset.Price; //가격
            Decimal discountRate = (asset.Order__r != null) ? asset.Discount_Rate__c : 0; //연결된 Oder가 있다면, 할인률
            Decimal discountedPrice = itemPrice * (1 - discountRate / 100); //한일률 적용햇을때의 가격

            if (!sumLaptopByContact.containsKey(asset.ContactId)) { //sumLaptop이 Asset의 ContactId를 포함하고 있지 않다면 
                sumLaptopByContact.put(asset.ContactId, 0); //해당 contact의 필드 값을 0으로 초기화
                sumAccessoryByContact.put(asset.ContactId, 0);
            }

            if (asset.Product2.Family == 'Laptop') { //Laptop이라면
                sumLaptopByContact.put(asset.ContactId, sumLaptopByContact.get(asset.ContactId) + discountedPrice); 
                //해당 Contact의 필드값에 할인된 가격 추가해줌 
            } else if (asset.Product2.Family == 'Accessory') { //Accessory라
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
