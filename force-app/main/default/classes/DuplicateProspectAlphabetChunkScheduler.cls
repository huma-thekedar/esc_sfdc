/**
 * Generic schedulable that runs an email‐alphabet batch for whatever
 * prefixes you pass in. You can schedule multiple instances at
 * different times, each with its own chunk of letters.
 */
global class DuplicateProspectAlphabetChunkScheduler implements Schedulable {
    private List<String> prefixes;

    /**
     * @param prefixes  The list of email prefixes (e.g. 'A','B','C') or
     *                  '0' to process null/blank emails.
     */
    public DuplicateProspectAlphabetChunkScheduler(List<String> prefixes) {
        this.prefixes = prefixes;
    }

    global void execute(SchedulableContext sc) {
        // Launch the alphabet chunk batch for the given prefixes
        Database.executeBatch(
            new DuplicateProspectBatch_Alphabet_chunk(prefixes),
            200
        );
    }
}