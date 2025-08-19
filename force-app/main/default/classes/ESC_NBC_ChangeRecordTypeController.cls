public with sharing class ESC_NBC_ChangeRecordTypeController {
    @AuraEnabled
    public static void updateToEmployee(Id recordId) {
        try {
            RecordType employeeRT = [
                SELECT Id FROM RecordType
                WHERE SObjectType = 'ESC_NBC_Prospect__c'
                AND DeveloperName = 'Employee'
                LIMIT 1
            ];

            if (employeeRT == null) {
                throw new AuraHandledException('RecordType not found for ESC_NBC_Prospect__c with DeveloperName = Employee');
            }

            ESC_NBC_Prospect__c prospect = new ESC_NBC_Prospect__c(Id = recordId);
            prospect.RecordTypeId = employeeRT.Id;
            prospect.ESC_NBC_Prospect_Status__c = 'Employee';
            update prospect;

        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
}