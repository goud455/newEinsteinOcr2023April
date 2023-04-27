public class fetchSentiments {
    
    public static String text = '';
    public static String text1 = '';
    public static String updateCaseId;
    public static string sentimentModelId = 'CommunitySentiment';
    
    @AuraEnabled
    public static string getCaseStatus(string CaseId){
        
        for(Case selectedCase : [SELECT Id,	Comments,Description FROM Case WHERE ID =: CaseId]){
            updateCaseId = selectedCase.Id;
            emailmessage emailMessageRecord = [select id,TextBody from emailmessage where parentid=:selectedCase.Id limit 1];
            system.debug('Field'+emailMessageRecord.TextBody);      
            text = emailMessageRecord.TextBody;
            system.debug('@@@text'+text);
            String []  lines = new list<string>();
		    lines = text.split('\n');
            for(String s: lines){  
                text1 =text1+s+' ';
               }
            system.debug('@@@text1'+text1);
            updateCase(text1);
        }
        return 'Success';
    }
    public static void updateCase(String text){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod( 'POST' );
        req.setEndpoint( 'https://api.einstein.ai/v2/language/sentiment' );
        req.setHeader( 'Authorization', 'Bearer ' + 'KFLUIQ2SKAZUGSBVKNKU2SSQGNJDOTCXLBHEETZWGJGEERKLKFLEUTSUK5EE2VSWIJITEUKHKNDEQTKUKYZU2VCTIVJE4WKYJZFUUWCNJJLEMU2ELFLUCRKIJZJEYWSXJFDUYUJVGVGEGN2MLJMUGWCOJBEVOVBSKFJEC7COIE' );
        req.setHeader( 'Content-type', 'application/json' );
        String body = '{\"modelId\":\"'+ sentimentModelId + '\",\"document\":\"' + text+ '\"}';
        req.setBody( body );
        HTTPResponse res = http.send( req );
        system.debug('resbody'+res.getBody());
        SentimentResponse resp = ( SentimentResponse ) JSON.deserialize( res.getBody(), SentimentResponse.class );
        Map<Double,String> maplabelprobablity = new Map<Double,String>();
        List<SentimentResponse.Probabilities > labelWithProbablity = new List<SentimentResponse.Probabilities >();
        for(SentimentResponse.Probabilities selected : resp.Probabilities){
            SentimentResponse.Probabilities selteced = new SentimentResponse.Probabilities();
            selteced.label = selected.label;
            selteced.probability = selected.probability;
            maplabelprobablity.put(selteced.probability,selteced.label);
            labelWithProbablity.add(selteced);
        }
        if(labelWithProbablity.size()>0){
            case updateCase = new case();
            updateCase.Id = updateCaseId;
            updateCase.Sentiment_Analysis__c = maplabelprobablity.get(labelWithProbablity[0].probability);
            update updateCase;
        }          
    }
}