public class ESC_NBC_ProspectTriggerHandler {
    public static void updateGeoCode(Map<Id,ESC_NBC_Prospect__c> newProspect, Map<Id,ESC_NBC_Prospect__c> oldProspect) {
        for(ESC_NBC_Prospect__c prospect: newProspect.values()) {
            if(
                oldProspect == null ||
                prospect.ESC_NBC_Address__City__s != oldProspect?.get(prospect.Id)?.ESC_NBC_Address__City__s ||
                //prospect.ESC_NBC_Address__CountryCode__s != oldProspect?.get(prospect.Id)?.ESC_NBC_Address__CountryCode__s ||
                //prospect.ESC_NBC_Address__GeocodeAccuracy__s != oldProspect?.get(prospect.Id)?.ESC_NBC_Address__GeocodeAccuracy__s ||
                prospect.ESC_NBC_Address__PostalCode__s != oldProspect?.get(prospect.Id)?.ESC_NBC_Address__PostalCode__s ||
                prospect.ESC_NBC_Address__StateCode__s != oldProspect?.get(prospect.Id)?.ESC_NBC_Address__StateCode__s ||
                prospect.ESC_NBC_Address__Street__s != oldProspect?.get(prospect.Id)?.ESC_NBC_Address__Street__s
             
            ){
             //  ESC_NBC_ProspectProcessor.uopdateGeoCode(prospect.Id); 
             	System.debug('inside trigger handler');
            	System.enqueueJob(new ESC_NBC_ProspectProcessor(prospect.Id));
            //    System.debug('Prospect updated'+prospect.Id);
            }
        }
    }
    
    /**
     * Deletes any Duplicate_Prospect__c records that reference
     * any Prospect deleted in this transaction.
     */
    public static void handleDelete(
        Map<Id, ESC_NBC_Prospect__c> oldMap
    ) {
        // Collect the deleted Prospect IDs
        Set<Id> deletedIds = oldMap.keySet();
        if (deletedIds.isEmpty()) return;

        // Find all duplicates where either lookup points to a deleted prospect
        List<Duplicate_Prospect__c> toDelete = [
            SELECT Id
            FROM Duplicate_Prospect__c
            WHERE Prospect_1__c IN :deletedIds
               OR Prospect_2__c IN :deletedIds
        ];

        // Remove them
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
    
}