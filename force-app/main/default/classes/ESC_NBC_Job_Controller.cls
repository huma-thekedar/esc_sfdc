/**
* @File Name : ESC_NBC_Job_Controller.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : March 6, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | March 6, 2025 |   | Initial Version
**/

public class ESC_NBC_Job_Controller {

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
        //query jobs
        /*qryStr = 'select Id, Name, Number_of_Openings__c, Position__c, Job_URL__c, Status__c, Rating__c, Job_Title__c, Address__City__s, Address__StateCode__s, Address__PostalCode__s, Address__CountryCode__s, ';
		qryStr += ' Address__Latitude__s, Job_Source__c, Employment_Type__c, Address__Street__s, Address__Longitude__s ,Address__c from Job_Opening__c  WHERE DISTANCE(Address__c , GEOLOCATION(';
        qryStr = qryStr + geocode + '), \'mi\') <  '+ miles;
        qryStr = qryStr + ' order by LastActivityDate desc LIMIT 100';*/

       qryStr = 'SELECT Id, Name, CreatedDate, Job_Title__c, Status__c, Job_Source__c, Employment_Type__c, ';
       qryStr += 'Job_URL__c, ';
       qryStr += 'Address__City__s, Address__StateCode__s, Address__PostalCode__s, Address__CountryCode__s, ';
       qryStr += 'Address__Latitude__s, Address__Longitude__s, Address__c, ';
       qryStr += 'Client__r.Name, Owner.Alias ';
       qryStr += 'FROM Job_Opening__c ';
       qryStr += 'WHERE DISTANCE(Address__c, GEOLOCATION(' + geoCoordinates[0] + ', ' + geoCoordinates[1] + '), \'mi\') < ' + miles + ' ';
       qryStr += 'ORDER BY LastActivityDate DESC LIMIT 100';





        System.debug('Query' + qryStr);
        System.debug('Results ' + Database.query(qryStr) );
        for(Job_Opening__c l : Database.query(qryStr) ){
            System.debug('Job opening : ' + l);
            /*LocationWrapper lwCon = new LocationWrapper(
                String.valueof(l.Address__Latitude__s),
                String.valueof(l.Address__Longitude__s ),
                l.id,
                l.name,
                l.Job_URL__c,
                l.Status__c,
                l.Job_Source__c,
                l.Job_Title__c,
                l.Employment_Type__c
            );*/

                LocationWrapper lwCon = new LocationWrapper(
                String.valueof(l.Address__Latitude__s),
                String.valueof(l.Address__Longitude__s),
                l.Id,
                l.Name,
                l.Job_URL__c,
                l.Status__c,
                l.Job_Source__c,
                l.Job_Title__c,
                l.Employment_Type__c,
                String.valueOf(l.CreatedDate),                     
                l.Client__r != null ? l.Client__r.Name : '',       
                l.Address__City__s,                                
                l.Address__StateCode__s,                           
                l.Address__PostalCode__s,                          
                l.Owner.Alias                                     
            );

            if(l.Address__c != null) {
                String addressStr = 
                    (l.Address__City__s != null ? l.Address__City__s + ' ' : '') +
                    (l.Address__PostalCode__s != null ? l.Address__PostalCode__s + ' ' : '') +
                    (l.Address__StateCode__s != null ? l.Address__StateCode__s + ' ' : '') +
                    (l.Address__CountryCode__s != null ? l.Address__CountryCode__s : '');

                lwCon.description = 'Address : ' + '<br/>' + '<b>' + addressStr + '</b>'; 
            }
            lwCon.mapIcon = new MapIconWrapper();
            lwCon.mapIcon.fillColor = 'green';
            locList.add(lwCon);
        }
        
        return JSON.serialize(locList);
    }
    
    /*public class LocationWrapper {
        public Location location ;
        public String value ;
        public String title ;
        public String leadstatus;
        public String leadSource;
        public String jobTitle;
        public String employmentType;
        public String description ;
        public String type;
        public Integer radius;
        public String strokeColor;
        public Double strokeOpacity;
        public Integer strokeWeight;
        public String fillColor;
        public Double fillOpacity;
        public MapIconWrapper mapIcon;
        // Constructor
        public LocationWrapper(
            String Latitude, String Longitude, String value, String title, String description, String leadStatus,
            String leadSource, String jobTitle, String employmentType) {
            this.location = new Location();
            this.location.Latitude = Latitude;
            this.location.Longitude = Longitude;
            this.value = value;
            this.title = title;
            this.description = description;
            this.leadStatus = leadStatus;
            this.leadSource = leadSource;
            this.jobTitle = jobTitle.length() > 25  ?jobTitle.substring(0, 25) + '...' : jobTitle;
            this.employmentType = employmentType;
        }
        public LocationWrapper(String Latitude, String Longitude) {
            this.location = new Location();
            this.location.Latitude = Latitude;
            this.location.Longitude = Longitude;
        }
    }*/


    public class LocationWrapper {
    public Location location;
    public String value;
    public String title;
    public String description;
    public String leadstatus;
    public String leadSource;
    public String jobTitle;
    public String employmentType;

    public String jobCreatedDatel;
    public String ClientName;
    public String addressCity;
    public String addressStateCode;
    public String addressPostalCode;
    public String ownerName;

    
    public String type;
    public Integer radius;
    public String strokeColor;
    public Double strokeOpacity;
    public Integer strokeWeight;
    public String fillColor;
    public Double fillOpacity;

    public MapIconWrapper mapIcon;

    public LocationWrapper(
        String Latitude, String Longitude, String value, String title, String description, String leadStatus,
        String leadSource, String jobTitle, String employmentType,
        String jobCreatedDatel, String clientName, String city, String state, String postalCode, String ownerName
    ) {
        this.location = new Location();
        this.location.Latitude = Latitude;
        this.location.Longitude = Longitude;
        this.value = value;
        this.title = title;
        this.description = description;
        this.leadstatus = leadStatus;
        this.leadSource = leadSource;
        this.jobTitle = jobTitle.length() > 25  ? jobTitle.substring(0, 25) + '...' : jobTitle;
        this.employmentType = employmentType;
        this.jobCreatedDatel = jobCreatedDatel;
        this.ClientName = clientName;
        this.addressCity = city;
        this.addressStateCode = state;
        this.addressPostalCode = postalCode;
        this.ownerName = ownerName;
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