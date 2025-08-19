/**
* @File Name : HCPL_NBC_Picklist_Controller.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : January 29, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | January 29, 2025 |   | Initial Version
**/

public class NBC_Picklist_Controller {
	@AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {
        // Describe the object and the field
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeFieldResult fieldDescribe = sobjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();

        // Get the picklist values
        List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
		Map<String, String> picklistValueNone = new Map<String, String>();
        picklistValueNone.put('label', 'None');
        picklistValueNone.put('value', 'None');
        picklistValues.add(picklistValueNone);
        for(Schema.PicklistEntry entry : picklistEntries) {
            Map<String, String> picklistValue = new Map<String, String>();
            picklistValue.put('label', entry.getLabel());
            picklistValue.put('value', entry.getValue());
            picklistValues.add(picklistValue);
        }

        return picklistValues;
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getRecordTypeNames(String objectName) {
        List<String> recordTypeList = new List<String>();

        // Get the SObjectType
        Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectName);
        if (sobjectType == null) return recordTypeList;

        // Get describe info for the object
        Schema.DescribeSObjectResult describeResult = sobjectType.getDescribe();

        // Add a default 'None' option
        recordTypeList.add('None');

        // Get available record types
        for (Schema.RecordTypeInfo rtInfo : describeResult.getRecordTypeInfos()) {
            if (rtInfo.getName() != 'Master') {
                recordTypeList.add(
                    rtInfo.getName()
                );
            }
        }

        return recordTypeList;
    }

}