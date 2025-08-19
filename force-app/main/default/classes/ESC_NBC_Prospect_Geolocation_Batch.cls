public class ESC_NBC_Prospect_Geolocation_Batch implements Database.Batchable<SObject> {
	 public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id 
            FROM ESC_NBC_Prospect__c 
            WHERE ESC_NBC_Address__Latitude__s = null 
            AND ESC_NBC_Address__Longitude__s = null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<ESC_NBC_Prospect__c> scope) {
        for (ESC_NBC_Prospect__c prospect : scope) {
            System.enqueueJob(new ESC_NBC_ProspectProcessor(prospect.Id));
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: Add post-processing logic if needed
    }

}