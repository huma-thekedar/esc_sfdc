@isTest
public class ContactControllerTest {

    @testSetup
    static void testGetContactDetails() {        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Phone = '123-456-7890',
            Email = 'test@example.com'
        );
        insert testContact;
        
    }
	@isTest
    static void testLogUsers() {
        Test.startTest();
        // Call method to test
        Contact result = ContactController.getContactDetails([select id from contact limit 1].id);
        Test.stopTest();
    }
    
    @isTest
    static void updateContactDetailsTest() {
        Contact contactObj = [SELECT ID, Email, Phone FROM Contact LIMIT 1];
        ContactController.updateContactDetails(contactObj.Id, '1322456', 'test@gmail.com');
        contactObj = [SELECT ID, Email, Phone FROM Contact LIMIT 1];
		System.assertEquals(ContactObj.Email, 'test@gmail.com'); 
        System.assertEquals(ContactObj.Phone, '1322456'); 
    }
    
    @isTest
    static void updateContactPicklistValues() {
        Map<String, List<String>> picklistValues = ContactController.getPicklistValues();
		System.assertEquals(picklistValues != null, true); 
    }
    
    @isTest
    static void updateContactDetails2Test() {
        Contact contactObj = [SELECT ID, Email, Phone FROM Contact LIMIT 1];
        ContactController.updateContactDetails2(contactObj.Id, '1322456', 'test@gmail.com', null, null);
        contactObj = [SELECT ID, Email, Phone FROM Contact LIMIT 1];
    }
    
    /*@isTest
    static void testLogUsers() {
        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Phone = '123-456-7890',
            Email = 'test@example.com'
        );
        insert testContact;
        
        Test.startTest();        
        ContactController.logUsers(testContact.Id);
        Test.stopTest();
        
        Test.startTest();
        
        List<Logs__b> logs = [SELECT Id, Viewed_By__c, Viewed_Contact__c, Viewed_At__c, What_Viewed__c 
                              FROM Logs__b                             
                              LIMIT 1];
        Test.stopTest();
        
        
        System.assertNotEquals(0, logs.size(), 'One log record should be created');
        if (logs.size() > 0) {
            System.assertEquals(UserInfo.getUserId(), logs[0].Viewed_By__c, 'Viewed_By__c should match current user');
            System.assertEquals('Phone and Email', logs[0].What_Viewed__c, 'What_Viewed__c should be "Phone and Email"');
        } else {
            System.debug('No log records found, which may indicate an issue with the logging process.');
        }
    }
 // Verify the contact details
        System.assertEquals(testContact.Id, result.Id, 'Contact Id should match.');
        System.assertEquals(testContact.Phone, result.Phone, 'Phone number should match.');
        System.assertEquals(testContact.Email, result.Email, 'Email should match.');
        System.assertEquals(testContact.Speciality__c, result.Speciality__c, 'Specialty should match.');
        System.assertEquals(testContact.Position__c, result.Position__c, 'Position should match.');*/
}