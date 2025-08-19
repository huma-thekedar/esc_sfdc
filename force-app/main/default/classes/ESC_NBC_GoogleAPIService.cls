public class ESC_NBC_GoogleAPIService {
	public static Map<String, String> getGeoCode(String address) {
		Map<String, String> geoCodeMap = new Map<String, String>();
		try{
			HttpRequest req = new HttpRequest();
            String encodedAddress = EncodingUtil.urlEncode(address, 'UTF-8');
            req.setEndpoint('https://api.radar.io/v1/geocode/forward?query='+encodedAddress);
            //req.setEndpoint('https://api.radar.io/v1/geocode/forward?query='+address); 
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
					geoCodeMap.put('latitude', String.valueof(mapObj.get('latitude')));
					geoCodeMap.put('longitude', String.valueof(mapObj.get('longitude')));
                    // return String.valueof(mapObj.get('latitude'))+','+String.valueof(mapObj.get('longitude'));
                }
            }
			return geoCodeMap;
		}
        Catch(Exception e){    
            system.debug(e.getStackTraceString()+'::'+e.getLineNumber()+'::'+e.getMessage()+'::'+e.getCause());        
            // return 'Error';
			return geoCodeMap;
        }
	}
}