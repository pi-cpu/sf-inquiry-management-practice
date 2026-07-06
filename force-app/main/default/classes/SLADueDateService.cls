public with sharing class SLADueDateService {
    public static final Decimal DEFAULT_TARGET_HOURS = 24;

    public static void calculateForCases(List<Case> cases) {
        Set<Id> categoryIds = new Set<Id>();
        Set<String> priorities = new Set<String>();
        for (Case c : cases) {
            if (c.Inquiry_Category__c != null) {
                categoryIds.add(c.Inquiry_Category__c);
            }
            if (c.Priority != null) {
                priorities.add(c.Priority);
            }
        }

        Map<String, Decimal> targetHoursByKey = new Map<String, Decimal>();
        if (!categoryIds.isEmpty() && !priorities.isEmpty()) {
            for (SLA_Target__c target : [
                SELECT Inquiry_Category__c, Priority__c, Target_Hours__c
                FROM SLA_Target__c
                WHERE Inquiry_Category__c IN :categoryIds AND Priority__c IN :priorities
            ]) {
                targetHoursByKey.put(buildKey(target.Inquiry_Category__c, target.Priority__c), target.Target_Hours__c);
            }
        }

        Id defaultBusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;

        for (Case c : cases) {
            Decimal targetHours = targetHoursByKey.get(buildKey(c.Inquiry_Category__c, c.Priority));
            if (targetHours == null) {
                targetHours = DEFAULT_TARGET_HOURS;
            }
            c.SLA_Target_Hours__c = targetHours;

            Datetime startDateTime = (c.CreatedDate != null) ? c.CreatedDate : Datetime.now();
            Long targetMillis = (targetHours * 3600000).longValue();
            c.SLA_Due_Date__c = BusinessHours.add(defaultBusinessHoursId, startDateTime, targetMillis);
        }
    }

    private static String buildKey(Id categoryId, String priority) {
        return String.valueOf(categoryId) + '|' + priority;
    }
}
