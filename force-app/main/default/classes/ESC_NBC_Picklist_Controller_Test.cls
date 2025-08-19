@isTest
public class ESC_NBC_Picklist_Controller_Test {
    @isTest
    static void testGetPicklistValues() {
        // Define test parameters
        String testObjectName = 'Account'; // Change to a valid object name with picklist fields
        String testFieldName = 'Industry'; // Change to a valid picklist field
        
        // Call the method
        Test.startTest();
        List<Map<String, String>> result = NBC_Picklist_Controller.getPicklistValues(testObjectName, testFieldName);
        Test.stopTest();
        
        // Validate results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Picklist values should not be empty');
        System.assertEquals('None', result[0].get('label'), 'First value should be None');
    }
    @isTest
    static void testGetRecordTypeNames() {
        // Call the method with a standard object that always has record types (like Account)
        Test.startTest();
        List<String> result = NBC_Picklist_Controller.getRecordTypeNames('ESC_NBC_Prospect__C');
        Test.stopTest();

        // Assert the result is not null and contains at least one value
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assert(result.size() > 0, 'There should be at least one record type or "None" option');
    }
                
}