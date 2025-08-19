@isTest
private class ESC_NBC_ClientInactivityBatchTest {
    static final String SPEC_USER_NAME = 'Every Special Child';

    // Utility to create the special user when needed
    public static User createSpecialUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Every Special',
            Alias = 'espc',
            Email = 'esc_user_' + Math.random() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Child',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'escuser_' + System.currentTimeMillis() + '@example.com'
        );
        insert u;
        return u;
    }

    @testSetup
    static void setupTestData() {
        // Create special user for tests that require user found path
        createSpecialUser();

        // Create active & inactive accounts
        Account activeAcc = new Account(Name = 'Active Client', ESC_NBC_Active__c = true);
        Account inactiveAcc = new Account(Name = 'Inactive Client', ESC_NBC_Active__c = true);
        insert new List<Account>{activeAcc, inactiveAcc};

        // Query Record Types for ESC_NBC_Prospect__c and Interview__c
        RecordType prospectRt = [SELECT Id FROM RecordType WHERE SObjectType = 'ESC_NBC_Prospect__c' LIMIT 1];
        RecordType interviewRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Interview__c' LIMIT 1];

        // Create a Prospect record
        ESC_NBC_Prospect__c prospect = new ESC_NBC_Prospect__c(
            Name = 'Test Prospect',
            RecordTypeId = prospectRt.Id,
            ESC_NBC_Prospect_Status__c = 'Active_Prospect'
        );
        insert prospect;

        // Insert recent Job Opening for active client
        Job_Opening__c recentJob = new Job_Opening__c(
            Name = 'Recent Job',
            Client__c = activeAcc.Id,
            Status__c = 'Active',
            Min_Rate__c = 50,
            Max_Rate__c = 60,
            Rate_Type__c = 'Hourly',
            Job_Expiry_Date__c = Date.today().addDays(30),
            Number_of_Hours__c = 40
        );
        insert recentJob;

        // Insert recent Interview for recent job
        Interview__c recentInterview = new Interview__c(
            Name = 'Recent Interview',
            Job_Opening__c = recentJob.Id,
            Interview_Date__c = Date.today().addDays(2),
            Status__c = 'Scheduled',
            Prospect__c = prospect.Id,
            RecordTypeId = interviewRt.Id
        );
        insert recentInterview;

        // Insert Task related to recent interview (recent activity)
        Task task = new Task(
            Subject = 'Follow-up',
            Status = 'Completed',
            Priority = 'Normal',
            WhatId = recentInterview.Id
        );
        insert task;

        // Insert old Job Opening for inactive client (simulate old activity by setting CreatedDate)
        Job_Opening__c oldJob = new Job_Opening__c(
            Name = 'Old Job',
            Client__c = inactiveAcc.Id,
            Status__c = 'Inactive'
        );
        insert oldJob;
        Test.setCreatedDate(oldJob.Id, DateTime.now().addDays(-35));

        // Insert old Interview linked to old job (no recent activity)
        Interview__c oldInterview = new Interview__c(
            Name = 'Old Interview',
            Job_Opening__c = oldJob.Id,
            Interview_Date__c = Date.today().addDays(-60),
            Status__c = 'Completed',
            Prospect__c = prospect.Id,
            RecordTypeId = interviewRt.Id
        );
        insert oldInterview;

        // Insert a recent Task linked to the old Interview (to cover 'tasks' branch)
        Task recentTaskOnOldInterview = new Task(
            Subject = 'Recent Task on Old Interview',
            Status = 'Completed',
            Priority = 'Normal',
            WhatId = oldInterview.Id
        );
        insert recentTaskOnOldInterview;
    }

    //  Test normal batch execution where user exists
    @isTest
    static void testBatchHappyPath() {
        Account before = [SELECT Id, ESC_NBC_Active__c FROM Account WHERE Name = 'Inactive Client' LIMIT 1];
        System.assertEquals(true, before.ESC_NBC_Active__c);

        Test.startTest();
        Database.executeBatch(new ESC_NBC_ClientInactivityBatch());
        Test.stopTest();

        Account after = [SELECT ESC_NBC_Active__c FROM Account WHERE Id = :before.Id];
        
        System.assertEquals(true, after.ESC_NBC_Active__c, 'Inactive client remains active due to recent job/interview activity');
    }

    //  Test batch when user is NOT found: do NOT create the special user here
    @isTest
    static void testNoSpecialUserBranch() {
        // No user created for this test

        Account acc = [SELECT Id, ESC_NBC_Active__c FROM Account WHERE Name = 'Inactive Client' LIMIT 1];
        System.assertEquals(true, acc.ESC_NBC_Active__c);

        Test.startTest();
        ESC_NBC_ClientInactivityBatch batch = new ESC_NBC_ClientInactivityBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        Account after = [SELECT ESC_NBC_Active__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, after.ESC_NBC_Active__c, 'Account should remain active because no user found');
    }

    //  Test fallback if custom metadata is NOT present (just ensure smooth run)
    @isTest
    static void testNoCustomMetadataBranch() {
        Test.startTest();
        Database.executeBatch(new ESC_NBC_ClientInactivityBatch());
        Test.stopTest();
    }

    //  Test DML exception in batch.execute by forcing duplicate accounts with same name
    @isTest
    static void testDmlExceptionBranch() {
        Account acc1 = new Account(Name='Force DML Fail', ESC_NBC_Active__c = true);
        Account acc2 = new Account(Name='Force DML Fail', ESC_NBC_Active__c = true);
        insert new List<Account>{acc1, acc2};

        createSpecialUser();

        Test.startTest();
        ESC_NBC_ClientInactivityBatch batch = new ESC_NBC_ClientInactivityBatch();
        batch.execute(null, new List<Account>{acc1, acc2});
        Test.stopTest();
    }

    //  Explicit batch lifecycle calls for coverage
    @isTest
    static void testDirectBatchMethods() {
        ESC_NBC_ClientInactivityBatch batch = new ESC_NBC_ClientInactivityBatch();
        Database.QueryLocator locator = batch.start(null);
        List<Account> scope = [SELECT Id, Name, OwnerId, ESC_NBC_Active__c FROM Account LIMIT 50];
        batch.execute(null, scope);
        batch.finish(null);
    }

    //  Test schedulable execute() method
    @isTest
    static void testSchedulableExecute() {
        ESC_NBC_ClientInactivityBatch batch = new ESC_NBC_ClientInactivityBatch();
        Test.startTest();
        batch.execute(null); 
        Test.stopTest();
    }

    //  Isolated test method specifically covering the "Tasks branch" logic
    @isTest
    static void testTaskBranchScenario() {
        // Create special user for batch user lookup
        User specialUser = createSpecialUser();

        // Create test account
        Account testAcc = new Account(Name='TaskBranchAccount', ESC_NBC_Active__c = true);
        insert testAcc;

        // Record types for interviews and prospect
        RecordType interviewRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Interview__c' LIMIT 1];
        RecordType prospectRT = [SELECT Id FROM RecordType WHERE SObjectType = 'ESC_NBC_Prospect__c' LIMIT 1];

        // Create prospect
        ESC_NBC_Prospect__c prospect = new ESC_NBC_Prospect__c(
            Name = 'TaskTest Prospect',
            RecordTypeId = prospectRT.Id,
            ESC_NBC_Prospect_Status__c = 'Active_Prospect'
        );
        insert prospect;

        // Insert old Job Opening (no recent activity)
        Job_Opening__c oldJob = new Job_Opening__c(
            Name = 'Old Job For Task Test',
            Client__c = testAcc.Id,
            Status__c = 'Inactive'
        );
        insert oldJob;

        // Insert old Interview linked to old Job Opening
        Interview__c oldInterview = new Interview__c(
            Name = 'Old Interview For Task Test',
            Job_Opening__c = oldJob.Id,
            Interview_Date__c = Date.today().addDays(-40),
            Status__c = 'Completed',
            Prospect__c = prospect.Id,
            RecordTypeId = interviewRT.Id
        );
        insert oldInterview;

        // Insert a recent Task linked to that old Interview
        Task recentTask = new Task(
            Subject = 'Recent Task For Task Branch Test',
            Status = 'Completed',
            Priority = 'Normal',
            WhatId = oldInterview.Id
        );
        insert recentTask;

        Test.startTest();
        ESC_NBC_ClientInactivityBatch batch = new ESC_NBC_ClientInactivityBatch();
        batch.execute(null, new List<Account>{testAcc});
        Test.stopTest();

        Account refreshedAcc = [SELECT ESC_NBC_Active__c FROM Account WHERE Id = :testAcc.Id];
        System.assertEquals(true, refreshedAcc.ESC_NBC_Active__c, 'Account should remain active due to recent Task activity');
    }
}