/**
* @File Name : addressSearchController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 13, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 13, 2024 |   | Initial Version
**/

public without sharing class addressSearchController {
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
        qryStr = 'select Id,name,ESC_NBC_Prospect_Source__c, ESC_NBC_Job_Title__c, ESC_NBC_City__c, ESC_NBC_State__c, ESC_NBC_Address__PostalCode__s, ESC_NBC_Address__CountryCode__s, ESC_NBC_Prospect_Status__c, ESC_NBC_Linkedin_URL__c,ESC_NBC_Address__Latitude__s, ESC_NBC_Address__Longitude__s ,ESC_NBC_Address__c, RecordType.Name from ESC_NBC_Prospect__c  WHERE DISTANCE(ESC_NBC_Address__c , GEOLOCATION(';
        qryStr = qryStr + geocode + '), \'mi\') <  '+ miles;
        qryStr = qryStr + ' order by LastActivityDate desc limit 10000';
        System.debug('Query' + qryStr);
        for(ESC_NBC_Prospect__c l : Database.query(qryStr) ){
            System.debug('Prospect : ' + l);
            LocationWrapper lwCon = new LocationWrapper(
                String.valueof(l.ESC_NBC_Address__Latitude__s),
                String.valueof(l.ESC_NBC_Address__Longitude__s ),
                l.id,
                l.name,
                l.ESC_NBC_Linkedin_URL__c,
                l.ESC_NBC_Prospect_Status__c,
                l.ESC_NBC_Prospect_Source__c,
                l.ESC_NBC_Job_Title__c,
                l.RecordType.Name,
                l.ESC_NBC_City__c,
    			l.ESC_NBC_Address__PostalCode__s
            );
            if(l.ESC_NBC_Address__c != null) {
                String addressStr = 
                    (l.ESC_NBC_City__c != null ? l.ESC_NBC_City__c + ' ' : '') +
                    (l.ESC_NBC_Address__PostalCode__s != null ? l.ESC_NBC_Address__PostalCode__s + ' ' : '') +
                    (l.ESC_NBC_State__c != null ? l.ESC_NBC_State__c + ' ' : '') +
                    (l.ESC_NBC_Address__CountryCode__s != null ? l.ESC_NBC_Address__CountryCode__s : '');

                lwCon.description = 'Address : ' + '<br/>' + '<b>' + addressStr + '</b>'; 
            }
            lwCon.mapIcon = new MapIconWrapper();
            lwCon.mapIcon.fillColor = 'green';
            locList.add(lwCon);
        }
        
        return JSON.serialize(locList);
    }
    
    public class LocationWrapper {
        public Location location ;
        public String value ;
        public String title ;
        public String leadstatus;
        public String leadSource;
        public String jobTitle;
        public String recordTypeName;
        public String description ;
        public String type;
        public Integer radius;
        public String strokeColor;
        public Double strokeOpacity;
        public Integer strokeWeight;
        public String fillColor;
        public Double fillOpacity;
        public MapIconWrapper mapIcon;
        public String city;
		public String postalCode;
        // Constructor
        
        public LocationWrapper(String Latitude, String Longitude, String value, String title, String description, String leadStatus, String leadSource, String jobTitle, String recordTypeName, String city, String postalCode) {
            this.location = new Location();
            this.location.Latitude = Latitude;
            this.location.Longitude = Longitude;
            this.value = value;
            this.title = title;
            this.description = description;
            this.leadStatus = leadStatus;
            this.leadSource = leadSource;
            this.jobTitle = jobTitle;
            this.recordTypeName = recordTypeName;
            this.city = city;
            this.postalCode = postalCode;
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