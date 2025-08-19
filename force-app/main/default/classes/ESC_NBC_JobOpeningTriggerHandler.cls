public class ESC_NBC_JobOpeningTriggerHandler {
    public static void updateGeoCode(Map<Id,Job_Opening__c> newJO, Map<Id,Job_Opening__c> oldJO) {
        for(Job_Opening__c newJOObj: newJO.values()) {
            if(
                oldJO == null ||
                newJOObj.Address__City__s != oldJO?.get(newJOObj.Id)?.Address__City__s ||
                //newJOObj.Address__CountryCode__s != oldJO?.get(newJOObj.Id)?.Address__CountryCode__s ||
                //newJOObj.Address__GeocodeAccuracy__s != oldJO?.get(newJOObj.Id)?.Address__GeocodeAccuracy__s ||
                newJOObj.Address__PostalCode__s != oldJO?.get(newJOObj.Id)?.Address__PostalCode__s ||
                newJOObj.Address__StateCode__s != oldJO?.get(newJOObj.Id)?.Address__StateCode__s ||
                newJOObj.Address__Street__s != oldJO?.get(newJOObj.Id)?.Address__Street__s
            ){  
              System.enqueueJob(new ESC_NBC_JobOpeningProcessor(newJOObj.Id));
              System.debug('Job opening updated'+newJOObj.Id);
            }
        }
    }
}