public class ESC_NBC_ProspectProcessor implements Queueable, Database.AllowsCallouts {
    String prospectId;
    public ESC_NBC_ProspectProcessor(String prospectId) {
        this.prospectId = prospectId;
    }
    public void execute(QueueableContext qc){
        uopdateGeoCode(prospectId);
    }
    public static void uopdateGeoCode(String prospectId) {
        ESC_NBC_prospect__c prospect = [Select 
                                       	id,ESC_NBC_Address__Street__s, ESC_NBC_Address__City__s,ESC_NBC_Address__StateCode__s,
                                       	ESC_NBC_Address__CountryCode__s
                                       FROM
                                       	ESC_NBC_prospect__c
                                       WHERE Id =:prospectId
                                      ];
        String address = prospect.ESC_NBC_Address__Street__s + '+' + prospect.ESC_NBC_Address__City__s + '+' +
                  prospect.ESC_NBC_Address__StateCode__s + '+' + prospect.ESC_NBC_Address__StateCode__s + '+' +
                  prospect.ESC_NBC_Address__CountryCode__s;
        Map<String, String> geoCodeMap = new Map<String, String>();
        //geoCodeMap = ESC_NBC_GoogleAPIService.getGeoCode(address);
        geoCodeMap = GeocodioService.geocodeAddress(address);
        System.debug('geoCode are ---> '+geoCodeMap);
        if(geoCodeMap.size() > 0) {
            prospect.ESC_NBC_Address__Latitude__s = Decimal.ValueOf(geoCodeMap.get('latitude'));
            prospect.ESC_NBC_Address__Longitude__s = Decimal.ValueOf(geoCodeMap.get('longitude'));
            update prospect;
        } 
    }
}