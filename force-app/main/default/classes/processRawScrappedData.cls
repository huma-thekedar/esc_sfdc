/**
* @File Name : processRawScrappedData.cls
* @Description : Batch to process raw data scrapped across web 
* @Author : Digvijay
* @Last Modified By :
* @Last Modified On : October 16, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 16, 2024 |   | Initial Version
**/
public class processRawScrappedData implements Database.batchable<sObject>{ 

    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'select id,ABOUT_0_text__c, LANGUAGES_0_title__c, LANGUAGES_1_title__c, firstName__c, headline__c, lastName__c, url__c, EDUCATION_0_caption__c, EDUCATION_0_child_0_text__c, EDUCATION_0_subtitle__c, EDUCATION_0_title__c, EDUCATION_1_caption__c, EDUCATION_1_child_0_text__c, EDUCATION_1_subtitle__c, EDUCATION_1_title__c, EXPERIENCE_0_caption__c, EXPERIENCE_0_child_0_caption__c, EXPERIENCE_0_child_0_child_0_text__c, EXPERIENCE_0_child_0_meta__c, EXPERIENCE_0_child_0_subtitle__c, EXPERIENCE_0_child_0_text__c, EXPERIENCE_0_child_0_title__c, EXPERIENCE_0_child_1_caption__c, EXPERIENCE_0_child_1_child_0_text__c, EXPERIENCE_0_child_1_meta__c, EXPERIENCE_0_child_1_subtitle__c, EXPERIENCE_0_child_1_title__c, EXPERIENCE_0_child_2_caption__c, EXPERIENCE_0_child_2_child_0_text__c, EXPERIENCE_0_child_2_meta__c, EXPERIENCE_0_child_2_subtitle__c, EXPERIENCE_0_child_2_title__c, EXPERIENCE_0_meta__c, EXPERIENCE_0_subtitle__c, EXPERIENCE_0_title__c, EXPERIENCE_1_caption__c, EXPERIENCE_1_child_0_caption__c, EXPERIENCE_1_child_0_child_0_text__c, EXPERIENCE_1_child_0_meta__c, EXPERIENCE_1_child_0_subtitle__c, EXPERIENCE_1_child_0_text__c, EXPERIENCE_1_child_0_title__c, EXPERIENCE_1_child_1_caption__c, EXPERIENCE_1_child_1_child_0_text__c, EXPERIENCE_1_child_1_meta__c, EXPERIENCE_1_child_1_subtitle__c, EXPERIENCE_1_child_1_title__c, EXPERIENCE_1_child_2_caption__c, EXPERIENCE_1_child_2_child_0_text__c, EXPERIENCE_1_child_2_meta__c, EXPERIENCE_1_child_2_subtitle__c, EXPERIENCE_1_child_2_title__c, EXPERIENCE_1_meta__c, EXPERIENCE_1_subtitle__c, EXPERIENCE_1_title__c, EXPERIENCE_2_caption__c, EXPERIENCE_2_child_0_caption__c, EXPERIENCE_2_child_0_child_0_text__c, EXPERIENCE_2_child_0_meta__c, EXPERIENCE_2_child_0_subtitle__c, EXPERIENCE_2_child_0_text__c, EXPERIENCE_2_child_0_title__c, EXPERIENCE_2_child_1_caption__c, EXPERIENCE_2_child_1_child_0_text__c, EXPERIENCE_2_child_1_meta__c, EXPERIENCE_2_child_1_subtitle__c, EXPERIENCE_2_child_1_title__c, EXPERIENCE_2_child_2_caption__c, EXPERIENCE_2_child_2_child_0_text__c, EXPERIENCE_2_child_2_meta__c, EXPERIENCE_2_child_2_subtitle__c, EXPERIENCE_2_child_2_title__c, EXPERIENCE_2_meta__c, EXPERIENCE_2_subtitle__c, EXPERIENCE_2_title__c, EXPERIENCE_3_caption__c, EXPERIENCE_3_child_0_caption__c, EXPERIENCE_3_child_0_child_0_text__c, EXPERIENCE_3_child_0_meta__c, EXPERIENCE_3_child_0_subtitle__c, EXPERIENCE_3_child_0_text__c, EXPERIENCE_3_child_0_title__c, EXPERIENCE_3_child_1_caption__c, EXPERIENCE_3_child_1_child_0_text__c, EXPERIENCE_3_child_1_meta__c, EXPERIENCE_3_child_1_subtitle__c, EXPERIENCE_3_child_1_title__c, EXPERIENCE_3_child_2_caption__c, EXPERIENCE_3_child_2_child_0_text__c, EXPERIENCE_3_child_2_meta__c, EXPERIENCE_3_child_2_subtitle__c, EXPERIENCE_3_child_2_title__c, EXPERIENCE_3_meta__c, EXPERIENCE_3_subtitle__c, EXPERIENCE_3_title__c, EXPERIENCE_4_caption__c, EXPERIENCE_4_child_0_caption__c, EXPERIENCE_4_child_0_child_0_text__c, EXPERIENCE_4_child_0_meta__c, EXPERIENCE_4_child_0_subtitle__c, EXPERIENCE_4_child_0_text__c, EXPERIENCE_4_child_0_title__c, EXPERIENCE_4_child_1_caption__c, EXPERIENCE_4_child_1_child_0_text__c, EXPERIENCE_4_child_1_meta__c, EXPERIENCE_4_child_1_subtitle__c, EXPERIENCE_4_child_1_title__c, EXPERIENCE_4_child_2_caption__c, EXPERIENCE_4_child_2_child_0_text__c, EXPERIENCE_4_child_2_meta__c, EXPERIENCE_4_child_2_subtitle__c, EXPERIENCE_4_child_2_title__c, EXPERIENCE_4_meta__c, EXPERIENCE_4_subtitle__c, EXPERIENCE_4_title__c, LICENSES_AND_CERTIFICATIONS_0_caption__c, LICENSES_AND_CERTIFICATIONS_0_meta__c, LICENSES_AND_CERTIFICATIONS_0_subtitle__c, LICENSES_AND_CERTIFICATIONS_0_title__c, LICENSES_AND_CERTIFICATIONS_1_caption__c, LICENSES_AND_CERTIFICATIONS_1_meta__c, LICENSES_AND_CERTIFICATIONS_1_subtitle__c, LICENSES_AND_CERTIFICATIONS_1_title__c, ORGANIZATIONS_0_child_0_text__c, ORGANIZATIONS_0_subtitle__c, ORGANIZATIONS_0_title__c, ORGANIZATIONS_1_child_0_text__c, ORGANIZATIONS_1_subtitle__c, ORGANIZATIONS_1_title__c from Raw_Scraped_Data__c where Processed__c = false';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Raw_Scraped_Data__c> scope)
    {
        processRSDs(scope);
    }
    public void finish(Database.BatchableContext BC) {
    
    }
    public static void processRSDs(list<Raw_Scraped_Data__c> rsds){
        list<Prospect_Landing_Zone__c> prospects = new list<Prospect_Landing_Zone__c>();
        list<scrappedDataUtility.expWrapper> experiences = new list<scrappedDataUtility.expWrapper>();
        list<Education__c> educations = new list<Education__c>();
        list<License_and_Certifications__c> licences = new list<License_and_Certifications__c>();
        list<Organization__c> organizations = new list<Organization__c>();
        for(Raw_Scraped_Data__c rsd : rsds){
            if(rsd.url__c!=null){
                //get prospect record
                prospects.add(scrappedDataUtility.fetchProspect(rsd));                

                // get all experiences related to the prospect
                experiences.addAll(scrappedDataUtility.fetchExpRecs(rsd));

                // get all education records
                educations.addAll( scrappedDataUtility.fetchEduRecs(rsd));

                //get all licence records
                licences.addAll( scrappedDataUtility.fetchlcRecs(rsd));

                //get all organization records
                organizations.addAll( scrappedDataUtility.fetchorgRecs(rsd));
                
            }
            rsd.Processed__c = true;
        }

        //Insert All records
        upsert prospects url__c;
        scrappedDataUtility.insertExperiences(experiences);
        insert educations;
        insert licences;
        insert organizations;
        update rsds;
         
    }
    
}