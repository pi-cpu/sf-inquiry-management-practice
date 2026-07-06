public with sharing class CaseSlaDashboardController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getOpenCasesWithSla() {
        return [
            SELECT Id, CaseNumber, Subject, Priority, Status,
                   Inquiry_Category__r.Name, SLA_Due_Date__c,
                   Is_SLA_Breached__c, Is_Escalated__c, Owner.Name
            FROM Case
            WHERE IsClosed = false
            ORDER BY SLA_Due_Date__c ASC NULLS LAST
            LIMIT 200
        ];
    }

    @AuraEnabled
    public static Case escalateCase(Id caseId, String reason) {
        try {
            Case c = [SELECT Id, OwnerId, Is_Escalated__c FROM Case WHERE Id = :caseId LIMIT 1];
            List<Case> casesToEscalate = new List<Case>{ c };
            EscalationService.escalateCases(casesToEscalate, reason);
            update c;

            return [
                SELECT Id, CaseNumber, Subject, Priority, Status,
                       Inquiry_Category__r.Name, SLA_Due_Date__c,
                       Is_SLA_Breached__c, Is_Escalated__c, Owner.Name
                FROM Case
                WHERE Id = :caseId
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
