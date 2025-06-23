/**
* @author Conga Services, ERedding
* @date 20190116
* @version 1.00
* @description JaroWinklerSimilarity - Jaro Winkler string similarity calculation code. Transposed from Java to Apex using this code:
*                                      https://salsa.debian.org/java-team/java-string-similarity/blob/master/src/main/java/info/debatty/java/stringsimilarity/JaroWinkler.java
*/
public class JaroWinklerSimilarity {
    private static final Double DEFAULT_THRESHOLD = 0.7;
    private static final Double JW_COEF = 0.1;

    /**
     * @description calculateSimilarity - Calculate Jaro-Winkler similarity using the default prefix boost threshold of 0.7
     * @param firstString - The first string to compare.
     * @param secondString - The second string to compare.   
     * @return Double - Value between 0 and 1 that is the calculated JaroWinkler similarity value
     */  
    public static Double calculateSimilarity(String firstString, String secondString) {
        return calculateSimilarity(firstString, secondString, DEFAULT_THRESHOLD);
    }

    /**
     * @description calculateSimilarity - Calculate Jaro-Winkler similarity using the supplied prefix boost threshold
     * @param String firstString - The first string to compare.
     * @param String secondString - The second string to compare.
     * @param Double prefixBoostThreshold - Value between 0 and 1 and the threshold where the prefix boost is added to the Jaro distance  
     * @return Double - Value between 0 and 1 that is the calculated JaroWinkler similarity value
     */    
    public static Double calculateSimilarity(String firstString, String secondString, Double prefixBoostThreshold) {
        try{
            if(String.isBlank(firstString) || String.isBlank(secondString)){
                return 0; // RETURN 0 IF EITHER STRING IS NULL OR EMPTY OR ONLY WHITESPACE
            }

            if(firstString.equals(secondString)){
                return 1; // RETURN 1 IF STRINGS ARE EXACT MATCHES
            }

            List<Integer> data = getCalculationData(firstString, secondString);
            Double matches = data[0];
            Double transpositions = data[1];
            Double prefix = data[2];
            Double maxLength = data[3];

            if(matches == 0) {
                return 0;
            }

            Double jaroDistance = (matches / firstString.length() + matches / secondString.length() + (matches - transpositions) / matches) / 3;

            // ADD PREFIX BOOST TO CREATE JARO WINKLER SIMILARITY, OTHERWISE RETURN THE JARO DISTANCE
            if(jaroDistance > prefixBoostThreshold){
                return (jaroDistance + Math.min(JW_COEF, 1.0 / maxLength) * prefix * (1 - jaroDistance)); // JARO WINKLER SIMILARITY
            }
            else{
                return jaroDistance; // JARO DISTANCE
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('JaroWinklerSimilarity', 'calculateSimilarity', '', ex, true);
            return 0;
        }
    }

    /**
     * @description matches - Builds an Integer array containing th data required by the Jaro-Winkler similarity calculation
     * @param firstString The first string to compare.
     * @param secondString The second string to compare.
     * @return List<Integer> - List of Integer data points to be used by the Jaro-Winkler similarity calculation
     */
    private static List<Integer> getCalculationData(String firstString, String secondString) {
        String longer;
        String shorter;
        if (firstString.length() > secondString.length()) {
            longer = firstString;
            shorter = secondString;
        }
        else {
            longer = secondString;
            shorter = firstString;
        }

        Integer range = Math.max(longer.length() / 2 - 1, 0);
        List<Integer> matchIndexes = new Integer[shorter.length()];
        for(Integer i = 0; i < matchIndexes.size(); i++){
            matchIndexes[i] = -1;
        }

        List<Boolean> matchflags = new Boolean[longer.length()];
        for(Integer i = 0; i < matchflags.size(); i++){
            matchflags[i] = false;
        }

        Integer matches = 0;
        for(Integer mi = 0; mi < shorter.length(); mi++) {
            String c1 = shorter.mid(mi,1);
            for(Integer xi = Math.max(mi - range, 0), xn = Math.min(mi + range + 1, longer.length()); xi < xn; xi++) {
                if(!matchflags[xi] && shorter.charAt(mi) == longer.charAt(xi)){
                    matchIndexes[mi] = xi;
                    matchflags[xi] = true;
                    matches++;
                    break;
                }
            }
        }

        List<String> ms1 = new String[matches];
        List<String> ms2 = new String[matches];
        for(Integer i = 0, si = 0; i < shorter.length(); i++) {
            if(matchIndexes[i] != -1) {
                ms1[si] = shorter.mid(i,1);
                si++;
            }
        }
        for(Integer i = 0, si = 0; i < longer.length(); i++) {
            if(matchflags[i]) {
                ms2[si] = longer.mid(i,1);
                si++;
            }
        }

        Integer transpositions = 0;
        for(Integer mi = 0; mi < ms1.size(); mi++) {
            if(ms1[mi] != ms2[mi]) {
                transpositions++;
            }
        }

        Integer prefix = 0;
        for(Integer mi = 0; mi < shorter.length(); mi++) {
            if(firstString.charAt(mi) == secondString.charAt(mi) && prefix < 4) {
                prefix++;
            } 
            else{
                break;
            }
        }

        return new List<Integer>{ matches, transpositions / 2, prefix, longer.length() };
    }


}