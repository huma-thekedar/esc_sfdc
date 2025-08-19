/**
 * Generic schedulable that optionally deletes all Duplicate_Prospect__c
 * and then runs a fixed set of phone‑prefix chunks.
 */
global class DuplicateProspectAdvChunkScheduler implements Schedulable {
    private List<String> prefixes;
    private Boolean deleteFirst;

    /**
     * @param prefixes   List of phone‐prefix strings to process in this job.
     * @param deleteFirst  If true, delete all existing Duplicate_Prospect__c before batching.
     */
    public DuplicateProspectAdvChunkScheduler(List<String> prefixes, Boolean deleteFirst) {
        this.prefixes    = prefixes;
        this.deleteFirst = deleteFirst;
    }

    global void execute(SchedulableContext sc) {
        // 1) Optionally wipe out all existing duplicates
        if (deleteFirst) {
            List<Duplicate_Prospect__c> allDups = [SELECT Id FROM Duplicate_Prospect__c];
            if (!allDups.isEmpty()) {
                delete allDups;
            }
        }

        // 2) Kick off one batch per prefix in this chunk
        for (String prefix : prefixes) {
            Database.executeBatch(
                new DuplicateProspectBatch_Adv_chunk(prefix),
                200
            );
        }
    }
}