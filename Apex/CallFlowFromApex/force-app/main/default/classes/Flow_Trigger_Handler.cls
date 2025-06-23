public with sharing class Flow_Trigger_Handler {
    public static void callFlow(List<ContentVersion> newVersions) {
        for (ContentVersion cv : newVersions) {
            Map<String, Object> flowInputs = new Map<String, Object>();
            flowInputs.put('varT_ContentVersionId', cv.Id); // Match this to your Flow input variable

            Flow.Interview.Get_Image_URL_ContentVersion flow = new Flow.Interview.Get_Image_URL_ContentVersion(flowInputs);
            flow.start();
        }
    }
}
