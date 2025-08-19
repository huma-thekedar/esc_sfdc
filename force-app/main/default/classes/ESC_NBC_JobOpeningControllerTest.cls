@isTest
public class ESC_NBC_JobOpeningControllerTest {

    @isTest
    static void testControllerMethods() {
       
        Account testClient = new Account(Name = 'Test Client');
        insert testClient;

        Job_Opening__c job = new Job_Opening__c(
            Name = 'Test Job',
            Client__c = testClient.Id,
            Status__c = 'Active',
            Min_Rate__c = 100,
            Max_Rate__c = 150,
            Rate_Type__c = 'Hourly',
            Job_Expiry_Date__c = Date.today().addDays(30),
            Number_of_Hours__c = 40
        );
        insert job;




        
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            AccountId = testClient.Id
        );
        insert con;
		
        // Get Record Type Id for Active Prospect
			Id activeProspectRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'ESC_NBC_Prospect__c' AND Name = 'Active Prospect' LIMIT 1].Id;

        // Insert prospect with correct record type
               
        ESC_NBC_Prospect__c prospect = new ESC_NBC_Prospect__c(
            Name = 'Test Prospect',
            RecordTypeId = activeProspectRtId,
            ESC_NBC_Prospect_Status__c = 'Active_Prospect'
        );
        insert prospect;
        
        Interview__c interview = new Interview__c(
            Job_Opening__c = job.Id,
            Interview_Date__c = System.now().addDays(2),
            Prospect__c = prospect.Id,
            Status__c = 'Scheduled'
        );
        insert interview;


        Test.startTest();

        // Test getActiveJobOpeningsForClient
        List<Job_Opening__c> activeJobs = ESC_NBC_JobOpeningController.getActiveJobOpeningsForClient(testClient.Id);
        System.assert(!activeJobs.isEmpty());

        // Test getContactsForClient
        List<Contact> contacts = ESC_NBC_JobOpeningController.getContactsForClient(testClient.Id);
        System.assertEquals(1, contacts.size());

        // Test getInterviewInfo
        Interview__c fetchedInterview = ESC_NBC_JobOpeningController.getInterviewInfo(interview.Id);
        System.assertEquals(interview.Id, fetchedInterview.Id);

        // Test getJobOpeningInfo
        Job_Opening__c fetchedJob = ESC_NBC_JobOpeningController.getJobOpeningInfo(job.Id);
        System.assertEquals(job.Id, fetchedJob.Id);

        Test.stopTest();
    }
}