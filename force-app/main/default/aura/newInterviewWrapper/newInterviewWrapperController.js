({
    init: function (component, event, helper) {
        const url = new URL(window.location.href); // or put the string directly if you wish
		const recordTypeId = url.searchParams.get("recordTypeId");
        console.log('recorsTypeId>>>' + recordTypeId);
        let recordId = '';
        let sObjectName = '';
        const inContextOfRef = url.searchParams.get("inContextOfRef");
        component.set("v.recordTypeId", recordTypeId);
        if (inContextOfRef) {
            try {
                const encoded = inContextOfRef.split('.')[1];
                const decoded = JSON.parse(atob(encoded));
                sObjectName = decoded.attributes.objectApiName;
                recordId = decoded.attributes.recordId;
                
                console.log('newInterviewWrapper - sObjectName:', sObjectName);
        		console.log('newInterviewWrapper - originatingRecordId:', recordId);
                
                
                if (sObjectName === 'Job_Opening__c') {
                    console.log('Launched from Job Opening');
                } else if(sObjectName === 'ESC_NBC_Prospect__c') {
                    console.log('Launched from Prospect');
                    console.log('recordId'+ recordId)
                }else {
                    console.log('Launched from:', sObjectName);
                }
            } catch (e) {
                console.error('Failed to parse inContextOfRef', e);
            }
        }
        component.set("v.sObjectName", sObjectName);
        component.set("v.recordId", recordId);
        //console.log('newInterviewWrapper - recordId:', component.get('v.recordId'));
        //console.log('newInterviewWrapper - sObjectName:', component.get('v.sObjectName'));
        console.log('newInterviewWrapper - recordTypeId:', recordTypeId);
    },
    onPageReferenceChanged: function(cmp, event, helper) {
        $A.get('e.force:refreshView').fire();
    }
});