@isTest
private class ESC_NBC_ProspectBatchTest {

    @testSetup
    static void setupTestData() {
        ESC_NBC_Prospect__c prospectObj = new ESC_NBC_Prospect__c(
        	Name = 'Candidate Beyrer',
            ESC_NBC_Linkedin_URL__c = 'test/test.com',
            ESC_NBC_Headline__c = 'Professor, Clinical | Director of Clinical Education, SLP | Speech Language Pathologist',
            RecordTypeId = Schema.SObjectType.ESC_NBC_Prospect__c.getRecordTypeInfosByName().get('Active Prospect').getRecordTypeId()
        );
        insert prospectObj;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRadar());
    }
    
    @isTest
    static void testProspectGeolocationBatch() {
        // Start test context
        Test.startTest();
        Database.executeBatch(new ESC_NBC_Prospect_Geolocation_Batch(), 1);
        Test.stopTest();

        // Assert that records were created and can be processed
        List<ESC_NBC_Prospect__c> inserted = [
            SELECT Id, ESC_NBC_Address__Latitude__s, ESC_NBC_Address__Longitude__s
            FROM ESC_NBC_Prospect__c           
        ];
		System.debug(inserted);
        System.assertEquals(1, inserted.size(), 'Five test prospects should have been inserted');
    }

}