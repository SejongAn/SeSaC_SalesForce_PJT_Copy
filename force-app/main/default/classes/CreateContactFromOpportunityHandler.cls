//현재 Org
public class CreateContactFromOpportunityHandler {
    public static void createContacts_First(List<Opportunity> newOpportunities, List<Contact> newContacts) {
        // 기존 연락처에 있는 연락처들을 Map 변수 existingMobileContacts에 담는다. (전화번호부)
        Map<String, Contact> existingMobileContacts = new Map<String, Contact>();
        for (Contact existingContact : [SELECT Id, Phone, Name FROM Contact]) {
            existingMobileContacts.put(existingContact.Phone, existingContact);  // .put(key, value) 값으로 Map 변수에 저장 / 타입은 각각 String과 contact
        }

        // 첫방문 상담, 고객 레코드 타입 ID 가져오기
        Id firstRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName ='First_Consulting' LIMIT 1].Id;
        Id contactRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'contactRecordType' LIMIT 1].Id;

        for (Opportunity opp : newOpportunities) {
            if (opp.RecordTypeId == firstRecordTypeId) {
                // 휴대전화 번호 유효성 검사
                if (!String.isBlank(opp.New_Contact_Phone__c) &&
                    !Pattern.matches('[0-9]{3}-[0-9]{4}-[0-9]{4}', opp.New_Contact_Phone__c)) {
                    // 휴대전화 번호가 비어 있지 않고 특정 형식을 따르지 않으면 에러 처리
                    opp.addError('휴대전화 번호를 000-0000-0000 형식으로 기입해주세요 (Ex: 010-1234-5678)');
                } else if (existingMobileContacts.containsKey(opp.New_Contact_Phone__c)) {
                    // 중복된 휴대전화 번호일 경우 에러 처리 및 기존 연락처 정보 표시
                    Contact existingContact = existingMobileContacts.get(opp.New_Contact_Phone__c);
                    opp.addError('기입하신 연락처는 이미 ' + existingContact.Name + ' 고객님의 연락처로 등록되어 있습니다.');
                } else {
                    // 새로운 연락처 생성
                    Contact newContact = new Contact(
                        LastName = opp.New_Last_Name__c,
                        FirstName = opp.New_First_Name__c,
                        Email = opp.New_Contact_Email__c,
                        Phone = opp.New_Contact_Phone__c,
                        AccountId = opp.AccountId,
                        RecordTypeId = contactRecordTypeId,
                        Level__c = 'D'
                    );

                    newContacts.add(newContact);
                }
            }
        }

        // 새로운 연락처를 대량으로 삽입
        if (!newContacts.isEmpty()) {
            try {
                Insert newContacts;
            } catch (DmlException e) {
                // DML 예외 처리가 필요한 경우
                System.debug('연락처 삽입 오류: ' + e.getMessage());
            }
}
        // 고객 - 상담 연결부분 : 고객 Related list 상담(1)
        for (Integer i = 0; i < newOpportunities.size() && i < newContacts.size(); i++) {
            Opportunity opp = newOpportunities[i];
            if (opp.RecordTypeId == firstRecordTypeId && newContacts[i].Id != null) {
                opp.Contact__c = newContacts[i].Id;
            }
        }
    }
    public static void createContacts_Simple(List<Opportunity> newOpportunities, List<Contact> newContacts) {
        for (Opportunity opp : newOpportunities) {
        opp.StageName = '상담';
        }        
        // 기존 연락처에 있는 연락처들을 Map 변수 existingMobileContacts에 담는다. (전화번호부)
        Map<String, Contact> existingMobileContacts = new Map<String, Contact>();
        for (Contact existingContact : [SELECT Id, Phone, Name FROM Contact]) {
            existingMobileContacts.put(existingContact.Phone, existingContact);  // .put(key, value) 값으로 Map 변수에 저장 / 타입은 각각 String과 contact
        }

        // 단순상담, 첫방문 상담, 고객 레코드 타입 ID 가져오기
        Id simpleRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName = 'Simple_consulting' LIMIT 1].Id;
        Id firstRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND DeveloperName ='First_Consulting' LIMIT 1].Id;
        Id contactRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'contactRecordType' LIMIT 1].Id;
        
        for (Opportunity opp : newOpportunities) {
            if (opp.RecordTypeId == firstRecordTypeId) {
                // 휴대전화 번호 유효성 검사
                if (!String.isBlank(opp.New_Contact_Phone__c) &&
                    !Pattern.matches('[0-9]{3}-[0-9]{4}-[0-9]{4}', opp.New_Contact_Phone__c)) {
                    // 휴대전화 번호가 비어 있지 않고 특정 형식을 따르지 않으면 에러 처리
                    opp.addError('휴대전화 번호를 000-0000-0000 형식으로 기입해주세요 (Ex: 010-1234-5678)');
                } else if (existingMobileContacts.containsKey(opp.New_Contact_Phone__c)) {
                    // 중복된 휴대전화 번호일 경우 에러 처리 및 기존 연락처 정보 표시
                    Contact existingContact = existingMobileContacts.get(opp.New_Contact_Phone__c);
                    opp.addError('기입하신 연락처는 이미 ' + existingContact.Name + ' 고객님의 연락처로 등록되어 있습니다.');
                } else {
                    // 새로운 연락처 생성
                    Contact newContact = new Contact(
                        LastName = opp.New_Last_Name__c,
                        FirstName = opp.New_First_Name__c,
                        Email = opp.New_Contact_Email__c,
                        Phone = opp.New_Contact_Phone__c,
                        AccountId = opp.AccountId,
                        RecordTypeId = contactRecordTypeId,
                        Level__c = 'D'
                    );

                    newContacts.add(newContact);
                }
            }
        }

        // 새로운 연락처를 대량으로 삽입
        if (!newContacts.isEmpty()) {
            try {
                Insert newContacts;
            } catch (DmlException e) {
                // DML 예외 처리가 필요한 경우
                System.debug('연락처 삽입 오류: ' + e.getMessage());
            }
}
        // 고객 - 상담 연결부분 : 고객 Related list 상담(1)
        for (Integer i = 0; i < newOpportunities.size() && i < newContacts.size(); i++) {
            Opportunity opp = newOpportunities[i];
            if (opp.RecordTypeId == firstRecordTypeId && newContacts[i].Id != null) {
                opp.Contact__c = newContacts[i].Id;
            }
        }
    }
}