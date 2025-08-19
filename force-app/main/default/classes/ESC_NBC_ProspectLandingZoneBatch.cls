/**
* @File Name : NBC_ESC_ProspectLandingZoneProcessor.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : February 14, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | February 14, 2025 |   | Initial Version
**/
// Database.executeBatch(new ESC_NBC_ProspectLandingZoneBatch());
public class ESC_NBC_ProspectLandingZoneBatch implements Database.batchable<sObject>{
 
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'select firstName__c,lastName__c,headline__c,url__c,Linkedin_About_Me__c  from Prospect_Landing_Zone__c where Processed__c = false';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Prospect_Landing_Zone__c> scope)
    {
        list<string> urls = new list<string>();
        map<string,string> linkedinURLToLeadId = new map<string,string>();
        list<ESC_NBC_Prospect__c>  prospectsToUpsert = new list<ESC_NBC_Prospect__c>();
        for(Prospect_Landing_Zone__c pl : scope)
        {
            urls.add(pl.url__c);
            pl.Processed__c = true;
        }
        for(ESC_NBC_Prospect__c prospectObj : [select id,ESC_NBC_Linkedin_URL__c from ESC_NBC_Prospect__c where ESC_NBC_Linkedin_URL__c in: urls])
        {
            linkedinURLToLeadId.put(prospectObj.ESC_NBC_Linkedin_URL__c, prospectObj.id);
        }
        String prospectRecordTypeId = [select Id, NAME from RECORDTYPE where SobjectType = 'ESC_NBC_Prospect__c' AND DeveloperName = 'Prospect'][0].Id;
        for(Prospect_Landing_Zone__c pl : scope)
        {
            String nameFinal = '';
            if(pl.firstName__c != null && !String.isBlank(pl.firstName__c)) {
                nameFinal = pl.firstName__c;
            }
            if(pl.lastName__c != null && !String.isBlank(pl.lastName__c)) {
                nameFinal += pl.lastName__c;
            }  
            ESC_NBC_Prospect__c prospectObj = new ESC_NBC_Prospect__c(
                Name = nameFinal,
                ESC_NBC_Headline__c = pl.headline__c,
                ESC_NBC_About__c = pl.Linkedin_About_Me__c,
                ESC_NBC_Linkedin_URL__c = pl.url__c,
                ESC_NBC_Company__c = 'Linkedin Scrapped Data',
                RecordTypeId = prospectRecordTypeId
            );
            if(linkedinURLToLeadId.containsKey(pl.url__c))
            {
                prospectObj.id = linkedinURLToLeadId.get(pl.url__c);
            }
             prospectsToUpsert.add(prospectObj);
        }
        upsert  prospectsToUpsert;
        for(ESC_NBC_Prospect__c prospectObj :  prospectsToUpsert)
        {
            linkedinURLToLeadId.put(prospectObj.ESC_NBC_Linkedin_URL__c, prospectObj.id);
        }
        list<Experience__c> exp = [Select id,Prospect_Landing_Zone__r.url__c from Experience__c where Prospect_Landing_Zone__r.url__c =: linkedinURLToLeadId.keyset()];
        list<Education__c> edu = [Select id,Prospect_Landing_Zone__r.url__c from Education__c where Prospect_Landing_Zone__r.url__c =: linkedinURLToLeadId.keyset()];
        list<License_and_Certifications__c> lc = [Select id,Prospect_Landing_Zone__r.url__c from License_and_Certifications__c where Prospect_Landing_Zone__r.url__c =: linkedinURLToLeadId.keyset()];
        list<Organization__c> org = [Select id,Prospect_Landing_Zone__r.url__c from Organization__c where Prospect_Landing_Zone__r.url__c =: linkedinURLToLeadId.keyset()];
        
        for(Experience__c e : exp)
        {
            e.ESC_NBC_Prospect__c = linkedinURLToLeadId.get(e.Prospect_Landing_Zone__r.url__c);
        }
        for(Education__c e : edu)
        {
            e.ESC_NBC_Prospect__c = linkedinURLToLeadId.get(e.Prospect_Landing_Zone__r.url__c);
        }
        for(License_and_Certifications__c l : lc)
        {
            l.ESC_NBC_Prospect__c = linkedinURLToLeadId.get(l.Prospect_Landing_Zone__r.url__c);
        }  
        for(Organization__c o : org)
        {
            o.ESC_NBC_Prospect__c = linkedinURLToLeadId.get(o.Prospect_Landing_Zone__r.url__c);
        }
        update exp;
        update edu;
        update lc;
        update org;
        update scope;
    }

    public void finish(Database.BatchableContext BC) {
    
    }
}