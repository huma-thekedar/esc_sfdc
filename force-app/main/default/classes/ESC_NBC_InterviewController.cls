public class ESC_NBC_InterviewController {
	@AuraEnabled
    public static List<Interview__c> getSubmissionForProspect(Id prospectId) {
        return [SELECT Id, Name, Status__c, Interview_Date__c,ESC_NBC_Client_Name__c,Job_Opening__r.Id,Job_Opening__r.Position__c, 
                Job_Opening__r.Client__c, Job_Opening__r.Client__r.Name 
                FROM Interview__c WHERE Prospect__c = :prospectId AND RecordType.DeveloperName = 'Submission'
            ORDER BY Interview_Date__c DESC
        ];
    }
    
    @AuraEnabled
    public static List<Interview__c> getInterviewsForProspect(Id prospectId) {
        return [
            SELECT Id, Name, Status__c, Interview_Date__c,Interviewer_Name__c,Interviewer_Name__r.Name,ESC_NBC_Client_Name__c,Job_Opening__r.Id, 
            Job_Opening__r.Position__c,Job_Opening__r.Client__c, Job_Opening__r.Client__r.Name FROM Interview__c
            WHERE Prospect__c = :prospectId
            AND RecordType.DeveloperName = 'Interview'
            ORDER BY Interview_Date__c DESC
        ];
    }
    
    
    @AuraEnabled
    public static void updateInterviewStatus(Id interviewId, String status, String notes) {
        Interview__c interview = [
            SELECT Id, Status__c, Prospect__c, ESC_NBC_Interview_Notes__c,Interviewer_Name__r.Name
            FROM Interview__c
            WHERE Id = :interviewId
            LIMIT 1
        ];
    
        if (interview != null) {
            interview.Status__c = status;
            interview.ESC_NBC_Interview_Notes__c = notes;
    
            if (interview.Prospect__c != null) {
                // ESC_NBC_Prospect__c prospect = [
                //     SELECT Id, ESC_NBC_Prospect_Status__c
                //     FROM ESC_NBC_Prospect__c
                //     WHERE Id = :interview.Prospect__c
                //     LIMIT 1
                // ];
                // prospect.ESC_NBC_Prospect_Status__c = status;
                // update new List<SObject>{ interview, prospect };
                update new List<SObject>{ interview };
                ESC_NBC_Prospect_Utility.updateProspectStatus(interview.Prospect__c, status);
            } else {
                update interview;
            }
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getRecordTypeInfoResult(){
        Schema.DescribeSObjectResult describeResult = Schema.SObjectType.Interview__c;
        Map<id,Schema.RecordTypeInfo> recordTypeMap= describeResult.getRecordTypeInfosById();
        List<String> recordTypeList = new List<String>();
        for(Schema.RecordTypeInfo info : recordTypeMap.values()){
            if(info.getDeveloperName() != 'Master'){
            recordTypeList.add(info.getRecordTypeId() + '-' + info.getName());
            }
        }
        return recordTypeList;
    }
    
        
    @AuraEnabled
    public static void convertToInterview(Id interviewId, Date interviewDate,String zoomMeetingLink,Id interviewerContactId) {
        Interview__c interview = [
            SELECT Id, Interview_Date__c, Status__c, RecordTypeId ,Zoom_Interview_Link__c,Interviewer_Name__c
            FROM Interview__c 
            WHERE Id = :interviewId 
            LIMIT 1
        ];
    
        
        interview.Interview_Date__c = interviewDate;
    
        
        interview.Status__c = 'Scheduled';
    
       
        interview.RecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Interview__c' 
              AND DeveloperName = 'Interview' 
            LIMIT 1
        ].Id;
    
        if (zoomMeetingLink != null) {
            interview.Zoom_Interview_Link__c = zoomMeetingLink;
        }
        if(interviewerContactId != null) {
            interview.Interviewer_Name__c = interviewerContactId;
        }
        update interview;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsForInterviewAccount(Id interviewId) {
        // Query Account Id from the Interview > Job Opening > Client
        Interview__c interviewWithAccount = [
            SELECT Job_Opening__r.Client__c
            FROM Interview__c
            WHERE Id = :interviewId
            LIMIT 1
        ];
    
        if (interviewWithAccount?.Job_Opening__r?.Client__c == null) {
            return new List<Contact>();
        }
    
        // Query Contacts related to that Client Account
        List<Contact> relatedContacts = [
            SELECT Id, Name 
            FROM Contact 
            WHERE AccountId = :interviewWithAccount.Job_Opening__r.Client__c
            ORDER BY Name
            LIMIT 50
        ];
    
        return relatedContacts;
    }


}