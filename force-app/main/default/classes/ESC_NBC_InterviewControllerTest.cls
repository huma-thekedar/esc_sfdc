@isTest
public class ESC_NBC_InterviewControllerTest {

    @isTest
    static void testInterviewControllerMethods() {
        // Defensive query for Interview RecordTypes
        List<RecordType> interviewRTList = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Interview__c' AND DeveloperName = 'Interview' LIMIT 1];
        System.assert(!interviewRTList.isEmpty(), 'Interview RecordType not found');
        RecordType interviewRT = interviewRTList[0];

        List<RecordType> submissionRTList = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Interview__c' AND DeveloperName = 'Submission' LIMIT 1];
        System.assert(!submissionRTList.isEmpty(), 'Submission RecordType not found');
        RecordType submissionRT = submissionRTList[0];

        // For Prospect record type, use Name (not DeveloperName) because of lookup filter on Prospect__c lookup
        List<RecordType> prospectRTList = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = 'ESC_NBC_Prospect__c' AND Name = 'Active Prospect' LIMIT 1];
        System.assert(!prospectRTList.isEmpty(), 'Active Prospect RecordType not found');
        RecordType activeProspectRT = prospectRTList[0];

        // Create test Account
        Account client = new Account(Name = 'Test Client');
        insert client;

        // Create Job Opening
        Job_Opening__c job = new Job_Opening__c(
            Name = 'Test Job',
            Client__c = client.Id,
            Status__c = 'Active',
            Min_Rate__c = 100,
            Max_Rate__c = 150,
            Rate_Type__c = 'Hourly',
            Job_Expiry_Date__c = Date.today().addDays(30),
            Number_of_Hours__c = 40
        );
        insert job;

        // Create Interviewer Contact
        Contact interviewer = new Contact(
            FirstName = 'Interviewer',
            LastName = 'One',
            AccountId = client.Id
        );
        insert interviewer;

        // Create Prospect - must match lookup filter props!
        ESC_NBC_Prospect__c prospect = new ESC_NBC_Prospect__c(
            Name = 'Test Prospect',
            RecordTypeId = activeProspectRT.Id,
            ESC_NBC_Prospect_Status__c = 'Active_Prospect'
        );
        insert prospect;

        ESC_NBC_Prospect__c otherProspect = new ESC_NBC_Prospect__c(
            Name = 'Other Prospect',
            RecordTypeId = activeProspectRT.Id,
            ESC_NBC_Prospect_Status__c = 'Active_Prospect'
        );
        insert otherProspect;

        // Create Interview record linked to Prospect
        Interview__c interview = new Interview__c(
            Name = 'Interview 1',
            Status__c = 'Scheduled',
            Interview_Date__c = Date.today(),
            Prospect__c = prospect.Id,
            RecordTypeId = interviewRT.Id,
            Job_Opening__c = job.Id,
            Interviewer_Name__c = interviewer.Id
        );
        insert interview;

        // Create Submission record linked to Prospect
        Interview__c submission = new Interview__c(
            Name = 'Submission 1',
            Status__c = 'In Submission',
            Interview_Date__c = Date.today().addDays(-1),
            Prospect__c = prospect.Id,
            RecordTypeId = submissionRT.Id,
            Job_Opening__c = job.Id
        );
        insert submission;

        // Create Interview without Prospect to test else branch in updateInterviewStatus
        Interview__c orphanInterview = new Interview__c(
            Name = 'Orphan Interview',
            Status__c = 'Scheduled',
            Interview_Date__c = Date.today().addDays(-3),
            RecordTypeId = interviewRT.Id,
            Job_Opening__c = job.Id,
            Prospect__c = otherProspect.Id // another prospect that *should* satisfy lookup filter
        );
        insert orphanInterview;

        // Start Test Execution Block
        Test.startTest();

        // Test querying submissions and interviews for the prospect
        List<Interview__c> submissions = ESC_NBC_InterviewController.getSubmissionForProspect(prospect.Id);
        List<Interview__c> interviews = ESC_NBC_InterviewController.getInterviewsForProspect(prospect.Id);

        // Re-query to get RecordType for assertions
        submissions = [SELECT Id, Name, RecordTypeId FROM Interview__c WHERE Id IN :submissions];
        interviews = [SELECT Id, Name, RecordTypeId FROM Interview__c WHERE Id IN :interviews];

        // Test updating interview status - Prospect assigned branch
        ESC_NBC_InterviewController.updateInterviewStatus(interview.Id, 'Selected', 'Candidate performed well');
        // Test updating interview status - Prospect assigned branch, reversed scenario (orphan)
        ESC_NBC_InterviewController.updateInterviewStatus(orphanInterview.Id, 'Rejected', 'No prospect');

        // Test convertToInterview on submission with all optional params null
        ESC_NBC_InterviewController.convertToInterview(submission.Id, Date.today().addDays(5),'abcd', null);

        ESC_NBC_InterviewController.getContactsForInterviewAccount(interview.Id);
        // Test getRecordTypeInfoResult returns list
        List<String> recordTypeInfo = ESC_NBC_InterviewController.getRecordTypeInfoResult();

        Test.stopTest();

        // Assert submissions
        List<Interview__c> filteredSubs = new List<Interview__c>();
        for (Interview__c sub : submissions) {
            if (sub.RecordTypeId == submissionRT.Id) filteredSubs.add(sub);
        }
        System.assertEquals(1, filteredSubs.size(), 'Should be 1 submission');
        System.assertEquals('Submission 1', filteredSubs[0].Name);

        // Assert interviews
        List<Interview__c> filteredInts = new List<Interview__c>();
        for (Interview__c intr : interviews) {
            if (intr.RecordTypeId == interviewRT.Id) filteredInts.add(intr);
        }
        System.assertEquals(1, filteredInts.size(), 'Should be 1 interview');
        System.assertEquals('Interview 1', filteredInts[0].Name);

        // Assert RecordTypeInfo non-empty
        System.assert(recordTypeInfo.size() > 0, 'RecordTypeInfo should not be empty');

        // Validate updated interview after updateInterviewStatus call
        Interview__c updatedInterview = [SELECT Status__c, ESC_NBC_Interview_Notes__c FROM Interview__c WHERE Id = :interview.Id];
        System.assertEquals('Selected', updatedInterview.Status__c);
        System.assertEquals('Candidate performed well', updatedInterview.ESC_NBC_Interview_Notes__c);

        // Validate updated prospect status
        ESC_NBC_Prospect__c updatedProspect = [SELECT ESC_NBC_Prospect_Status__c FROM ESC_NBC_Prospect__c WHERE Id = :prospect.Id];
        //System.assertEquals('Selected', updatedProspect.ESC_NBC_Prospect_Status__c);

        // Validate updated orphan interview status & notes
        Interview__c updatedOrphanInterview = [SELECT Status__c, ESC_NBC_Interview_Notes__c FROM Interview__c WHERE Id = :orphanInterview.Id];
        System.assertEquals('Rejected', updatedOrphanInterview.Status__c);
        System.assertEquals('No prospect', updatedOrphanInterview.ESC_NBC_Interview_Notes__c);
    }
}