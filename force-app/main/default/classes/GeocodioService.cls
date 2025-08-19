public class GeocodioService {



   /* private static final String GEOCODIO_API_KEY = '7067060688ddd8116dec7d1de888778e7e866d8';


    public class GeocodeResult {

        public Decimal latitude;

        public Decimal longitude;

    }



    public static GeocodeResult geocodeAddress(String address) {

        GeocodeResult result = new GeocodeResult();



        // Prepare the HTTP request

        Http http = new Http();

        HttpRequest request = new HttpRequest();

        String endpoint = 'https://api.geocod.io/v1.7/geocode?q=' + EncodingUtil.urlEncode(address, 'UTF-8') + '&api_key=' + GEOCODIO_API_KEY;

        

        request.setEndpoint(endpoint);

        request.setMethod('GET');



        try {

            HttpResponse response = http.send(request);

			System.debug('inside try response --->>'+response);

            if (response.getStatusCode() == 200) {

                // Parse JSON response

                Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                List<Object> results = (List<Object>) resMap.get('results');

				System.debug('results is --->> '+results);

                if (!results.isEmpty()) {

                    Map<String, Object> firstResult = (Map<String, Object>) results[0];

                    Map<String, Object> location = (Map<String, Object>) firstResult.get('location');

                    result.latitude = (Decimal) location.get('lat');
                    System.debug('latitude --> '+result.latitude);

                    result.longitude = (Decimal) location.get('lng');
                    System.debug('longitude --> '+result.longitude);

                } else {

                    System.debug('No results found for address: ' + address);

                }

            } else {

                System.debug('Error response from Geocod.io: ' + response.getStatusCode() + ' ' + response.getBody());

            }

        } catch (Exception e) {

            System.debug('Exception during HTTP callout: ' + e.getMessage());

        }



        return result;

    }*/
    private static final String GEOCODIO_API_KEY = '7067060688ddd8116dec7d1de888778e7e866d8';

    public static Map<String, String> geocodeAddress(String address) {
        Map<String, String> geoCodeMap = new Map<String, String>();

        try {
            // Prepare the HTTP request
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            String endpoint = 'https://api.geocod.io/v1.7/geocode?q=' + EncodingUtil.urlEncode(address, 'UTF-8') +
                              '&api_key=' + GEOCODIO_API_KEY;

            request.setEndpoint(endpoint);
            request.setMethod('GET');

            HttpResponse response = http.send(request);
            System.debug('Geocod.io response: ' + response.getBody());

            if (response.getStatusCode() == 200) {
                Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> results = (List<Object>) resMap.get('results');

                if (!results.isEmpty()) {
                    Map<String, Object> firstResult = (Map<String, Object>) results[0];
                    Map<String, Object> location = (Map<String, Object>) firstResult.get('location');

                    String lat = String.valueOf(location.get('lat'));
                    String lng = String.valueOf(location.get('lng'));
					System.debug('lat is -->'+lat+' lng is ---> '+lng);

                    geoCodeMap.put('latitude', lat);
                    geoCodeMap.put('longitude', lng);
                } else {
                    System.debug('No results found for address: ' + address);
                }
            } else {
                System.debug('Error response from Geocod.io: ' + response.getStatusCode() + ' ' + response.getBody());
            }

        } catch (Exception e) {
            System.debug('Exception during HTTP callout: ' + e.getMessage());
        }

        return geoCodeMap;
    }

}