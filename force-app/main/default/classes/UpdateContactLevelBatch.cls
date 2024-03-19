global class UpdateContactLevelBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Contact 레코드를 가져오는 쿼리
        return Database.getQueryLocator([
            SELECT Id, recent_90Days__c, Level__c
            FROM Contact
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Contact> contacts) {
        // 각 Contact의 등급을 업데이트
        for (Contact c : contacts) {
            if (c.recent_90Days__c >= 5000000) { // 500만원 이상
                c.Level__c = 'A';
            } else if (c.recent_90Days__c >= 2000000) { // 200만원 이상
                c.Level__c = 'B';
            } else if (c.recent_90Days__c > 0) { // 200만원 미만
                c.Level__c = 'C';
            } else { // 미구매
                c.Level__c = 'D';
            }
        }
        // Contact 레코드 업데이트
        update contacts;
    }

    global void finish(Database.BatchableContext BC) {
        // 필요한 경우 배치 작업 완료 후 후속 작업
    }
}