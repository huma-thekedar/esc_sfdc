/**
 * Schedulable class to run DuplicateProspectCleanupBatch nightly at 11pm.
 */
global class DuplicateProspectCleanupScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Launch the cleanup batch with a batch size of 200
        Database.executeBatch(new DuplicateProspectCleanupBatch(), 200);
    }
}