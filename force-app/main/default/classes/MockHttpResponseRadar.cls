@isTest
global class MockHttpResponseRadar implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"meta":{"code":200},"addresses":[{"addressLabel":"Garden City","city":"Garden City","country":"United States","countryCode":"US","countryFlag":"🇺🇸","county":"Nassau County","distance":4141542.2987495884,"formattedAddress":"Garden City, NY US","geometry":{"type":"Point","coordinates":[-73.6343,40.72677]},"latitude":40.72677,"longitude":-73.6343,"state":"New York","stateCode":"NY","layer":"locality","timeZone":{"id":"America/New_York","name":"Eastern Daylight Time","code":"EDT","currentTime":"2024-10-11T12:43:18-04:00","utcOffset":-14400,"dstOffset":3600}}]}');
        res.setStatusCode(200);
        return res;
    }
}