public class ESC_NBC_LaunchInactiveProspectBatch {

    @InvocableMethod(label='Run Inactive Prospect Batch')
    public static void runBatch(List<String> dummyInput) {
        Database.executeBatch(new ESC_NBC_InactiveProspectBatch(), 200);
    }
}