global class ScheduleContactLevelBatch implements Schedulable {
    global void execute(SchedulableContext SC) {
        UpdateContactLevelBatch batchJob = new UpdateContactLevelBatch();
        Database.executeBatch(batchJob);
    }
}