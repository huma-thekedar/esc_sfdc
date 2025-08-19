@isTest
public class ESC_NBC_InactiveProspectBatchTest {

    @testSetup
    static void setupData() {
        // Create a mock user to act as Sean Hasan
        User seanHasan = new User(
            FirstName = 'Sean',
            LastName = 'Hasan',
            Email = 'sean.hasan@example.com',
            Username = 'sean.hasan.' + DateTime.now().getTime() + '@example.com',
            Alias = 'sean',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert seanHasan;

        // Create Record Types
        Id sObjTypeId = Schema.SObjectType.ESC_NBC_Prospect__c.getRecordTypeInfosByName().get('Active Prospect').getRecordTypeId();
        Id prospectRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'ESC_NBC_Prospect__c' AND DeveloperName = 'Prospect' LIMIT 1].Id;

        // Create test Prospect record older than 5 days with a different owner
        ESC_NBC_Prospect__c prospect = new ESC_NBC_Prospect__c(
            Name = 'Test Prospect',
            RecordTypeId = sObjTypeId,
            ESC_NBC_Prospect_Status__c = 'New',
            OwnerId = UserInfo.getUserId() // Make sure it's not Sean Hasan
        );
        insert prospect;
    }

    @isTest
    static void testBatchExecution() {
        // Run batch
        Test.startTest();
        Database.executeBatch(new ESC_NBC_InactiveProspectBatch(), 200);
        Test.stopTest();
    }
    
    @isTest
    static void testBatchExecution2() {
        // Run batch
        Test.startTest();
        ESC_NBC_InactiveProspectBatch exe = new ESC_NBC_InactiveProspectBatch();
        exe.execute(null, [SELECT ID FROM ESC_NBC_Prospect__c]);
        Test.stopTest();
    }
    
    @isTest
    static void testBatchExecution3() {
        // Run batch
        Test.startTest();
        ESC_NBC_LaunchInactiveProspectBatch.runBatch(null);
        Test.stopTest();
    }
}