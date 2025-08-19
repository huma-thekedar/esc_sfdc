public class ESC_NBC_Prospect_Controller {

    @AuraEnabled(cacheable=true)
    public static ESC_NBC_Prospect__c getContactDetails(Id prospectId) {        
        ESC_NBC_Prospect__c prospect = [
			SELECT
				Id,
				Name,
				ESC_NBC_Phone__c,
				ESC_NBC_Email__c,
				ESC_NBC_Speciality__c,
				ESC_NBC_Job_Title__c,
                RecordType.Name
			FROM
				ESC_NBC_Prospect__c
			WHERE
				Id = :prospectId
		];
        logUsers(prospectId);
        return prospect;
    }
    
    @AuraEnabled
    public static void logUsers(Id prospectId) {
        Logs__b logRecord = new Logs__b(
            Viewed_By__c = UserInfo.getUserId(),
            Viewed_Contact__c = prospectId,
            Viewed_At__c = System.now(),
            What_Viewed__c = 'Phone and Email'
        );
        
        try {
            if(!test.isrunningtest()) {
				Database.insertImmediate(logRecord);
			}
        } catch (Exception e) {
            System.debug('Error inserting log record: ' + e.getMessage());
        }
    }
	
	@AuraEnabled
    public static Map<String, String> updateContactDetails2(ESC_NBC_Prospect__c prospectData) {
		try{
			update prospectData;
			return null;
		}
		catch(exception e){
			Map<String, String> errorMessage = new Map<String, String>();
			errorMessage.put('Other Error', e.getMessage());
			System.debug('Error' + e.getMessage());
			return errorMessage;
		}
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistValues() {
        List<String> positionPicklistValues = new List<String>();
        List<String> specialityPicklistValues = new List<String>();
        Map<String, List<String>> picklistMap = new Map<String, List<String>>();
        try {
            Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get('ESC_NBC_Prospect__c').getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get('ESC_NBC_Job_Title__c').getDescribe();
            Schema.DescribeFieldResult fieldDescribe2 = objDescribe.fields.getMap().get('ESC_NBC_Speciality__c').getDescribe();
            
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                positionPicklistValues.add(entry.getLabel());
            }
            for (Schema.PicklistEntry entry : fieldDescribe2.getPicklistValues()) {
                specialityPicklistValues.add(entry.getLabel());
            }
            picklistMap.put('ESC_NBC_Job_Title__c', positionPicklistValues);
            picklistMap.put('ESC_NBC_Speciality__c', specialityPicklistValues);
        } catch (Exception e) {
            System.debug('Error retrieving picklist values: ' + e.getMessage());
        }
        return picklistMap;
    }
}