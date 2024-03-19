trigger PreventMobile on Contact (before insert, before update) {
    set<String> lstMobileno = new set<String>();
    for(Contact ct : Trigger.new) {
        if(ct.phone != null) {
            lstMobileno.add(ct.phone);
        }
    }
    
    // Query all existing records
    Map<String, Contact> mapMobileNo = new Map<String, Contact>();
    for(Contact ct : [SELECT Id, Phone, Name FROM Contact WHERE Phone IN :lstMobileno]) {
        if(!mapMobileNo.containsKey(ct.phone)) {
            mapMobileNo.put(ct.phone, ct);
        }
    }

    // Loop through the trigger.new 
    // 새로운 연락처가 생성되는 경우와 
    // 연락처의 전화번호가 변경되는 경우에만 중복 검사를 수행하도록
    for(Contact ct : Trigger.new) {
        if(ct.phone != null && mapMobileNo.containsKey(ct.phone) && (Trigger.isInsert || (Trigger.isUpdate && ct.phone != Trigger.oldMap.get(ct.Id).phone))) {
            // Check if it's an insert or an update with a different phone number
            ct.addError('기입하신 연락처는 이미 ' + mapMobileNo.get(ct.phone).Name + '고객님의 연락처로 등록되어 있습니다.');
        }
    }
}