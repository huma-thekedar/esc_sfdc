public class ESC_NBC_JobOpeningController {
	@AuraEnabled(cacheable=true)
    public static List<Job_Opening__c> getActiveJobOpeningsForClient(Id clientId) {
        if (String.isBlank(clientId)) return new List<Job_Opening__c>();

        return [
            SELECT Id, Name
            FROM Job_Opening__c
            WHERE Client__c = :clientId
            AND Status__c = 'Active'
            ORDER BY CreatedDate DESC
        ];
    }
    
    @AuraEnabled(cacheable=true)
	public static Interview__c getInterviewInfo(Id interviewId) {
    	return [
            SELECT Id, Prospect__c, Job_Opening__c, Job_Opening__r.Name, Job_Opening__r.Client__c
            FROM Interview__c
            WHERE Id = :interviewId
            LIMIT 1
        ];
	}
    
    
    @AuraEnabled(cacheable=true)
	public static List<Contact> getContactsForClient(Id clientId) {
    	if (String.isBlank(clientId)) return new List<Contact>();

    	return [
            SELECT Id, Name, Email
            FROM Contact
            WHERE AccountId = :clientId
        ];
	}
    
    @AuraEnabled(cacheable=true)
    public static Job_Opening__c getJobOpeningInfo(Id jobOpeningId) {
        return [
            SELECT Id, Name, Client__c
            FROM Job_Opening__c
            WHERE Id = :jobOpeningId
            LIMIT 1
        ];
    }
}