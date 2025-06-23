/**
* @author Conga Services, ERedding
* @date 20190116
* @version 1.00
* @description JaroWinklerSimilarityTest  - Test class for the JaroWinklerSimilarity class
*/
@isTest
public with sharing class JaroWinklerSimilarityTest {

    /**
    * @description calculateSimilarityTest - Test similiarity code
    */
    public static testMethod void calculateSimilarityTest() {
        Test.startTest();

        // IF EITHER VALUE IS NULL OR BLANK, RETURNED VALUE SHOULD BE 0
        Double nullBlankResult1 = JaroWinklerSimilarity.calculateSimilarity(null, 'My string');
        Double nullBlankResult2 = JaroWinklerSimilarity.calculateSimilarity('My string', null);
        Double nullBlankResult3 = JaroWinklerSimilarity.calculateSimilarity('', 'My string');
        Double nullBlankResult4 = JaroWinklerSimilarity.calculateSimilarity('My string', '');
        System.assert(nullBlankResult1 == 0);
        System.assert(nullBlankResult2 == 0);
        System.assert(nullBlankResult3 == 0);
        System.assert(nullBlankResult4 == 0);

        // IF VALUES ARE THE SAME, RETURNED VALUE SHOULD BE 1
        Double matchingResult1 = JaroWinklerSimilarity.calculateSimilarity('My string', 'My string');
        System.assert(matchingResult1 == 1);

        // IF VALUES ARE COMPLETELY DIFFERENT, RETURNED VALUE SHOULD BE 0
        Double completelyDifferentResult1 = JaroWinklerSimilarity.calculateSimilarity('ABCD', 'RSTU');
        System.assert(completelyDifferentResult1 == 0);

        // LONGER/SHORTER VARIATIONS
        JaroWinklerSimilarity.calculateSimilarity('ShortText', 'LongerText');
        JaroWinklerSimilarity.calculateSimilarity('LongerText', 'ShortText');

        // DEFAULT THRESHOLD OF 0.70
        Double defaultThresholdResult1 = JaroWinklerSimilarity.calculateSimilarity('My string', 'My tsring');
        Double defaultThresholdResult2 = JaroWinklerSimilarity.calculateSimilarity('My string', 'My ntrisg');
        System.assert(String.valueOf(defaultThresholdResult1).left(6) == '0.9740');
        System.assert(String.valueOf(defaultThresholdResult2).left(6) == '0.8962');

        // SPECIFIED THRESHOLD OF 0.98, ONLY JARO DISTANCE WILL BE RETURNED, WITHOUT PREFIX BOOST
        Double specifiedThresholdResult1 = JaroWinklerSimilarity.calculateSimilarity('My string', 'My tsring', (Double)0.98);
        Double specifiedThresholdResult2 = JaroWinklerSimilarity.calculateSimilarity('My string', 'My ntrisg', (Double)0.98);
        System.assert(String.valueOf(specifiedThresholdResult1).left(6) == '0.9629');
        System.assert(String.valueOf(specifiedThresholdResult2).left(6) == '0.8518');

        Test.stopTest();
    }


}