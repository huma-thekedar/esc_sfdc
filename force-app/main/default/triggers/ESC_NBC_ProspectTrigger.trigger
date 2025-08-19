trigger ESC_NBC_ProspectTrigger on ESC_NBC_Prospect__c (after insert, after update) {
    if(trigger.isAfter) {
        if(trigger.isInsert) {
            ESC_NBC_ProspectTriggerHandler.updateGeoCode(trigger.newMap, trigger.oldMap);
        }
        if(trigger.isUpdate) {
            ESC_NBC_ProspectTriggerHandler.updateGeoCode(trigger.newMap, trigger.oldMap);
        }
        
    }
    
     if(trigger.isBefore) {
     if (Trigger.isDelete) {
            // Pass the map of deleted records into the handler
            ESC_NBC_ProspectTriggerHandler.handleDelete(Trigger.oldMap);
        }
     }
}