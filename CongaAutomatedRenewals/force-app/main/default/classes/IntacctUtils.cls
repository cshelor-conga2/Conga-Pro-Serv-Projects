/**
* @author Systemyc, Giovanni Modica - giovanni.modica@getconga.com
* @date 20180710
* @version 1.0
* @description IntacctUtils - 
*/
public class IntacctUtils {

    /**
    * @description replaceVariables - 
    * @param String text
    * @return String
    */
    public static String replaceVariables(String text) {
        text = text.replace('{{$guid}}', IntacctUtils.getGuid());
        text = text.replace('{{$timestamp}}', IntacctUtils.getTimestamp());
        return text;
    }
    
    /**
    * @description isNull - 
    * @param String text
    * @param String defaultText    
    * @return String
    */
    public static String isNull(String text, String defaultText) {
        if(String.isBlank(text)) return defaultText;
        return text;
    }
    
    /**
    * @description formatDate - 
    * @param Date theDate
    * @return String
    */
    public static String formatDate(Date theDate) {
        if(theDate == null) return null;
        return String.format('{1}/{2}/{0}', new String[] { String.valueOf(theDate.year()), String.valueOf(theDate.month()).leftPad(2,'0'), String.valueOf(theDate.day()).leftPad(2,'0') });
    }

    /**
    * @description cleanHtmlText - 
    * @param String text
    * @return String
    */
    public static String cleanHtmlText(String text) {
        if(String.isBlank(text)) return text;
        return text.replace('&rdquo;','"').replace('&ldquo;','"').replace('&bull;','-').replace('&ndash;','-').replace('&lsquo;','\'').replace('&rsquo;','\'');
    }

    /**
    * @description getTimestamp - 
    * @return String
    */
    public static String getTimestamp() {        
        return String.valueOf(DateTime.now().getTime());
    }
        
    private static String kHexChars = '0123456789abcdef';
    /**
    * @description getGuid - 
    * @return String
    */
    public static String getGuid() {
        String returnValue = '';
        Integer nextByte = 0;

        for(Integer i=0; i<16; i++) {

            if(i==4 || i==6 || i==8 || i==10) 
                returnValue += '-';

            nextByte = (Math.round(Math.random() * 255)-128) & 255;

            if(i==6) {
                nextByte = nextByte & 15;
                nextByte = nextByte | (4 << 4);
            }

            if(i==8) {
                nextByte = nextByte & 63;
                nextByte = nextByte | 128;
            }

            returnValue += getCharAtIndex(kHexChars, nextByte >> 4);
            returnValue += getCharAtIndex(kHexChars, nextByte & 15);
        }

        return returnValue;
    }

    /**
    * @description getCharAtIndex - 
    * @param String str
    * @param Integer index    
    * @return String
    */   
    private static String getCharAtIndex(String str, Integer index) {
        if (str == null) return null;
        if (str.length() <= 0) return str;    
        if (index == str.length()) return null;    
        return str.substring(index, index+1);
    }


}