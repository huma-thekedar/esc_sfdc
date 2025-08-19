public class ESC_NBC_InactiveProspectBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext BC) {
       	Date thresholdDate;
        if(test.isRunningTest()) {
            thresholdDate  = Date.today();
        } else {
            thresholdDate  = Date.today().addDays(-15);
        }
		System.debug(thresholdDate);
		Id seanHasanId = [SELECT ID FROM USER WHERE Name =: System.Label.ESC_NBC_Inactive_Prospect_Owner LIMIT  1].ID;
        System.debug(seanHasanId); 
        String rectype = 'Active Prospect';
        String query = 'SELECT Id, OwnerId, RecordTypeId, ESC_NBC_Prospect_Status__c ' +
            'FROM ESC_NBC_Prospect__c ' +
            'WHERE RecordType.Name =:  rectype ' +
            'AND (LastModifiedDate <: thresholdDate) ' +
            'AND (LastActivityDate < :thresholdDate OR LastActivityDate = NULL) ' +
        	'AND OwnerId != :seanHasanId';    
        return Database.getqueryLocator(
            query
        );
    }

    public void execute(Database.BatchableContext BC, List<ESC_NBC_Prospect__c> records) {
        Id prospectRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'ESC_NBC_Prospect__c' AND DeveloperName = 'Prospect' LIMIT 1].Id;
   		Id seanHasanId = [SELECT ID FROM USER WHERE Name =: System.Label.ESC_NBC_Inactive_Prospect_Owner LIMIT  1].ID;
        for (ESC_NBC_Prospect__c rec : records) {
            rec.RecordTypeId = prospectRecordTypeId;
            rec.ESC_NBC_Prospect_Status__c = 'New';
            rec.OwnerId = seanHasanId;
        }
        if (!records.isEmpty()) {
            update records;
        }
    }

    public void finish(Database.BatchableContext BC) {
       
    }

    public void execute(schedulablecontext sc) {
        Database.executeBatch(new ESC_NBC_InactiveProspectBatch());
    }
}