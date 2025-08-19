@isTest
public class ESC_NBC_ChangeRecordTypeControllerTest {

    @isTest
    static void testUpdateToEmployeeSuccess() {
        // Query the 'Employee' RecordType
        RecordType employeeRT = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'ESC_NBC_Prospect__c' 
              AND DeveloperName = 'Employee'
            LIMIT 1
        ];

        // Query any other RecordType to use for test creation
        RecordType anotherRT = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'ESC_NBC_Prospect__c' 
              AND DeveloperName != 'Employee'
            LIMIT 1
        ];

        // Insert a test prospect with a different record type
        ESC_NBC_Prospect__c prospect = new ESC_NBC_Prospect__c(
            Name = 'Test Prospect',
            RecordTypeId = anotherRT.Id
        );
        insert prospect;

        // Call the method under test
        Test.startTest();
        ESC_NBC_ChangeRecordTypeController.updateToEmployee(prospect.Id);
        Test.stopTest();

        // Query and verify the record was updated to Employee record type
        ESC_NBC_Prospect__c updated = [
            SELECT Id, RecordTypeId 
            FROM ESC_NBC_Prospect__c 
            WHERE Id = :prospect.Id
        ];
        System.assertEquals(
            employeeRT.Id, 
            updated.RecordTypeId, 
            'RecordType should be updated to Employee'
        );
    }
}