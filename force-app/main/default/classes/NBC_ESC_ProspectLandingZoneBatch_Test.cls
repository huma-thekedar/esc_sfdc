@isTest
public class NBC_ESC_ProspectLandingZoneBatch_Test {
    @testSetup
    static void setupTestData() {
        String uniqueURL = 'https://linkedin.com/test';
        // Create test Prospect Landing Zone records
        Prospect_Landing_Zone__c prospect = new Prospect_Landing_Zone__c(
            firstName__c = 'TestFirst',
            lastName__c = 'TestLast',
            headline__c = 'Test Headline ',
            url__c = uniqueURL,
            Linkedin_About_Me__c = 'Test About Me ',
            Processed__c = false
        );
        insert prospect;
        
         // Insert related child records and link to the Prospect Landing Zone
        Experience__c experience = new Experience__c(
            Sequence__c =1,
            Prospect_Landing_Zone__c = prospect.Id
        );
        Education__c education = new Education__c(
            Name = 'EDU-001',
            Sequence__c = 1,
            Prospect_Landing_Zone__c = prospect.Id
        );
        License_and_Certifications__c licenseCert = new License_and_Certifications__c(
            Name = 'LICAC-001',
            Sequence__c = 1,
            Prospect_Landing_Zone__c = prospect.Id
        );
        Organization__c organization = new Organization__c(
            Name = 'ORG-001',
            Prospect_Landing_Zone__c = prospect.Id
        );
        
        insert experience;
        insert education;
        insert licenseCert;
        insert organization;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        ESC_NBC_ProspectLandingZoneBatch batchJob = new ESC_NBC_ProspectLandingZoneBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();

        // Validate that all records are processed
        List<Prospect_Landing_Zone__c> processedRecords = [SELECT Id, Processed__c FROM Prospect_Landing_Zone__c];
        for (Prospect_Landing_Zone__c record : processedRecords) {
            System.assert(record.Processed__c, 'Processed__c should be true');
        }

        // Validate that new prospects are inserted and existing ones are updated
        List<ESC_NBC_Prospect__c> allProspects = [SELECT Id, Name, ESC_NBC_Linkedin_URL__c FROM ESC_NBC_Prospect__c];
        System.assertEquals(1, allProspects.size(), 'There should be 1 ESC_NBC_Prospect__c records after processing');
    }
}