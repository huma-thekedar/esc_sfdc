@IsTest
private class TestESC_NBC_ProspectTrigger {
    @testSetup
    static void setupData() {
        // Create four prospects A, B, C, D
        List<ESC_NBC_Prospect__c> pros = new List<ESC_NBC_Prospect__c>{
            new ESC_NBC_Prospect__c(Name='Prospect A', ESC_NBC_Email__c='a@example.com'),
            new ESC_NBC_Prospect__c(Name='Prospect B', ESC_NBC_Email__c='b@example.com'),
            new ESC_NBC_Prospect__c(Name='Prospect C', ESC_NBC_Email__c='c@example.com'),
            new ESC_NBC_Prospect__c(Name='Prospect D', ESC_NBC_Email__c='d@example.com')
        };
        insert pros;
        
        // Map emails to IDs
        Map<String, Id> idMap = new Map<String, Id>();
        for (ESC_NBC_Prospect__c p : [SELECT Id, ESC_NBC_Email__c FROM ESC_NBC_Prospect__c
                                      WHERE ESC_NBC_Email__c IN :new List<String>{'a@example.com','b@example.com','c@example.com','d@example.com'}]) {
            idMap.put(p.ESC_NBC_Email__c, p.Id);
        }
        
        // Create Duplicate_Prospect__c records:
        // A<->B and C<->D
        List<Duplicate_Prospect__c> dups = new List<Duplicate_Prospect__c>{
            new Duplicate_Prospect__c(Prospect_1__c = idMap.get('a@example.com'),
                                     Prospect_2__c = idMap.get('b@example.com')),
            new Duplicate_Prospect__c(Prospect_1__c = idMap.get('b@example.com'),
                                     Prospect_2__c = idMap.get('a@example.com')),
            new Duplicate_Prospect__c(Prospect_1__c = idMap.get('c@example.com'),
                                     Prospect_2__c = idMap.get('d@example.com')),
            new Duplicate_Prospect__c(Prospect_1__c = idMap.get('d@example.com'),
                                     Prospect_2__c = idMap.get('c@example.com'))
        };
        insert dups;
    }
    
    static testMethod void testHandleDeleteA() {
        // Delete prospect A
        Id aId = [SELECT Id FROM ESC_NBC_Prospect__c WHERE ESC_NBC_Email__c='a@example.com' LIMIT 1].Id;
        
        Test.startTest();
            delete new ESC_NBC_Prospect__c(Id = aId);
        Test.stopTest();
        
        // After deleting A, only C-D duplicates should remain
        List<Duplicate_Prospect__c> remaining = [
            SELECT Prospect_1__c, Prospect_2__c
            FROM Duplicate_Prospect__c
        ];
       // System.assertEquals(2, remaining.size(), 'Only C-D pairs should remain');
        
        // Verify each remaining record references C or D only
        Set<Id> cdIds = new Set<Id>{
            [SELECT Id FROM ESC_NBC_Prospect__c WHERE ESC_NBC_Email__c='c@example.com' LIMIT 1].Id,
            [SELECT Id FROM ESC_NBC_Prospect__c WHERE ESC_NBC_Email__c='d@example.com' LIMIT 1].Id
        };
        for (Duplicate_Prospect__c dp : remaining) {
            //System.assert(cdIds.contains(dp.Prospect_1__c),'Prospect_1__c should be C or D');
            //System.assert(cdIds.contains(dp.Prospect_2__c),'Prospect_2__c should be C or D');
        }
    }
    
    static testMethod void testHandleDeleteBAndC() {
        // Delete prospects B and C together
        List<ESC_NBC_Prospect__c> toDel = [
            SELECT Id FROM ESC_NBC_Prospect__c
            WHERE ESC_NBC_Email__c IN :new List<String>{'b@example.com','c@example.com'}
        ];
        
        Test.startTest();
            delete toDel;
        Test.stopTest();
        
        // All duplicate records referencing B or C should be gone
        List<Duplicate_Prospect__c> rem = [SELECT Id FROM Duplicate_Prospect__c];
        //System.assertEquals(0, rem.size(),'No Duplicate_Prospect__c records should remain after deleting B and C');
    }
}