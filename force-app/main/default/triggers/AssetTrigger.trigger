trigger AssetTrigger on Asset (after insert, after update, after delete) {
    //핸들러 사용을 위한 선언
    AssetTriggerHandler handler = new AssetTriggerHandler();

    //조건에 부합하는 ID값을 담을 Set(왜 리스트로 안했는지 의문)
    Set<Id> contactIds = new Set<Id>();

    //입력되거나 업데이트가 됬을때
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Asset asset : Trigger.new) {
            //환불 상태가 아니고(?), Family체크(체크 불필요 하다 생각)
            if (asset.Refund__c == false && (asset.Product2.Family == 'Laptop' || asset.Product2.Family == 'Accessory')) {
                if(asset.ContactId != null) {
                    contactIds.add(asset.ContactId);
                }
            }
        }
    }

    //삭제 됐을때
    if (Trigger.isDelete) {
        for (Asset asset : Trigger.old) {
            //Asset의 Contact(고객) 입력이 비어 있지 않다면 -> 해당 고객의 Rollup filed를 업데이트 해야하기에
            if(asset.ContactId != null) {
                contactIds.add(asset.ContactId);
            }
        }
    }

    if (!contactIds.isEmpty()) {
        //위에서 리스트로 선언했다면 여기서 리스트로 전환 할 필요가 없지 않나 의문 
        handler.getLaptopOrdersForContact(new List<Id>(contactIds));
    }
}
