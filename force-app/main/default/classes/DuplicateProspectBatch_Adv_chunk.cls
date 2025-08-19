global class DuplicateProspectBatch_Adv_chunk implements Database.Batchable<SObject>, Database.Stateful {
    private Map<String, List<Id>> emailToIds = new Map<String, List<Id>>();
    private Map<String, List<Id>> phoneToIds = new Map<String, List<Id>>();
    private Map<Id, ESC_NBC_Prospect__c> idToPros = new Map<Id, ESC_NBC_Prospect__c>();
    private String phonePrefix;

    /**
     * Constructor takes a phone prefix to chunk the query
     */
    public DuplicateProspectBatch_Adv_chunk(String phonePrefix) {
        this.phonePrefix = phonePrefix;
    }

    /**
     * Start: stream prospects based on phone prefix or null phones when prefix = '0'
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (phonePrefix == '0') {
            // Handle null or blank phone values
            return Database.getQueryLocator([
                SELECT Id, ESC_NBC_Email__c, ESC_NBC_Phone__c
                FROM ESC_NBC_Prospect__c
                WHERE ESC_NBC_Phone__c = null
                   OR ESC_NBC_Phone__c = ''
            ]);
        } else {
            // Regular prefix-based chunking
            return Database.getQueryLocator([
                SELECT Id, ESC_NBC_Email__c, ESC_NBC_Phone__c
                FROM ESC_NBC_Prospect__c
                WHERE ESC_NBC_Phone__c LIKE :phonePrefix + '%'
            ]);
        }
    }

    /**
     * Execute: collect IDs by email and phone within this chunk
     */
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (SObject sobj : scope) {
            ESC_NBC_Prospect__c p = (ESC_NBC_Prospect__c) sobj;
            idToPros.put(p.Id, p);
            if (p.ESC_NBC_Email__c != null) {
                if (!emailToIds.containsKey(p.ESC_NBC_Email__c)) {
                    emailToIds.put(p.ESC_NBC_Email__c, new List<Id>());
                }
                emailToIds.get(p.ESC_NBC_Email__c).add(p.Id);
            }
            if (p.ESC_NBC_Phone__c != null) {
                if (!phoneToIds.containsKey(p.ESC_NBC_Phone__c)) {
                    phoneToIds.put(p.ESC_NBC_Phone__c, new List<Id>());
                }
                phoneToIds.get(p.ESC_NBC_Phone__c).add(p.Id);
            }
        }
    }

    /**
     * Finish: build and insert Duplicate_Prospect__c records based on match logic
     */
    global void finish(Database.BatchableContext bc) {
        List<Duplicate_Prospect__c> dupRecs = new List<Duplicate_Prospect__c>();

        // Email-based and Email+Phone duplicates
        for (String email : emailToIds.keySet()) {
            List<Id> ids = emailToIds.get(email);
            if (ids.size() > 1) {
                for (Integer i = 0; i < ids.size(); i++) {
                    for (Integer j = i + 1; j < ids.size(); j++) {
                        Id id1 = ids[i];
                        Id id2 = ids[j];
                        ESC_NBC_Prospect__c p1 = idToPros.get(id1);
                        ESC_NBC_Prospect__c p2 = idToPros.get(id2);
                        Boolean phoneMatches = p1.ESC_NBC_Phone__c != null && p1.ESC_NBC_Phone__c == p2.ESC_NBC_Phone__c;
                        String matchType = phoneMatches ? 'Email and Phone' : 'Email';
                        dupRecs.add(new Duplicate_Prospect__c(
                            Prospect_1__c = id1,
                            Prospect_2__c = id2,
                            Match_Type__c = matchType
                        ));
                        dupRecs.add(new Duplicate_Prospect__c(
                            Prospect_1__c = id2,
                            Prospect_2__c = id1,
                            Match_Type__c = matchType,
                            Is_Reciprocal__c = true
                        ));
                    }
                }
            }
        }

        // Phone-only duplicates (skip those with same email)
        for (String phone : phoneToIds.keySet()) {
            List<Id> ids = phoneToIds.get(phone);
            if (ids.size() > 1) {
                for (Integer i = 0; i < ids.size(); i++) {
                    for (Integer j = i + 1; j < ids.size(); j++) {
                        Id id1 = ids[i];
                        Id id2 = ids[j];
                        ESC_NBC_Prospect__c p1 = idToPros.get(id1);
                        ESC_NBC_Prospect__c p2 = idToPros.get(id2);
                        // Skip if already matched by email
                        if (p1.ESC_NBC_Email__c == p2.ESC_NBC_Email__c) continue;
                        dupRecs.add(new Duplicate_Prospect__c(
                            Prospect_1__c = id1,
                            Prospect_2__c = id2,
                            Match_Type__c = 'Phone'
                        ));
                        dupRecs.add(new Duplicate_Prospect__c(
                            Prospect_1__c = id2,
                            Prospect_2__c = id1,
                            Match_Type__c = 'Phone',
                            Is_Reciprocal__c = true
                        ));
                    }
                }
            }
        }

        if (!dupRecs.isEmpty()) {
            insert dupRecs;
        }
        System.debug('Inserted ' + dupRecs.size() + ' duplicate prospect records for prefix ' + phonePrefix);
    }
}

// To execute two smaller chunks:
// Database.executeBatch(new DuplicateProspectBatch_Adv_chunk('2'), 200);
// Database.executeBatch(new DuplicateProspectBatch_Adv_chunk('3'), 200);
// Database.executeBatch(new DuplicateProspectBatch_Adv_chunk('0'), 200); // Null/blank phones