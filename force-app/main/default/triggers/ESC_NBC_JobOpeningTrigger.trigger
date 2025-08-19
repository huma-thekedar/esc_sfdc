trigger ESC_NBC_JobOpeningTrigger on Job_Opening__c (after insert, after update) {
    if(trigger.isAfter) {
        if(trigger.isInsert) {
           // ESC_NBC_JobOpeningTriggerHandler.updateGeoCode(trigger.newMap, trigger.oldMap);
        }
        if(trigger.isUpdate) {
           // ESC_NBC_JobOpeningTriggerHandler.updateGeoCode(trigger.newMap, trigger.oldMap);
        }
    }
}