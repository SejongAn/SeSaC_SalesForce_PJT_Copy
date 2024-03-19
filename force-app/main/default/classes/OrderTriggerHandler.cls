public without sharing class OrderTriggerHandler {
    public void afterInsert(List<Order> newOrders) {
        try{
            // Order 객체의 필드에서 추출된 Id들을 저장할 List를 선언합니다.
            List<Id> oppIds = new List<Id>();
            List<Id> contactIds = new List<Id>();
            List<Id> orderIds = new List<Id>();
            List<Id> productIds = new List<Id>();
    
            // 새로 생성된 Order 객체들을 순회하며, 필요한 필드의 Id를 각각의 List에 추가합니다.
            for (Order order : newOrders) {
                oppIds.add(order.OpportunityId);
                contactIds.add(order.Contact__c);
                orderIds.add(order.Id);
            }

            // Order와 연결된 Contact의 First_Purchase__c 저장을 위한 Map 생성
            Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, AccountId,First_Purchase__c FROM Contact WHERE Id IN :contactIds]);

            // Contact들과 관련된 Asset을 조회하기 위한 Map을 생성합니다.
            Map<Id, List<Asset>> contactToAssetsMap = new Map<Id, List<Asset>>();

            // 고객의 Asset을 판별해서 인입지점 세팅을 위해 Contact 객체를 저장할 List 선언.
            List<Contact> contactsToUpdateForAccount = new List<Contact>();

            // SOQL 쿼리를 사용하여 추출한 OpportunityId를 가진 모든 OpportunityLineItem을 조회합니다.
            List<OpportunityLineItem> oppLineItems = [SELECT Id, OpportunityId, Product2Id, Quantity, UnitPrice, PricebookEntryId, PricebookEntry.Pricebook2Id FROM OpportunityLineItem WHERE OpportunityId IN :oppIds];
    
            // SOQL 쿼리를 사용하여 추출한 OpportunityId를 가진 모든 Opportunity를 조회하고, 이를 Map에 저장합니다.
            // 이 Map은 나중에 Order의 Pricebook2Id를 업데이트할 때 사용됩니다.
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Pricebook2Id FROM Opportunity WHERE Id IN :oppIds]);
    
            // SOQL 쿼리를 사용하여 추출한 OrderId를 가진 모든 Order를 조회합니다. 이들은 나중에 Pricebook2Id를 업데이트할 때 사용됩니다.
            List<Order> ordersToUpdate = [SELECT Id, OpportunityId FROM Order WHERE Id IN :orderIds];
    
            // SOQL 쿼리를 사용하여 추출한 OpportunityId를 가진 모든 Opportunity를 조회합니다. 이들은 나중에 StageName을 업데이트할 때 사용됩니다.
            List<Opportunity> oppsToUpdate = [SELECT Id, StageName FROM Opportunity WHERE Id IN :oppIds];
    
            // RecordType을 'CS'에서 'Buy'로 변경할 Contact 객체를 저장할 List를 선언합니다.
            List<Contact> contactsToUpdate = new List<Contact>();

            // Asset을 조회하여 ContactId를 키로, 해당 Contact에 연결된 Asset 리스트를 값으로 가지는 Map을 생성합니다.
            for (Asset asset : [SELECT Id, Refund__c, ContactId FROM Asset WHERE ContactId IN :contactIds]) {
                if (!contactToAssetsMap.containsKey(asset.ContactId)) {
                    contactToAssetsMap.put(asset.ContactId, new List<Asset>());
                }
                contactToAssetsMap.get(asset.ContactId).add(asset);
            }
            // 판매를 순회합니다.
            for (Order order : newOrders) {
                // order의 Contact__c를 키로 사용하여 contactMap에서 Contact를 조회합니다.    
                Contact relatedContact = contactMap.get(order.Contact__c);
                // order의 Contact__c를 키로 사용하여 contactToAssetsMap에서 Asset 리스트를 조회합니다.
                List<Asset> relatedAssets = contactToAssetsMap.get(order.Contact__c);
                if (relatedContact != null) {
                    // relatedContact의 AccountId가 null인 경우, 주문의 AccountId를 설정하고 업데이트 대상 리스트에 추가합니다.
                    if (relatedContact.First_Purchase__c == null) {
                        relatedContact.First_Purchase__c = order.AccountId;
                        contactsToUpdateForAccount.add(relatedContact);
                    } else if (relatedAssets != null) {
                        Boolean allRefunded = true;
                        // Asset을 순회하며, 모든 Asset이 Refund 상태인지 확인합니다.    
                        for (Asset asset : relatedAssets) {
                            // Asset이 Refund 상태가 아니라면 allRefunded를 false로 설정하고 루프를 종료합니다.
                            if (asset.Refund__c != true) {
                                allRefunded = false;
                                break;
                            }
                        }
                        // 모든 Asset이 Refund 상태라면, relatedContact의 AccountId를 주문의 AccountId로 설정하고 업데이트 대상 리스트에 추가합니다.
                        if (allRefunded) {
                            relatedContact.First_Purchase__c = order.AccountId;
                            contactsToUpdateForAccount.add(relatedContact);
                        }
                    }
                }
            }
            // 업데이트 대상 리스트가 비어 있지 않다면, 리스트에 있는 모든 Contact를 한 번에 업데이트합니다.
            if (!contactsToUpdateForAccount.isEmpty()) {
                update contactsToUpdateForAccount;
            }       

            // OpportunityLineItem 객체들을 순회하며, 각각의 Product2Id를 productIds List에 추가합니다.
            for (OpportunityLineItem oppLineItem : oppLineItems) {
                productIds.add(oppLineItem.Product2Id);
            }
    
            // Order 객체들을 순회하며, 각각의 Pricebook2Id를 oppMap에서 찾아 업데이트합니다.
            for (Order order : ordersToUpdate) {
                Opportunity opp = oppMap.get(order.OpportunityId);
                order.Pricebook2Id = opp.Pricebook2Id;
            }
            // Pricebook2Id가 업데이트된 Order 객체들을 데이터베이스에 반영합니다.
            update ordersToUpdate;
    
            // Order 객체들을 다시 조회하여, 각각의 OpportunityId를 키로 가지는 Map에 저장합니다.
            Map<Id, Order> orderMap = new Map<Id, Order>();
            for (Order order : [SELECT Id, AccountId,OpportunityId, Contact__c, Pricebook2Id,EffectiveDate FROM Order WHERE Id IN :orderIds]) {
                orderMap.put(order.OpportunityId, order);
            }
    
            // Opportunity 객체들을 순회하며, StageName이 '상담'인 경우 '구매'로 변경합니다.
            for (Opportunity opp : oppsToUpdate) {
                if (opp.StageName == '상담') {  
                    opp.StageName = '구매';
                }
            }
            // StageName이 업데이트된 Opportunity 객체들을 데이터베이스에 반영합니다.
            update oppsToUpdate;
    
            // RecordType Id를 조회하기 위한 SOQL 쿼리를 실행합니다.
            RecordType consultingRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'contactRecordType' LIMIT 1];
            RecordType buyingRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'buyContactRecordType' LIMIT 1];
    
            // RecordType을 'CS'에서 'Buy'로 변경해야 할 Contact 객체들을 조회합니다.
            List<Contact> contacts = [SELECT Id, RecordTypeId FROM Contact WHERE Id IN :contactIds AND RecordTypeId = :consultingRT.Id];
    
            // Contact 객체들을 순회하며, RecordType을 'CS'에서 'Buy'로 변경하고, 이를 contactsToUpdate List에 추가합니다.
            for (Contact con : contacts) {
                if (con.RecordTypeId == consultingRT.Id) {
                    con.RecordTypeId = buyingRT.Id;
                    contactsToUpdate.add(con);
                }
            }
            // RecordType이 업데이트된 Contact 객체들을 데이터베이스에 반영합니다.
            if (!contactsToUpdate.isEmpty()) {
                update contactsToUpdate;
            }
    
            // OrderItem과 Asset 객체를 저장할 List를 선언합니다.
            List<OrderItem> orderItems = new List<OrderItem>();
            List<Asset> assets = new List<Asset>();
    
            // Contact의 이름과 Product의 이름을 저장할 Map을 선언합니다.
            Map<Id, String> contactNameMap = new Map<Id, String>();
            Map<Id, String> productNameMap = new Map<Id, String>();
    
            // Contact 객체들을 조회하여, 각각의 이름을 contactNameMap에 저장합니다.
            for (Contact contact : [SELECT Id, Name FROM Contact WHERE Id IN :contactIds]) {
                contactNameMap.put(contact.Id, contact.Name);
            }
            // Product 객체들을 조회하여, 각각의 이름을 productNameMap에 저장합니다.
            for (Product2 product : [SELECT Id, Name FROM Product2 WHERE Id IN :productIds]) {
                productNameMap.put(product.Id, product.Name);
            }
            Map<Id, Double> totalAmounts = new Map<Id, Double>();

            // OpportunityLineItem 객체들을 순회하며, 각각에 대응하는 OrderItem과 Asset 객체를 생성합니다.
            for (OpportunityLineItem oppLineItem : oppLineItems) {
                Order order = orderMap.get(oppLineItem.OpportunityId);
                if (order != null) {
                    OrderItem orderItem = new OrderItem();
                    orderItem.OrderId = order.Id;
                    orderItem.Product2Id = oppLineItem.Product2Id;
                    orderItem.Quantity = oppLineItem.Quantity;
                    orderItem.UnitPrice = oppLineItem.UnitPrice;
                    orderItem.PricebookEntryId = oppLineItem.PricebookEntryId;
                    orderItems.add(orderItem);
                    // 각 상품의 총 가격을 계산하고 주문의 총 금액에 더함
                    Double itemTotalAmount = oppLineItem.Quantity * oppLineItem.UnitPrice;
                    if (!totalAmounts.containsKey(order.Id)) {
                        totalAmounts.put(order.Id, 0.0);
                    }
                    totalAmounts.put(order.Id, totalAmounts.get(order.Id) + itemTotalAmount);
        
                    for (Integer i = 0; i < oppLineItem.Quantity; i++) {
                        Asset asset = new Asset();
                        asset.AccountId = order.AccountId;
                        asset.Price = oppLineItem.UnitPrice;
                        asset.Order__c = order.Id;
                        asset.ContactId = order.Contact__c;
                        asset.Product2Id = oppLineItem.Product2Id;
                        asset.Quantity = 1;
                        asset.SerialNumber__c = String.valueOf(Math.random()).substring(2,8) + '_' + DateTime.now().getTime();
                        asset.PurchaseDate = order.EffectiveDate;
                        asset.Name = contactNameMap.get(order.Contact__c) + '-' + productNameMap.get(oppLineItem.Product2Id) + '-' + i;
                        assets.add(asset);
                    }
                }
            }
            // 생성된 OrderItem과 Asset 객체들을 데이터베이스에 저장합니다.
            insert orderItems;
            insert assets;
            calculateDiscountedAmountAndSendEmail(newOrders,totalAmounts);
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }

    
    public void calculateDiscountedAmountAndSendEmail(List<Order> orders, Map<Id, Double> totalAmounts) {
        List<Order> ordersToUpdate = new List<Order>();
        List<String> emailAddresses = new List<String>();
        Set<String> userIds = new Set<String>();
        // 사용자 정의 알림 ID 가져오기
        CustomNotificationType type = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'DiscountNotification'];
        String notificationTypeId = type.Id;
        // 'Manager' 롤을 가진 유저들의 이메일 주소 및 ID 가져오기
        for (User u : [SELECT Id, Email FROM User WHERE UserRole.Name = 'Headquarters Manager']) {
            emailAddresses.add(u.Email);
            userIds.add(u.Id);  // 사용자 ID 추가
        }

        for (Order order : orders) {
            Order orderToUpdate = new Order(Id = order.Id); // 새 Order 객체 생성 후 Id 설정
            Double discountRate = order.DIscount_Rate__c;
            Double totalAmount = totalAmounts.get(order.Id);
            Double discountedAmount = totalAmount - (totalAmount * (discountRate/100));
            Integer discountedAmountInt = Integer.valueOf(discountedAmount.intValue());
            // 숫자를 콤마로 구분된 문자열로 변환
            String discountedAmountStr = discountedAmountInt.format();

            orderToUpdate.discountedAmount__c = discountedAmount;  // 할인된 금액 저장
            ordersToUpdate.add(orderToUpdate);
    
            // 할인율이 10% 이상이거나 할인된 금액이 30만원 이상인 경우 이메일 보내기
            if (discountRate >= 10 || (totalAmount - discountedAmount) >= 300000) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(emailAddresses);
                mail.setSubject('할인 알림');
                mail.setPlainTextBody('판매 번호: ' + order.OrderNumber + '은(는) 할인율 ' + discountRate + '%이며 할인 적용 최종금액은 ' + discountedAmountStr + '원 입니다.');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   

                // push알림 보내기
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setNotificationTypeId(notificationTypeId);
                notification.setTitle('할인 알림');
                notification.setBody('판매 번호: ' + order.OrderNumber + '은(는) 할인율 ' + discountRate + '%이며 할인 적용 최종금액은 ' + discountedAmountStr + '원 입니다.');
                notification.setTargetId(order.Id);
                try {
                    notification.send(userIds);  // 사용자 ID 세트
                } catch (Exception e) {
                    System.debug('할인 알림 오류: ' + e.getMessage());
                }
            }
        }
    
        try {
            update ordersToUpdate; // 리스트에 추가된 Order 레코드 업데이트
        } catch (Exception e) {
            System.debug('Error updating orders: ' + e.getMessage());
        }
    }
    
    public void statusUpdate(List<Order> oldOrders, List<Order> newOrders) {
        // 환불로 표시될 Asset들과 업데이트될 Contact들을 저장할 List를 선언합니다.
        List<Asset> assetsToUpdate = new List<Asset>();
        List<Contact> contactsToUpdate = new List<Contact>();
        
        // '상담고객' 레코드 타입의 ID를 조회합니다.
        RecordType consultingRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'contactRecordType' LIMIT 1];
        
        // Contact Id를 키로, 해당 Contact와 연결된 Asset들의 List를 값으로 가지는 Map을 선언합니다.
        Map<Id, List<Asset>> contactToAssets = new Map<Id, List<Asset>>();
        
        // 필요한 모든 Asset을 한 번에 조회합니다.
        for (Asset asset : [SELECT Id, ContactId,Order__c, Refund__c FROM Asset WHERE ContactId IN (SELECT Contact__c FROM Order WHERE Id IN :newOrders)]) {
            // 조회된 Asset의 Contact Id가 Map에 없다면, 해당 Id와 빈 List를 Map에 추가합니다.
            if (!contactToAssets.containsKey(asset.ContactId)) {
                contactToAssets.put(asset.ContactId, new List<Asset>());
            }
            // Map에서 해당 Contact Id에 연결된 List를 찾아 Asset을 추가합니다.
            contactToAssets.get(asset.ContactId).add(asset);
        }
        
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, RecordTypeId FROM Contact WHERE Id IN (SELECT Contact__c FROM Order WHERE Id IN :newOrders)]);
        
        // 각각의 Order에 대해 환불 상태를 확인하고, 필요한 경우 Asset과 Contact를 업데이트합니다.
        for (Integer i = 0; i < newOrders.size(); i++) {
            // 주문 상태가 환불로 변경되었는지 확인합니다.
            if (newOrders[i].Status == 'Refund' && oldOrders[i].Status != 'Refund') {
                // 해당 Contact와 연결된 Asset들을 Map에서 찾습니다.
                List<Asset> assets = contactToAssets.get(newOrders[i].Contact__c);
    
                // 각각의 Asset에 대해 환불 상태를 업데이트합니다.
                for (Asset asset : assets) {
                    if (asset.Order__c == newOrders[i].Id) {
                        asset.Refund__c = true;
                        assetsToUpdate.add(asset);
                    }
                }
    
                // 해당 고객이 가지고 있는 모든 Asset이 환불 상태인지 확인합니다.
                Boolean allAssetsRefunded = true;
                for (Asset a : assets) {
                    if (a.Refund__c == false) {
                        allAssetsRefunded = false;
                        break;
                    }
                }
    
                // 모든 Asset이 환불되었는지 확인하고, 필요한 경우 Contact를 업데이트합니다.
                if (allAssetsRefunded) {
                    Contact contact = contactsMap.get(newOrders[i].Contact__c);
                    if (contact != null) {
                        contact.RecordTypeId = consultingRT.Id;
                        contactsToUpdate.add(contact);
                    }
                }
            }
        }
    
        // 업데이트할 모든 Asset을 한 번에 업데이트합니다.
        update assetsToUpdate;
    
        // 업데이트할 모든 Contact을 한 번에 업데이트합니다.
        update contactsToUpdate;
    }
    
    
    

    public void getLaptopOrdersForContact(List<Id> contactIds) {
        //구매 금액 합
        Decimal sumLaptop=0;
        Decimal sumAccessory=0;

        // 쿼리 실행
        List<Order> orders = [
            SELECT Id, DIscount_Rate__c,
                (SELECT Id, Product2Id, Quantity, TotalPrice,Product2.Family 
                FROM OrderItems 
                WHERE Product2.Family IN ('Laptop', 'Accessory'))
            FROM Order
            WHERE Contact__c = :contactIds
            AND Status = 'Order'
            AND EffectiveDate >= LAST_N_DAYS:90
        ];
        System.debug(orders);
        for (Order ord : orders) {
            for (OrderItem oi : ord.OrderItems) {
                Decimal itemAmount = (oi.TotalPrice * (1 - (ord.DIscount_Rate__c / 100)));
                if (oi.Product2.Family == 'Laptop') {
                    sumLaptop += itemAmount;
                } else if (oi.Product2.Family == 'Accessory') {
                    sumAccessory += itemAmount;
                }
            }
        }
        //contactsToUpdate를 하기 위해 리스트에 담고 아이디 값과 같이 필드값을 갱신
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Id contactId : contactIds) {
            Contact contact = new Contact(Id = contactId, Laptop90__c = sumLaptop, Accessory90__c=sumAccessory, recent_90Days__c=sumLaptop+sumAccessory);
            contactsToUpdate.add(contact);
        }

        // Update contacts
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }

    // 할인율 변경 시 처리를 위한 메서드
    public void handleDiscountRateChange(List<Order> oldOrders, List<Order> newOrders) {
        List<Order> ordersToUpdate = new List<Order>();

        for (Integer i = 0; i < newOrders.size(); i++) {
            Order newOrder = newOrders[i];
            Order oldOrder = oldOrders[i];

            // 할인율이 변경되었는지 확인
            if (newOrder.DIscount_Rate__c != oldOrder.DIscount_Rate__c) {
                Double discountedAmount = newOrder.TotalAmount * (1 - newOrder.DIscount_Rate__c / 100);
                Order orderToUpdate = new Order(Id = newOrder.Id);
                orderToUpdate.DIscountedAmount__c = discountedAmount;
                ordersToUpdate.add(orderToUpdate);

            }
        }

        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }    
}