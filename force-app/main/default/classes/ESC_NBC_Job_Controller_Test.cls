@isTest
public class ESC_NBC_Job_Controller_Test {

    @testSetup
    static void setupTestData() {
        Job_Opening__c jobOpeningObj = new Job_Opening__c(
        	Name = 'Candidate Beyrer',
            Job_Title__c = 'Professor, Clinical | Director of Clinical Education, SLP | Speech Language Pathologist',
            Job_Source__c = 'Indeed;Other',
            Employment_Type__c = 'Full time',
            Address__City__s = 'Garden City',
            Address__CountryCode__s = 'US',
            Address__Latitude__s = 40.726768,
            Address__Longitude__s = -73.634295,
            Address__StateCode__s = 'NY',
            Job_Expiry_Date__c = System.Today()
        );
        insert jobOpeningObj;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRadar());
    }
    
    @isTest
    static void getJobOpeningDetailsTest() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseRadar());
        test.startTest();
        ESC_NBC_Job_Controller.getSearchLocation('Garden City,NY,United States',10);
        test.stopTest();
    }    
}