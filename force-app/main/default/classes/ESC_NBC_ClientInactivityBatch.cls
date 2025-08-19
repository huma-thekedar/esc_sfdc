global class ESC_NBC_ClientInactivityBatch implements Database.Batchable<SObject>, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Name, OwnerId, ESC_NBC_Active__c FROM Account WHERE ESC_NBC_Active__c = true]);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        if(scope.isEmpty()) return;      
        
        Integer inactivityDays = 30; // default fallback value
        ESC_NBC_Inactivity_Setting__mdt setting = ESC_NBC_Inactivity_Setting__mdt.getInstance('ESC_NBC_Client_Inactive_Day');
		if (setting != null && setting.ESC_NBC_Client_Inactivity_Days__c != null) {
            inactivityDays = Integer.valueOf(setting.ESC_NBC_Client_Inactivity_Days__c);
        }
        
       
        DateTime thresholdDateTime = System.now().addDays(-inactivityDays);

        Set<Id> accountIds = new Set<Id>();
        for(Account acc : scope) {
            accountIds.add(acc.Id);
        }

        //  Find recent Job Openings (modified in last 30 days)
        Map<Id, Id> jobOpeningToClientMap = new Map<Id, Id>();
        Set<Id> jobOpeningsWithRecentActivity = new Set<Id>();
        // All Job Openings for these accounts
        List<Job_Opening__c> jobOpenings = [
            SELECT Id, Client__c, LastModifiedDate FROM Job_Opening__c
            WHERE Client__c IN :accountIds ];
        
        
        for(Job_Opening__c jo : jobOpenings) {
            jobOpeningToClientMap.put(jo.Id, jo.Client__c);
            if(jo.LastModifiedDate >= thresholdDateTime) {
                jobOpeningsWithRecentActivity.add(jo.Id);
            }
        }

        //  Find recent Interviews (linked to Job Openings without recent activity)
        Set<Id> jobOpeningIdsWithoutRecentActivity = new Set<Id>();
        for(Job_Opening__c jo : jobOpenings) {
            if(!jobOpeningsWithRecentActivity.contains(jo.Id)) {
                jobOpeningIdsWithoutRecentActivity.add(jo.Id);
            }
        }

        Set<Id> accountsWithRecentInterviews = new Set<Id>();
        // Interviews with recent activity linked to job openings without recent activity
        List<Interview__c> interviewsWithRecentActivity = [
            SELECT Id, Job_Opening__c, Job_Opening__r.Client__c, LastModifiedDate
            FROM Interview__c
            WHERE Job_Opening__c IN :jobOpeningIdsWithoutRecentActivity
              AND LastModifiedDate >= :thresholdDateTime
        ];

	
        for(Interview__c iv : interviewsWithRecentActivity) {
            if (iv.Job_Opening__r != null && iv.Job_Opening__r.Client__c != null) {
            	accountsWithRecentInterviews.add(iv.Job_Opening__r.Client__c);
            }
        }

        //  Find recent Tasks related to Interviews with no recent activity
        // Build set of Interview Ids that have no recent activity
        Set<Id> interviewIdsWithoutRecentActivity = new Set<Id>();
        // Collect all Interview Ids linked to job openings without recent interviews
        List<Interview__c> allInterviews = [
            SELECT Id, Job_Opening__r.Client__c
            FROM Interview__c
            WHERE Job_Opening__c IN :jobOpeningIdsWithoutRecentActivity
        ];
        for(Interview__c iv : allInterviews) {
            if (iv.Job_Opening__r != null && iv.Job_Opening__r.Client__c != null) {
                if(!accountsWithRecentInterviews.contains(iv.Job_Opening__r.Client__c)) {
                    interviewIdsWithoutRecentActivity.add(iv.Id);
                }
            }
        }

        Set<Id> accountsWithRecentTasks = new Set<Id>();
        if(!interviewIdsWithoutRecentActivity.isEmpty()) {
            // Query Tasks whose WhatId (related record) is in interviewIdsWithoutRecentActivity and modified recently
            List<Task> recentTasks = [
                SELECT Id, WhatId, LastModifiedDate
                FROM Task
                WHERE WhatId IN :interviewIdsWithoutRecentActivity
                AND LastModifiedDate >= :thresholdDateTime
            ];

            // Map tasks back to account (via Interview)
            Map<Id, Id> interviewToAccountMap = new Map<Id, Id>();
            for(Interview__c iv : allInterviews) {
                if (iv.Job_Opening__r != null && iv.Job_Opening__r.Client__c != null) {
                	interviewToAccountMap.put(iv.Id, iv.Job_Opening__r.Client__c);
                }
            }
            
            for(Task t : recentTasks) {
                Id accId = interviewToAccountMap.get(t.WhatId);
                if(accId != null) {
                    accountsWithRecentTasks.add(accId);
                }
            }
        }

        // Find all accounts from scope that have no recent activity in Job Opening, Interview, or Task 
        Set<Id> accountsWithRecentJobs = new Set<Id>();
        for(Job_Opening__c jo : jobOpenings) {
            if(jobOpeningsWithRecentActivity.contains(jo.Id)) {
                accountsWithRecentJobs.add(jo.Client__c);
            }
        }
        
        // Combine all accounts with recent activity
        Set<Id> accountsWithRecentActivity = new Set<Id>();
        accountsWithRecentActivity.addAll(accountsWithRecentJobs);
        accountsWithRecentActivity.addAll(accountsWithRecentInterviews);
        accountsWithRecentActivity.addAll(accountsWithRecentTasks);

        // User lookup: "Every Special Child"
        Id newOwnerId;
        List<User> specUsers = [SELECT Id FROM User WHERE Name = 'Every Special Child' LIMIT 1];
        if(specUsers.isEmpty()) {
            System.debug('User "Every Special Child" not found! Batch will abort.');
            return;
        }
        newOwnerId = specUsers[0].Id;

        List<Account> accountsToUpdate = new List<Account>();
        for(Account acc : scope) {
            Boolean hasRecentActivity = accountsWithRecentActivity.contains(acc.Id);

            if(!hasRecentActivity) {
                // Mark inactive per requirements
                acc.ESC_NBC_Active__c = false;
                acc.OwnerId = newOwnerId;
                accountsToUpdate.add(acc);
            }
        }

        if(!accountsToUpdate.isEmpty()) {
            try {
                update accountsToUpdate;
            } catch(Exception e) {
                System.debug('Error updating accounts: ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ESC_NBC_ClientInactivityBatch());
    }
}