@isTest
public class TestDataFactory {
    public static Inquiry_Category__c createInquiryCategory(String categoryName) {
        Inquiry_Category__c category = new Inquiry_Category__c(Name = categoryName, Active__c = true);
        insert category;
        return category;
    }

    public static SLA_Target__c createSlaTarget(Id categoryId, String priority, Decimal targetHours) {
        SLA_Target__c target = new SLA_Target__c(
            Inquiry_Category__c = categoryId,
            Priority__c = priority,
            Target_Hours__c = targetHours
        );
        insert target;
        return target;
    }

    public static Case createCase(String subject, String priority, Id categoryId) {
        Case c = new Case(
            Subject = subject,
            Priority = priority,
            Inquiry_Category__c = categoryId,
            Status = 'New'
        );
        insert c;
        return c;
    }
}
