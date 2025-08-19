({
    init: function (component, event, helper) {
        const recordId = component.get("v.recordId");
        const sObjectName = component.get("v.sObjectName");
        const recordTypeId = component.get("v.recordTypeId");

        console.log("Aura Record ID: ", recordId);
        console.log("Aura Object Name: ", sObjectName);
        console.log("Aura RecordType ID: ", recordTypeId);

        const inputVariables = [
            {
                name: "inputRecordId",
                type: "String",
                value: recordId || ""
            },
            {
                name: "inputObjectName",
                type: "String",
                value: sObjectName || ""
            },
            {
                name: "inputRecordTypeId",
                type: "String",
                value: recordTypeId || ""
            }
        ];

        console.log("Passing to Flow: ", inputVariables);

        const flow = component.find("flowData");
        flow.startFlow("New_Interview", inputVariables);
    },

    handleStatusChange: function (component, event, helper) {
        if (event.getParam("status") === "FINISHED") {
            console.log("Flow completed");
        }
    }
});