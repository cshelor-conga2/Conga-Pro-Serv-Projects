/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180710
* @version 1.0
* @description IntacctUtilsTest - Test class for the IntacctUtils class
*/
@isTest
private class IntacctUtilsTest {
    
    /**
    * @description testReplaceVariables - 
    */
    private static testmethod void testReplaceVariables() {
        String textToReplace = 'A[{{$guid}}]B[{{$timestamp}}]';

        Test.startTest();
        String replacedTest = IntacctUtils.replaceVariables(textToReplace);
        Test.stopTest();

        System.assertEquals(replacedTest.contains('{{$guid}}'), false);
        System.assertEquals(replacedTest.contains('{{$timestamp}}'), false);

    }

    /**
    * @description testIsNull - 
    */
    private static testmethod void testIsNull() {
        Test.startTest();
        String textResult1 = IntacctUtils.IsNull('', 'default');
        String textResult2 = IntacctUtils.IsNull('notBlank', '');
        String textResult3 = IntacctUtils.IsNull('', '');
        String textResult4 = IntacctUtils.IsNull(null, null);
        Test.stopTest();

        System.assertEquals('default', textResult1);
        System.assertEquals('notBlank', textResult2);
        System.assertEquals(true, String.IsBlank(textResult3));
        System.assertEquals(null, textResult4);
    }

    /**
    * @description testCleanHtmlText - 
    */
    private static testmethod void testCleanHtmlText() {
        Test.startTest();
        String textResult = IntacctUtils.cleanHtmlText('AA &bull; AA');
        Test.stopTest();

        System.assertEquals('AA - AA', textResult);
    }

    /**
    * @description testFormatDate - 
    */
    private static testmethod void testFormatDate() {
        Date testDate = DateTime.now().date();

        Test.startTest();
        String formattedDate = IntacctUtils.formatDate(testDate);
        Test.stopTest();

        String expectedValue = String.valueOf(testDate.month()).leftPad(2, '0') + '/' + String.valueOf(testDate.day()).leftPad(2, '0') + '/' + String.valueOf(testDate.year());
        System.assertEquals(expectedValue, formattedDate);
    }


}