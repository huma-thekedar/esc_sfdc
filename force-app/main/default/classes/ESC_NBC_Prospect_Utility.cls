/**
* @File Name : ESC_NBC_Prospect_Utility.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 1, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 1, 2025 |   | Initial Version
**/

public without sharing class ESC_NBC_Prospect_Utility {

	public static void updateProspectStatus(String prospectId, String status){
		Update new ESC_NBC_Prospect__c(
			Id = prospectId,
			ESC_NBC_Prospect_Status__c = status
		);
	}
}