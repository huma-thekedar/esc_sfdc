/**
* @File Name : processCandidateLandingData.cls
* @Description : Batch to process prospect landing records into leads  
* @Author : Digvijay
* @Last Modified By :
* @Last Modified On : October 16, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 16, 2024 |   | Initial Version
**/
public class processCandidateLandingData implements Database.batchable<sObject>{ 
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'select firstName__c,lastName__c,headline__c,url__c,Linkedin_About_Me__c  from Prospect_Landing_Zone__c where Processed__c = false';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Prospect_Landing_Zone__c> scope)
    {
        list<string> urls = new list<string>();
        map<string,string> urlLeads = new map<string,string>();
        list<lead> leadsToInsert = new list<lead>();
        for(Prospect_Landing_Zone__c pl : scope)
        {
            urls.add(pl.url__c);
            pl.Processed__c = true;
        }
        for(lead l : [select id,Linkedin_URL__c from lead where Linkedin_URL__c in: urls])
        {
            urlLeads.put(l.Linkedin_URL__c, l.id);
        }
        for(Prospect_Landing_Zone__c pl : scope)
        {
            Lead l = new Lead();
            l.FirstName = pl.firstName__c;
            l.LastName = pl.lastName__c;
            l.headline__c = pl.headline__c;
            l.About__c = pl.Linkedin_About_Me__c;
            l.Linkedin_URL__c = pl.url__c;
            l.company = 'Linkedin Scrapped Data';
            if(urlLeads.containsKey(pl.url__c))
            {
                l.id = urlLeads.get(pl.url__c);
            }
            leadsToInsert.add(l);
        }
        upsert leadsToInsert;
        for(lead l : leadsToInsert)
        {
            urlLeads.put(l.Linkedin_URL__c, l.id);
        }
        list<Experience__c> exp = [Select id,Prospect_Landing_Zone__r.url__c from Experience__c where Prospect_Landing_Zone__r.url__c =: urlLeads.keyset()];
        list<Education__c> edu = [Select id,Prospect_Landing_Zone__r.url__c from Education__c where Prospect_Landing_Zone__r.url__c =: urlLeads.keyset()];
        list<License_and_Certifications__c> lc = [Select id,Prospect_Landing_Zone__r.url__c from License_and_Certifications__c where Prospect_Landing_Zone__r.url__c =: urlLeads.keyset()];
        list<Organization__c> org = [Select id,Prospect_Landing_Zone__r.url__c from Organization__c where Prospect_Landing_Zone__r.url__c =: urlLeads.keyset()];
        
        for(Experience__c e : exp)
        {
            e.Lead__c = urlLeads.get(e.Prospect_Landing_Zone__r.url__c);
        }
        for(Education__c e : edu)
        {
            e.Lead__c = urlLeads.get(e.Prospect_Landing_Zone__r.url__c);
        }
        for(License_and_Certifications__c l : lc)
        {
            l.Lead__c = urlLeads.get(l.Prospect_Landing_Zone__r.url__c);
        }  
        for(Organization__c o : org)
        {
            o.Prospect__c = urlLeads.get(o.Prospect_Landing_Zone__r.url__c);
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