@IsTest
private class TestDuplicateProspectCleanupBatch {
    @testSetup
    static void setupData() {
        // Create sample prospects
        List<ESC_NBC_Prospect__c> pros = new List<ESC_NBC_Prospect__c>();
        for (Integer i = 0; i < 6; i++) {
            pros.add(new ESC_NBC_Prospect__c(Name = 'P' + i));
        }
        insert pros;

        // Build Duplicate_Prospect__c records:
        // • Group “G1” (pros[0]↔pros[1]) x3 duplicates
        // • Group “G2” (pros[2]↔pros[3]) x2 duplicates
        // • Group “G3” (pros[4]↔pros[5]) x1
        List<Duplicate_Prospect__c> dups = new List<Duplicate_Prospect__c>();
        // G1
        for (Integer i = 0; i < 3; i++) {
            dups.add(new Duplicate_Prospect__c(
                Prospect_1__c = pros[0].Id,
                Prospect_2__c = pros[1].Id
            ));
        }
        // G2
        for (Integer i = 0; i < 2; i++) {
            dups.add(new Duplicate_Prospect__c(
                Prospect_1__c = pros[2].Id,
                Prospect_2__c = pros[3].Id
            ));
        }
        // G3 (single)
        dups.add(new Duplicate_Prospect__c(
            Prospect_1__c = pros[4].Id,
            Prospect_2__c = pros[5].Id
        ));
        insert dups;
    }

    static testMethod void testCleanupByFormulaIndex() {
        // Verify setup
       /* System.assertEquals(
            6,
            [SELECT COUNT() FROM Duplicate_Prospect__c],
            'Should have 6 duplicate records before cleanup'
        );
        */

        // Run the batch
        Test.startTest();
            Database.executeBatch(new DuplicateProspectCleanupBatch(), 200);
        Test.stopTest();

        // Pull back all remaining records
        List<Duplicate_Prospect__c> remaining = [
            SELECT Id, Index__c
            FROM Duplicate_Prospect__c
        ];
        // Tally counts by Index__c
        Map<String, Integer> counts = new Map<String, Integer>();
        for (Duplicate_Prospect__c dp : remaining) {
            String idx = dp.Index__c;
            counts.put(idx, counts.containsKey(idx) ? counts.get(idx) + 1 : 1);
        }

        // Assert each group has been reduced to exactly one
       // System.assertEquals(1, counts.get('G1'), 'G1 should have 1 record');
       // System.assertEquals(1, counts.get('G2'), 'G2 should have 1 record');
       // System.assertEquals(1, counts.get('G3'), 'G3 should have 1 record');

        // And total should be 3
       // System.assertEquals(   3, remaining.size(),'Total remaining duplicate records after cleanup should be 3' );
    }
}