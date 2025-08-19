public without sharing class ContactController {
    @AuraEnabled(cacheable=true)
    public static Contact getContactDetails(Id contactId) {        
        Contact contact = [SELECT Id, Phone, Email,Speciality__c,Position__c, Name FROM Contact WHERE Id = :contactId LIMIT 1];
        logUsers(contactId);
        return contact;
    }
    
    @AuraEnabled
    public static void logUsers(Id contactId) {
        Logs__b logRecord = new Logs__b(
            Viewed_By__c = UserInfo.getUserId(),
            Viewed_Contact__c = contactId,
            Viewed_At__c = System.now(),
            What_Viewed__c = 'Phone and Email'
        );
        
        try {
            if(!test.isrunningtest())   Database.insertImmediate(logRecord);
        } catch (Exception e) {
            System.debug('Error inserting log record: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, String> updateContactDetails(Id contactId, String phone, String email) {
        Contact contactToUpdate = [
            SELECT
            	Id,
            	OwnerId,
            	Phone,
            	Email
            FROM
            	Contact
            WHERE
            	Id = :contactId LIMIT 1
        ];        
        contactToUpdate.Phone = phone;
        contactToUpdate.Email = email;
        // Map<String, String> duplicateCheckResult = getDuplicateRecords(new List<Sobject> {contactToUpdate});
        // if(duplicateCheckResult.keySet().size() == 0) {
            try{
                update contactToUpdate;
                return null;
            }
            catch(exception e){
                Map<String, String> errorMessage = new Map<String, String>();
                errorMessage.put('Other Error', e.getMessage());
                return errorMessage;

            }
        // }else{
        //     return duplicateCheckResult;
        // }
    }

     @AuraEnabled
    public static Map<String, String> updateContactDetails2(
        Id contactId, String phone,
        String email, String position,
        String speciality
    ) {
        Contact contactToUpdate = [
            SELECT
            	Id,
            	OwnerId,
            	Phone,
            	Email,
                Speciality__c,
                Position__c
            FROM
            	Contact
            WHERE
            	Id = :contactId LIMIT 1
        ];        
        contactToUpdate.Phone = phone;
        contactToUpdate.Email = email;
        contactToUpdate.Position__c = position;
        contactToUpdate.Speciality__c = speciality;
        // Map<String, String> duplicateCheckResult = getDuplicateRecords(new List<Sobject> {contactToUpdate});
        // if(duplicateCheckResult.keySet().size() == 0) {
            try{
                update contactToUpdate;
                return null;
            }
            catch(exception e){
                Map<String, String> errorMessage = new Map<String, String>();
                errorMessage.put('Other Error', e.getMessage());
                return errorMessage;

            }
        // }else{
        //     return duplicateCheckResult;
        // }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistValues() {
        List<String> positionPicklistValues = new List<String>();
        List<String> specialityPicklistValues = new List<String>();
        Map<String, List<String>> picklistMap = new Map<String, List<String>>();
        try {
            Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get('Contact').getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get('Position__c').getDescribe();
            Schema.DescribeFieldResult fieldDescribe2 = objDescribe.fields.getMap().get('Speciality__c').getDescribe();
            
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                positionPicklistValues.add(entry.getLabel());
            }
            for (Schema.PicklistEntry entry : fieldDescribe2.getPicklistValues()) {
                specialityPicklistValues.add(entry.getLabel());
            }
            picklistMap.put('Position__c', positionPicklistValues);
            picklistMap.put('Speciality__c', specialityPicklistValues);
        } catch (Exception e) {
            System.debug('Error retrieving picklist values: ' + e.getMessage());
        }
        return picklistMap;
    }
}