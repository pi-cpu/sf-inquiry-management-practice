public with sharing class CaseTriggerHandler {
    public static void handleBeforeInsert(List<Case> newCases) {
        SLADueDateService.calculateForCases(newCases);
    }

    public static void handleBeforeUpdate(List<Case> newCases, Map<Id, Case> oldCasesById) {
        List<Case> casesNeedingRecalculation = new List<Case>();
        for (Case c : newCases) {
            Case oldCase = oldCasesById.get(c.Id);
            if (c.Inquiry_Category__c != oldCase.Inquiry_Category__c || c.Priority != oldCase.Priority) {
                casesNeedingRecalculation.add(c);
            }
        }
        if (!casesNeedingRecalculation.isEmpty()) {
            SLADueDateService.calculateForCases(casesNeedingRecalculation);
        }
    }
}
