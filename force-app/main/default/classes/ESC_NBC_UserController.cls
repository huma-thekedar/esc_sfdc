public without sharing class ESC_NBC_UserController {
	@AuraEnabled(cacheable=true)
    public static String getUserProfileName() {
        return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
    }
}