public with sharing class IdentifyRecordIdsByNameMultiObjects_V1 {

    /* ---------- Input DTO ------------------------------------------- */
    public class Request {
        @InvocableVariable(required=true
            label='Record Name Prefix'
            description='Initial text of the Name field to search for (e.g., "Acme").')
        public String recordName;

        @InvocableVariable(
            label='Object API Names'
            description='Optional list of object API names to search (e.g., ["Account","Contact"]). If omitted, a default set of common objects is used.')
        public List<String> objectApiNames;
    }

    /* ---------- Output DTO ------------------------------------------ */
    public class Response {
        @InvocableVariable(label='Matching Record IDs'
            description='Unified list of record Ids matching the search criteria.')
        public List<Id> recordIds;
    }

    /* ---------- Invocable Method ------------------------------------ */
    @InvocableMethod(
        label='Identify Record IDs by Name (Multi‑Object) V1'
        description='Searches for up to five record IDs per specified object (or a sensible default set) whose Name field starts with the provided text and returns a unified list of matching IDs.')
    public static List<Response> run(List<Request> requests) {
        List<Response> out = new List<Response>();

        for (Request r : requests) {
            if (r.objectApiNames == null || r.objectApiNames.isEmpty()) {
                // Default object list – adjust based on org needs
                r.objectApiNames = new List<String>{'Account','Contact','Opportunity','Lead','Case','User','Task','Event','Campaign','Asset'};
            }

            // Build RETURNING clause with a limit of five IDs per object
            List<String> clauses = new List<String>();
            for (String apiName : r.objectApiNames) {
                clauses.add(apiName + ' (Id LIMIT 5)');
            }
            String returningClause = String.join(clauses, ', ');

            // Construct SOSL
            String sosl = 'FIND {' + String.escapeSingleQuotes(r.recordName) + '} IN NAME FIELDS RETURNING ' + returningClause;

            // Execute search
            List<List<SObject>> hits = Search.query(sosl);

            // Collect unique IDs
            Set<Id> idSet = new Set<Id>();
            for (List<SObject> lst : hits) {
                for (SObject sob : lst) {
                    idSet.add((Id)sob.get('Id'));
                }
            }

            Response resp = new Response();
            resp.recordIds = new List<Id>(idSet);
            out.add(resp);
        }

        return out;
    }
}