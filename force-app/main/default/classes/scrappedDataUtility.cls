/**
* @File Name : scrappedDataUtility.cls
* @Description : Utility to process raw data scrapped across web 
* @Author : Digvijay
* @Last Modified By :
* @Last Modified On : October 17, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 17, 2024 |   | Initial Version
**/
public class scrappedDataUtility {
    //Prospect
    Public static Map<String,String> prospectLandingFieldMap = new Map<String, String>{
                                                        'firstName__c' => 'firstName__c', 
                                                        'headline__c' => 'headline__c', 
                                                        'lastName__c' => 'lastName__c', 
                                                        'url__c' => 'url__c', 
                                                        'ABOUT_0_text__c' => 'Linkedin_About_Me__c'};

    public static Prospect_Landing_Zone__c fetchProspect(Raw_Scraped_Data__c rsd){
        Prospect_Landing_Zone__c pl = new Prospect_Landing_Zone__c();
        // for(Prospect_Landing_Zone__c p : [Select id from Prospect_Landing_Zone__c where url__c =:  rsd.url__c]){
        //     pl.id = p.id;
        // }
        for(String key : prospectLandingFieldMap.keyset()){
            if(rsd.get(key)!=null){
                pl.put(prospectLandingFieldMap.get(key),rsd.get(key));
            }
        }
        List<string> langs = new list<string>();
        if(rsd.LANGUAGES_0_title__c != null){
            langs.add(rsd.LANGUAGES_0_title__c);
        }
        if(rsd.LANGUAGES_1_title__c != null){
            langs.add(rsd.LANGUAGES_1_title__c);
        }
        if(langs.size()>0){
            pl.Linkedin_Languages__c = string.join(langs,', ');
        }
        return pl;
    }

    //Experience
    public static Integer maxExpParentRec = 5;
    public static Integer maxExpChildRec = 3;
    Public static Map<String,String> expFieldMap = new Map<String, String>{
                                                        'caption__c' => 'Experience_Caption__c', 
                                                        'child_0_text__c' => 'ExperienceText__c', 
                                                        'meta__c' => 'Experience_Meta__c', 
                                                        'subtitle__c' => 'Experience_Subtitle__c', 
                                                        'title__c' => 'Experience_Title__c'};

    public class expWrapper{
        public Experience__c parentExp;
        public list<Experience__c> childExps;
    }

    public static list<expWrapper> fetchExpRecs(Raw_Scraped_Data__c rsd){
        list<expWrapper> expList = new list<expWrapper>();
        boolean hasExp =false;
        for(Integer i=0 ; i < maxExpParentRec; i++) {
            expWrapper expWr =  new expWrapper();
            Experience__c expParent = convertExp(rsd,i,null);
            if(expParent != null){
                hasExp =true;
                expWr.parentExp = expParent;
                system.debug('parent');
                system.debug(expParent);
                expWr.childExps = new  list<Experience__c>();
                for(Integer j=0 ; j < maxExpChildRec; j++){
                    Experience__c expChild = convertExp(rsd,i,j);
                    if(expChild != null){
                        expWr.childExps.add(expChild);
                        system.debug('child');
                        system.debug(expChild);
                    }                    
                }
                expList.add(expWr);
            }           
        }
        return expList;
    }

    public static Experience__c convertExp(Raw_Scraped_Data__c rsd, Integer parIndex, Integer childIndex){
        Experience__c exp = new Experience__c();
        Prospect_Landing_Zone__c p = new Prospect_Landing_Zone__c();
        p.url__c = rsd.url__c;
        exp.Prospect_Landing_Zone__r = p;
        exp.Sequence__c = parIndex+1;
        Boolean expRecCreate = false;
        String baseVarName = 'EXPERIENCE_'+parIndex+'_';
        if(childIndex != null){
            baseVarName = baseVarName + 'child_' + childIndex + '_' ;
            exp.Sequence__c = exp.Sequence__c + (.01*(childIndex+1));
        }
        for(String key : expFieldMap.keyset()){
            String var = baseVarName + key;
            if(rsd.get(var)!=null){
                expRecCreate = true;
                exp.put(expFieldMap.get(key),rsd.get(var));
            }
        }
        
        if(expRecCreate){
            return exp;
        }
        return null;
    }
    public static void insertExperiences(list<expWrapper> expWrapperList){
        list<Experience__c> parentExp = new list<Experience__c>();
        list<Experience__c> childExp = new list<Experience__c>();
        for(expWrapper expWrapperObj : expWrapperList){
            parentExp.add(expWrapperObj.parentExp);
        }
        insert parentExp;
        for(expWrapper expWrapperObj : expWrapperList){
            for(Experience__c exp : expWrapperObj.childExps){
                exp.Parent_Experience__c = expWrapperObj.parentExp.id;
                childExp.add(exp);
            }
        }
        insert childExp;
        
    }

    //Education
    public static Integer maxEduParentRec = 2;
    Public static Map<String,String> eduFieldMap = new Map<String, String>{
                                                        'caption__c' => 'Caption__c', 
                                                        'child_0_text__c' => 'Title__c', 
                                                        'subtitle__c' => 'Subtitle__c', 
                                                        'title__c' => 'Name'};

    public static list<Education__c> fetchEduRecs(Raw_Scraped_Data__c rsd){
        list<Education__c> eduList = new list<Education__c>();
        boolean hasEdu =false;
        for(Integer i=0 ; i < maxEduParentRec; i++) {
            Education__c eduRec = convertEdu(rsd,i);
            if(eduRec != null){
                hasEdu =true;
                system.debug('eduRec');
                system.debug(eduRec);
                eduList.add(eduRec);
            }           
        }
        return eduList;
    }
    public static Education__c convertEdu(Raw_Scraped_Data__c rsd, Integer parIndex){
        Education__c edu = new Education__c();
        Prospect_Landing_Zone__c p = new Prospect_Landing_Zone__c();
        p.url__c = rsd.url__c;
        edu.Prospect_Landing_Zone__r = p;
        edu.Sequence__c = parIndex+1;
        Boolean eduRecCreate = false;
        String baseVarName = 'EDUCATION_'+parIndex+'_';
        for(String key : eduFieldMap.keyset()){
            String var = baseVarName + key;
            if(rsd.get(var)!=null){
                eduRecCreate = true;
                edu.put(eduFieldMap.get(key),rsd.get(var));
            }
        }        
        if(eduRecCreate){
            return edu;
        }
        return null;
    }

    //Licences And Certifications
    public static Integer maxlcParentRec = 2;
    Public static Map<String,String> lcFieldMap = new Map<String, String>{
                                                        'caption__c' => 'Caption__c', 
                                                        'meta__c' => 'Meta__c', 
                                                        'subtitle__c' => 'Subtitle__c', 
                                                        'title__c' => 'Name'};

    public static list<License_and_Certifications__c> fetchlcRecs(Raw_Scraped_Data__c rsd){
        list<License_and_Certifications__c> lcList = new list<License_and_Certifications__c>();
        boolean haslc =false;
        for(Integer i=0 ; i < maxlcParentRec; i++) {
            License_and_Certifications__c lcRec = convertlc(rsd,i);
            if(lcRec != null){
                haslc =true;
                system.debug('lcRec');
                system.debug(lcRec);
                lcList.add(lcRec);
            }           
        }
        return lcList;
    }
    public static License_and_Certifications__c convertlc(Raw_Scraped_Data__c rsd, Integer parIndex){
        License_and_Certifications__c lc = new License_and_Certifications__c();
        Prospect_Landing_Zone__c p = new Prospect_Landing_Zone__c();
        p.url__c = rsd.url__c;
        lc.Prospect_Landing_Zone__r = p;
        lc.Sequence__c = parIndex+1;
        Boolean lcRecCreate = false;
        String baseVarName = 'LICENSES_AND_CERTIFICATIONS_'+parIndex+'_';
        for(String key : lcFieldMap.keyset()){
            String var = baseVarName + key;
            if(rsd.get(var)!=null){
                lcRecCreate = true;
                lc.put(lcFieldMap.get(key),rsd.get(var));
            }
        }        
        if(lcRecCreate){
            return lc;
        }
        return null;
    }

    //Organization
    public static Integer maxorgParentRec = 2;
    Public static Map<String,String> orgFieldMap = new Map<String, String>{
                                                        'child_0_text__c' => 'Text__c',
                                                        'subtitle__c' => 'Subtitle__c', 
                                                        'title__c' => 'Name'};

    public static list<Organization__c> fetchorgRecs(Raw_Scraped_Data__c rsd){
        list<Organization__c> orgList = new list<Organization__c>();
        boolean hasorg =false;
        for(Integer i=0 ; i < maxorgParentRec; i++) {
            Organization__c orgRec = convertorg(rsd,i);
            if(orgRec != null){
                hasorg =true;
                system.debug('orgRec');
                system.debug(orgRec);
                orgList.add(orgRec);
            }           
        }
        return orgList;
    }
    public static Organization__c convertorg(Raw_Scraped_Data__c rsd, Integer parIndex){
        Organization__c org = new Organization__c();
        //org.Sequence__c = parIndex+1;
        Prospect_Landing_Zone__c p = new Prospect_Landing_Zone__c();
        p.url__c = rsd.url__c;
        org.Prospect_Landing_Zone__r = p;
        Boolean orgRecCreate = false;
        String baseVarName = 'ORGANIZATIONS_'+parIndex+'_';
        for(String key : orgFieldMap.keyset()){
            String var = baseVarName + key;
            if(rsd.get(var)!=null){
                orgRecCreate = true;
                org.put(orgFieldMap.get(key),rsd.get(var));
            }
        }        
        if(orgRecCreate){
            return org;
        }
        return null;
    }
}