@isTest
private class CaseTriggerHandlerTest {
    @isTest
    static void testDoesNotRecalculateWhenUnrelatedFieldChanges() {
        Inquiry_Category__c category = TestDataFactory.createInquiryCategory('契約関連テスト');
        TestDataFactory.createSlaTarget(category.Id, 'Medium', 24);
        TestDataFactory.createSlaTarget(category.Id, 'High', 4);

        Case c = TestDataFactory.createCase('テスト', 'Medium', category.Id);
        Datetime originalDueDate = [SELECT SLA_Due_Date__c FROM Case WHERE Id = :c.Id].SLA_Due_Date__c;

        Test.startTest();
        c.Subject = '件名変更のみ';
        update c;
        Test.stopTest();

        Datetime unchangedDueDate = [SELECT SLA_Due_Date__c FROM Case WHERE Id = :c.Id].SLA_Due_Date__c;
        System.assertEquals(originalDueDate, unchangedDueDate);
    }

    @isTest
    static void testRecalculatesWhenPriorityChanges() {
        Inquiry_Category__c category = TestDataFactory.createInquiryCategory('クレームテスト');
        TestDataFactory.createSlaTarget(category.Id, 'Medium', 24);
        TestDataFactory.createSlaTarget(category.Id, 'High', 2);

        Case c = TestDataFactory.createCase('テスト', 'Medium', category.Id);

        Test.startTest();
        c.Priority = 'High';
        update c;
        Test.stopTest();

        Case result = [SELECT SLA_Target_Hours__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(2, result.SLA_Target_Hours__c);
    }

    @isTest
    static void testBulkInsertOf200Cases() {
        Inquiry_Category__c category = TestDataFactory.createInquiryCategory('バルクテスト種別');
        TestDataFactory.createSlaTarget(category.Id, 'Low', 48);

        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            cases.add(new Case(Subject = 'バルク' + i, Priority = 'Low', Inquiry_Category__c = category.Id, Status = 'New'));
        }

        Test.startTest();
        insert cases;
        Test.stopTest();

        Integer countWithDueDate = [SELECT COUNT() FROM Case WHERE Id IN :cases AND SLA_Due_Date__c != null];
        System.assertEquals(200, countWithDueDate);
    }
}
