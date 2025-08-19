global class DuplicateProspectCleanupBatch implements Database.Batchable<SObject>, Database.Stateful {
    // Holds lists of record‐Ids keyed by Index__c
    private Map<String, List<Id>> indexToIds = new Map<String, List<Id>>();

    /** 
     * QueryLocator over all Duplicate_Prospect__c — we’ll group by the formula field in memory. 
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Index__c FROM Duplicate_Prospect__c'
        );
    }

    /**
     * For each chunk of records, collect their Ids under their Index__c value
     */
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (SObject sobj : scope) {
            Duplicate_Prospect__c dp = (Duplicate_Prospect__c)sobj;
            String idx = dp.Index__c;
            if (String.isBlank(idx)) {
                // skip records with no Index__c
                continue;
            }
            if (!indexToIds.containsKey(idx)) {
                indexToIds.put(idx, new List<Id>());
            }
            indexToIds.get(idx).add(dp.Id);
        }
    }

    /**
     * After all chunks are processed, delete all but one record per Index__c
     */
    global void finish(Database.BatchableContext bc) {
        List<Duplicate_Prospect__c> toDelete = new List<Duplicate_Prospect__c>();
        // For each group, keep the first Id and delete the rest
        for (String idx : indexToIds.keySet()) {
            List<Id> ids = indexToIds.get(idx);
            if (ids.size() > 1) {
                // sort by ID to make behavior predictable, optional:
                ids.sort();
                // skip index 0
                for (Integer i = 1; i < ids.size(); i++) {
                    toDelete.add(new Duplicate_Prospect__c(Id = ids[i]));
                }
            }
        }
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
        System.debug('Cleaned up ' + toDelete.size() + ' duplicate records by Index__c');
    }
}

// To run the batch:
// Database.executeBatch(new DuplicateProspectCleanupBatch(), 200);