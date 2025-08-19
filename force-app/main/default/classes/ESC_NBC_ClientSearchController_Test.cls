@isTest
public class ESC_NBC_ClientSearchController_Test {
    @isTest
    static void testCallout() {
        test.startTest();
        Account clientObj = new Account(
        	Name = 'Candidate Beyrer',
            BillingCity = 'Garden City',
            BillingCountry = 'US',
            BillingLatitude = 40.726768,
            BillingLongitude = -73.634295,
            BillingState = 'NY'
        );
        insert clientObj;
        test.stopTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRadar());
        ESC_NBC_ClientSearchController.getSearchLocation('Garden City,NY,United States',10);              
    }
    
    @isTest
    static void getProspectAddressTest() {
        test.startTest();
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
        test.stopTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRadar());
        ESC_NBC_ClientSearchController.getRecordAddress(prospectObj.Id); 
    }
}