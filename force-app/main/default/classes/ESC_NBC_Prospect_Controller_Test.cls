@isTest
public class ESC_NBC_Prospect_Controller_Test {

    @testSetup
    static void setupTestData() {
        ESC_NBC_Prospect__c prospectObj = new ESC_NBC_Prospect__c(
            Name = 'Candidate Beyrer',
            ESC_NBC_Linkedin_URL__c = 'test/test.com',
            ESC_NBC_Headline__c = 'Professor, Clinical | Director of Clinical Education, SLP | Speech Language Pathologist',
            ESC_NBC_Prospect_Status__c = 'Nurturing',
            ESC_NBC_Address__City__s = 'Garden City',
            ESC_NBC_Address__CountryCode__s = 'US',
            ESC_NBC_Address__Latitude__s = 40.726768,
            ESC_NBC_Address__Longitude__s = -73.634295,
            ESC_NBC_Address__StateCode__s = 'NY',
            RecordTypeId = Schema.SObjectType.ESC_NBC_Prospect__c.getRecordTypeInfosByName().get('Active Prospect').getRecordTypeId()
        );
        insert prospectObj;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRadar());
    }
    
    @isTest
    static void getProspectDetailsTest() {
        ESC_NBC_Prospect__c prospectObj = [SELECT ID FROM ESC_NBC_Prospect__c LIMIT 1];
        ESC_NBC_Prospect_Controller.getContactDetails(prospectObj.Id);
    }
    
    @isTest
    static void updateContactDetails2Test() {
        ESC_NBC_Prospect__c prospectObj = [SELECT ID FROM ESC_NBC_Prospect__c LIMIT 1];
        //prospectObj.ESC_NBC_Active__c = true;
        ESC_NBC_Prospect_Controller.updateContactDetails2(prospectObj);
        //System.assertEquals(prospectObj.ESC_NBC_Active__c ==  true, true);
    }
    
    @isTest
    static void getPicklistValuesTest() {
        Map<String, List<String>> pickMap = ESC_NBC_Prospect_Controller.getPicklistValues();
        System.assertEquals(pickMap != null, true);
    }
    
}