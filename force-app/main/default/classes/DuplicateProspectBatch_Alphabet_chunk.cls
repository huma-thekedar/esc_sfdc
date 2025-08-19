global class DuplicateProspectBatch_Alphabet_chunk implements Database.Batchable<SObject>, Database.Stateful {
    private List<String> emailPrefixes;
    private Map<String, List<Id>> emailToIds = new Map<String, List<Id>>();
    private Map<String, List<Id>> phoneToIds = new Map<String, List<Id>>();
    private Map<Id, ESC_NBC_Prospect__c> idToPros = new Map<Id, ESC_NBC_Prospect__c>();

    /**
     * Constructor takes a list of email prefixes to chunk the query.
     * Include '0' to fetch records with null or blank emails.
     */
    public DuplicateProspectBatch_Alphabet_chunk(List<String> emailPrefixes) {
        this.emailPrefixes = emailPrefixes;
    }

    /**
     * Start: stream prospects based on email prefixes or null emails when '0' is passed.
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> whereClauses = new List<String>();

        // Null or blank emails
        if (emailPrefixes.contains('0')) {
            whereClauses.add('(ESC_NBC_Email__c = NULL OR ESC_NBC_Email__c = \'\')');
        }

        // Email prefix conditions
        List<String> prefixClauses = new List<String>();
        for (String prefix : emailPrefixes) {
            if (prefix != '0') {
                // properly escape the single quotes around the LIKE pattern
                prefixClauses.add('ESC_NBC_Email__c LIKE \'' + String.escapeSingleQuotes(prefix) + '%\'');
            }
        }
        if (!prefixClauses.isEmpty()) {
            whereClauses.add('(' + String.join(prefixClauses, ' OR ') + ')');
        }

        String query = 'SELECT Id, ESC_NBC_Email__c, ESC_NBC_Phone__c FROM ESC_NBC_Prospect__c';
        if (!whereClauses.isEmpty()) {
            query += ' WHERE ' + String.join(whereClauses, ' OR ');
        }
        return Database.getQueryLocator(query);
    }

    /**
     * Execute: collect IDs by email and phone within this chunk
     */
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (SObject sobj : scope) {
            ESC_NBC_Prospect__c p = (ESC_NBC_Prospect__c) sobj;
            idToPros.put(p.Id, p);

            if (String.isNotBlank(p.ESC_NBC_Email__c)) {
                if (!emailToIds.containsKey(p.ESC_NBC_Email__c)) {
                    emailToIds.put(p.ESC_NBC_Email__c, new List<Id>());
                }
                emailToIds.get(p.ESC_NBC_Email__c).add(p.Id);
            }
            if (String.isNotBlank(p.ESC_NBC_Phone__c)) {
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
                        Boolean phoneMatches = String.isNotBlank(p1.ESC_NBC_Phone__c)
                            && p1.ESC_NBC_Phone__c == p2.ESC_NBC_Phone__c;
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

        // Phone-only duplicates
        for (String phone : phoneToIds.keySet()) {
            List<Id> ids = phoneToIds.get(phone);
            if (ids.size() > 1) {
                for (Integer i = 0; i < ids.size(); i++) {
                    for (Integer j = i + 1; j < ids.size(); j++) {
                        Id id1 = ids[i];
                        Id id2 = ids[j];
                        ESC_NBC_Prospect__c p1 = idToPros.get(id1);
                        ESC_NBC_Prospect__c p2 = idToPros.get(id2);
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
        System.debug('Inserted ' + dupRecs.size()
            + ' duplicate prospect records for email prefixes: ' + emailPrefixes);
    }
}

// Sample usage:
// Database.executeBatch(new DuplicateProspectBatch_Alphabet_chunk(new List<String>{'A','B','C'}), 200);
// Database.executeBatch(new DuplicateProspectBatch_Alphabet_chunk(new List<String>{'0'}), 200);