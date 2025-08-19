public class ESC_NBC_JobOpeningProcessor implements Queueable, Database.AllowsCallouts {
    String jobOpeningId;
    public ESC_NBC_JobOpeningProcessor(String jobOpeningId) {
        this.jobOpeningId = jobOpeningId;
    }
    public void execute(QueueableContext qc){
        uopdateGeoCode(jobOpeningId);
    }
    public static void uopdateGeoCode(String jobOpeningId) {
        Job_Opening__c jobOpeningObj = [Select 
                                       	id,Address__Street__s, Address__City__s,Address__StateCode__s,
                                       	Address__CountryCode__s
                                       FROM
                                       	Job_Opening__c
                                       WHERE Id =:jobOpeningId
                                      ];
        String address = jobOpeningObj.Address__Street__s + '+' + jobOpeningObj.Address__City__s + '+' +
                  jobOpeningObj.Address__StateCode__s + '+' + jobOpeningObj.Address__StateCode__s + '+' +
                  jobOpeningObj.Address__CountryCode__s;
        Map<String, String> geoCodeMap = new Map<String, String>();
        geoCodeMap = ESC_NBC_GoogleAPIService.getGeoCode(address);
        if(geoCodeMap.size() > 0) {
            jobOpeningObj.Address__Latitude__s = Decimal.ValueOf(geoCodeMap.get('latitude'));
            jobOpeningObj.Address__Longitude__s = Decimal.ValueOf(geoCodeMap.get('longitude'));
            update jobOpeningObj;
        } 
    }
}