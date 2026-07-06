public with sharing class CaseEscalationBatch implements Database.Batchable<sObject>, Schedulable {
    public static final String AUTO_ESCALATION_REASON = '自動エスカレーション：SLA超過';

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, OwnerId, Is_Escalated__c, Is_SLA_Breached__c
            FROM Case
            WHERE IsClosed = false
              AND SLA_Due_Date__c < :Datetime.now()
              AND Is_Escalated__c = false
        ]);
    }

    public void execute(Database.BatchableContext context, List<Case> scope) {
        for (Case c : scope) {
            c.Is_SLA_Breached__c = true;
        }
        EscalationService.escalateCases(scope, AUTO_ESCALATION_REASON);
        update scope;
    }

    public void finish(Database.BatchableContext context) {
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new CaseEscalationBatch());
    }
}
