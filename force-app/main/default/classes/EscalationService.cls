public with sharing class EscalationService {
    public static void escalateCases(List<Case> cases, String reason) {
        Set<Id> ownerIds = new Set<Id>();
        for (Case c : cases) {
            if (c.OwnerId != null) {
                ownerIds.add(c.OwnerId);
            }
        }

        Map<Id, Id> managerIdByOwnerId = new Map<Id, Id>();
        if (!ownerIds.isEmpty()) {
            for (User u : [SELECT Id, ManagerId FROM User WHERE Id IN :ownerIds]) {
                managerIdByOwnerId.put(u.Id, u.ManagerId);
            }
        }

        Datetime now = Datetime.now();
        for (Case c : cases) {
            c.Is_Escalated__c = true;
            c.Escalated_Date__c = now;
            c.Escalation_Reason__c = reason;
            Id managerId = managerIdByOwnerId.get(c.OwnerId);
            if (managerId != null) {
                c.Escalated_To__c = managerId;
            }
        }
    }
}
