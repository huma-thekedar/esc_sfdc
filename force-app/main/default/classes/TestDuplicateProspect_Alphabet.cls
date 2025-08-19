@IsTest
private class TestDuplicateProspect_Alphabet {
    @testSetup
    static void setupTestData() {
        // Email-prefix ‘A’ duplicates (phones differ)
        ESC_NBC_Prospect__c p1 = new ESC_NBC_Prospect__c(
            Name             = 'Prospect A1',
            ESC_NBC_Email__c = 'abc1@example.com',
            ESC_NBC_Phone__c = '12345'
        );
        ESC_NBC_Prospect__c p2 = new ESC_NBC_Prospect__c(
            Name             = 'Prospect A2',
            ESC_NBC_Email__c = 'abc1@example.com',
            ESC_NBC_Phone__c = '67890'
        );
        // Email‑prefix ‘B’ duplicates (phones identical → Email and Phone)
        ESC_NBC_Prospect__c p3 = new ESC_NBC_Prospect__c(
            Name             = 'Prospect B1',
            ESC_NBC_Email__c = 'bcd1@example.com',
            ESC_NBC_Phone__c = '11111'
        );
        ESC_NBC_Prospect__c p4 = new ESC_NBC_Prospect__c(
            Name             = 'Prospect B2',
            ESC_NBC_Email__c = 'bcd1@example.com',
            ESC_NBC_Phone__c = '11111'
        );
        // Different prefix, should be excluded entirely
        ESC_NBC_Prospect__c p5 = new ESC_NBC_Prospect__c(
            Name             = 'Prospect X',
            ESC_NBC_Email__c = 'xyz@example.com',
            ESC_NBC_Phone__c = '22222'
        );
        // Blank & null email records (should not produce any dupes here)
        ESC_NBC_Prospect__c p6 = new ESC_NBC_Prospect__c(
            Name             = 'Prospect Blank',
            ESC_NBC_Email__c = '',
            ESC_NBC_Phone__c = '33333'
        );
        ESC_NBC_Prospect__c p7 = new ESC_NBC_Prospect__c(
            Name             = 'Prospect Null',
            ESC_NBC_Email__c = null,
            ESC_NBC_Phone__c = '44444'
        );
        insert new List<ESC_NBC_Prospect__c>{ p1, p2, p3, p4, p5, p6, p7 };
    }

    static testMethod void testEmailPrefixChunks() {
        // Run batch for prefixes A and B
        Test.startTest();
            Database.executeBatch(
                new DuplicateProspectBatch_Alphabet_chunk(new List<String>{'A','B'}),
                200
            );
        Test.stopTest();

        // Fetch all generated duplicates
        List<Duplicate_Prospect__c> dups = [
            SELECT Prospect_1__c, Prospect_2__c, Match_Type__c
            FROM Duplicate_Prospect__c
        ];
        // We expect:
        // - 2 records for 'abc1@example.com' with Match_Type = 'Email'
        // - 2 records for 'bcd1@example.com' with Match_Type = 'Email and Phone'
        System.assertEquals(4, dups.size(),
            'Should create 4 total duplicate records for prefixes A and B');

        Integer emailOnlyCount = 0;
        Integer emailAndPhoneCount = 0;
        for (Duplicate_Prospect__c dp : dups) {
            if (dp.Match_Type__c == 'Email') {
                emailOnlyCount++;
            } else if (dp.Match_Type__c == 'Email and Phone') {
                emailAndPhoneCount++;
            } else {
                System.assert(false, 'Unexpected Match_Type: ' + dp.Match_Type__c);
            }
        }
        System.assertEquals(2, emailOnlyCount,
            'Should have exactly 2 Email‑only duplicates for prefix A');
        System.assertEquals(2, emailAndPhoneCount,
            'Should have exactly 2 Email and Phone duplicates for prefix B');
    }

    static testMethod void testNullAndBlankEmailChunk() {
        // Run batch for the '0' chunk (null/blank emails)
        Test.startTest();
            Database.executeBatch(
                new DuplicateProspectBatch_Alphabet_chunk(new List<String>{'0'}),
                200
            );
        Test.stopTest();

        // There are two blank/null email records but no matching pair, so no dups
        Integer count = [
            SELECT COUNT()
            FROM Duplicate_Prospect__c
            WHERE Match_Type__c IN ('Email','Phone')
        ];
        System.assertEquals(0, count,
            'No duplicates expected when only blank/null emails are processed');
    }
}