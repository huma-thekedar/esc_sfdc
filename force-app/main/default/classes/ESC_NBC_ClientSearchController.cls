public with sharing class ESC_NBC_ClientSearchController {

    @AuraEnabled
    public static ESC_NBC_Prospect__c  getRecordAddress(String recordId){
        try {
            return [Select Id, Name, ESC_NBC_Address__CountryCode__s, ESC_NBC_Address__City__s, ESC_NBC_Address__StateCode__s, ESC_NBC_Address__Street__s 
                FROM ESC_NBC_Prospect__c WHERE Id =: recordId
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    Public static String getGeocode(String addressVal){
        try{
            HttpRequest req = new HttpRequest();
            String encodedAddress = EncodingUtil.urlEncode(addressVal, 'UTF-8');
            req.setEndpoint('https://api.radar.io/v1/geocode/forward?query='+encodedAddress);
            //req.setEndpoint('https://api.radar.io/v1/geocode/forward?query='+addressVal); 
            req.setMethod('GET');
            req.setHeader('Authorization', Label.authorizationHeaderRadar);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                System.debug('Response: ' + res.getBody());
                Map<String, Object> m1 = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                for(Object data : (list<Object>)m1.get('addresses')){
                    Map<String,Object> mapObj = (Map<String,Object>)Json.deserializeUntyped(Json.serialize(data));
                    system.debug(mapObj.get('latitude'));
                    system.debug(mapObj.get('longitude'));
                    return String.valueof(mapObj.get('latitude'))+','+String.valueof(mapObj.get('longitude'));
                }
            } else {
                return 'Error';
            }
            return null;
        }
        Catch(Exception e){    
            system.debug(e.getStackTraceString()+'::'+e.getLineNumber()+'::'+e.getMessage()+'::'+e.getCause());        
            return 'Error';
        }
    }
    @AuraEnabled
    Public static String getSearchLocation(String addressVal,Integer miles){
        system.debug('Address Value: ' + addressVal + ' Miles: '+miles);
        String geocode = getGeocode(addressVal);
        if(geocode != null && geocode != 'Error'){
            return getNearbyRecs(geocode,miles);
        }
        return 'Error';
    }
    @AuraEnabled
    Public static String getNearbyRecs(String geocode,Integer miles){
        list<LocationWrapper> locList = new list<LocationWrapper>();
        String[] geoCoordinates = geocode.split(',');
        LocationWrapper lw = new LocationWrapper(
            geoCoordinates[0],
            geoCoordinates[1]
        );
        lw.type= 'Circle';
        lw.radius= (1610*miles);
        lw.strokeColor= '#FFF000';
        lw.strokeOpacity= 0.8;
        lw.strokeWeight= 2;
        lw.fillColor= '#FFF000';
        lw.fillOpacity= 0.35;
        locList.add(lw);
        LocationWrapper lw2 = new LocationWrapper(
            geoCoordinates[0],
            geoCoordinates[1]
        );
        locList.add(lw2);
        String qryStr = '';
        //query prospects
        qryStr = 'select Id,ESC_NBC_Active__c, Name, Type, Industry, BillingCity, BillingCountry, BillingLatitude, ESC_NBC_Sales_Owner_Name__c, Owner.Name, BillingLongitude, BillingPostalCode, BillingState,BillingStreet , BillingAddress from Account  WHERE DISTANCE(BillingAddress , GEOLOCATION(';
        qryStr = qryStr + geocode + '), \'mi\') <  '+ miles;
        qryStr = qryStr + ' order by LastActivityDate desc LIMIT 100';
        System.debug('Query' + qryStr);
        for(Account record : Database.query(qryStr) ){
            
            System.debug('Prospect : ' + record);
            LocationWrapper lwCon = new LocationWrapper(
                String.valueof(record.BillingLatitude),
                String.valueof(record.BillingLongitude ),
                record.Id,
                record.Name,
                record.Industry,
                record.type,
                String.valueOf(record.ESC_NBC_Active__c == true ? 'Active' : 'Inactive'),
                record.Name,
                record.Owner.Name,
                record.BillingCity,
                record.BillingState,
                record.BillingPostalCode    
            );
            if(record.BillingAddress != null) {
                String addressStr = 
                    (record.BillingCity != null ? record.BillingCity + ' ' : '') +
                    (record.BillingPostalCode != null ? record.BillingPostalCode + ' ' : '') +
                    (record.BillingState != null ? record.BillingState + ' ' : '') +
                    (record.BillingCountry != null ? record.BillingCountry : '');

                lwCon.description = 'Address : ' + '<br/>' + '<b>' + addressStr + '</b>'; 
            }
            lwCon.mapIcon = new MapIconWrapper();
            lwCon.mapIcon.fillColor = 'green';
            
            locList.add(lwCon);
        }
        
        return JSON.serialize(locList);
    }


    /*@AuraEnabled(cacheable=true)
public static Map<Id, String> getLatestJobOpeningsForAccounts(List<Id> accountIds) {
    Map<Id, String> latestJobMap = new Map<Id, String>();

    List<Job_Opening__c> jobs = [
        SELECT Id, Name, Client__c, Client__r.Name, CreatedDate
        FROM Job_Opening__c
        WHERE Client__c IN :accountIds
        ORDER BY CreatedDate DESC
    ];

    Set<Id> processedClients = new Set<Id>();
    for (Job_Opening__c job : jobs) {
        if (!processedClients.contains(job.Client__c)) {
            latestJobMap.put(job.Client__c, job.Name);
            processedClients.add(job.Client__c);
        }
    }

    return latestJobMap;
}*/

        /*@AuraEnabled(cacheable=true)
    public static Map<Id, String> getLatestJobOpeningsForAccounts(List<Id> accountIds) {
        Map<Id, String> latestJobMap = new Map<Id, String>();

        // Fetch all job openings related to the given accounts, sorted by most recent first
        List<Job_Opening__c> jobs = [
            SELECT Id, Job_Title__c, Client__c, CreatedDate
            FROM Job_Opening__c
            WHERE Client__c IN :accountIds
            ORDER BY CreatedDate DESC
        ];

        // Keep only the most recent job for each Client
        Set<Id> processedClients = new Set<Id>();
        for (Job_Opening__c job : jobs) {
            if (!processedClients.contains(job.Client__c)) {
                latestJobMap.put(
                    job.Client__c,
                    job.Job_Title__c != null && job.Job_Title__c.trim() != '' ? job.Job_Title__c : 'No job'
                );
                processedClients.add(job.Client__c);
            }
        }

        // For accounts with no job openings at all
        for (Id accountId : accountIds) {
            if (!latestJobMap.containsKey(accountId)) {
                latestJobMap.put(accountId, 'No job');
            }
        }

        return latestJobMap;
    }*/

    @AuraEnabled(cacheable=true)
    public static Map<Id, String> getLatestJobOpeningsForAccounts(List<Id> accountIds) {
        Map<Id, String> latestJobMap = new Map<Id, String>();

        // Only fetch job openings with Status = Active or Inactive
        List<Job_Opening__c> jobs = [
            SELECT Id, Job_Title__c, Client__c, CreatedDate
            FROM Job_Opening__c
            WHERE Client__c IN :accountIds
            AND Status__c IN ('Active', 'Inactive')
            ORDER BY CreatedDate DESC
        ];

        Set<Id> processedClients = new Set<Id>();
        for (Job_Opening__c job : jobs) {
            if (!processedClients.contains(job.Client__c)) {
                latestJobMap.put(
                    job.Client__c,
                    String.isNotBlank(job.Job_Title__c) ? job.Job_Title__c : 'No job'
                );
                processedClients.add(job.Client__c);
            }
        }

        // For clients with no eligible job openings
        for (Id accountId : accountIds) {
            if (!latestJobMap.containsKey(accountId)) {
                latestJobMap.put(accountId, 'No job');
            }
        }

        return latestJobMap;
    }



    
    public class LocationWrapper {
        public Location location ;
        public String value ;
        public String name ;
        public String type;
        public String industry;
        public String isActive;
        public String title ;
        public String salesOwner;
        public String description;
        public Integer radius;
        public String strokeColor;
        public Double strokeOpacity;
        public Integer strokeWeight;
        public String fillColor;
        public Double fillOpacity;
        public MapIconWrapper mapIcon;

        public String billingCity;
        public String billingState;
        public String billingPostalCode;
        // Constructor
        public LocationWrapper(String Latitude, String Longitude, String value, String name, String industry, String type, String isActive, String title, String salesOwner,
        String billingCity,
        String billingState,
        String billingPostalCode
        ) {
            this.location = new Location();
            this.location.Latitude = Latitude;
            this.location.Longitude = Longitude;
            this.value = value;
            this.title = title;
            this.name = name;
            this.type = type;
            this.industry = industry;
            this.type = type;
            this.isActive = isActive;
            this.salesOwner = salesOwner;
            this.billingCity = billingCity;
            this.billingState = billingState;
            this.billingPostalCode = billingPostalCode;
            // this.jobTitle = jobTitle;
            // this.recordTypeName = recordTypeName;
        }
        public LocationWrapper(String Latitude, String Longitude) {
            this.location = new Location();
            this.location.Latitude = Latitude;
            this.location.Longitude = Longitude;
        }
    }

    public class Location {
        public String Latitude ;
        public String Longitude ;
        public string City;
        public string Country;
        public string PostalCode;
        public string State;            
        public string Street;
    }

    public class MapIconWrapper {
        public String path ;
        public String fillColor ;
        public Double fillOpacity ;
        public Double strokeOpacity ;
        public String strokeColor ;
        public Double strokeWeight ;
        public Double scale ;
        
        public MapIconWrapper() {
            this.path = 'M 0,0 C -2,-20 -10,-22 -10,-30 A 10,10 0 1,1 10,-30 C 10,-22 2,-20 0,0 z';
            this.fillColor = 'blue';
            this.fillOpacity = 1;
            this.strokeOpacity = 1;
            this.strokeColor = '#000';
            this.strokeWeight = 1;
            this.scale = 1;
        }
    }
}