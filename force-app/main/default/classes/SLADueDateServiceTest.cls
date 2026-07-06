@isTest
private class SLADueDateServiceTest {
    @isTest
    static void testCalculatesDueDateFromMatchingSlaTarget() {
        Inquiry_Category__c category = TestDataFactory.createInquiryCategory('製品不良テスト');
        TestDataFactory.createSlaTarget(category.Id, 'High', 4);

        Test.startTest();
        Case c = new Case(Subject = 'テスト問い合わせ', Priority = 'High', Inquiry_Category__c = category.Id, Status = 'New');
        insert c;
        Test.stopTest();

        Case result = [SELECT SLA_Target_Hours__c, SLA_Due_Date__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(4, result.SLA_Target_Hours__c);
        System.assertNotEquals(null, result.SLA_Due_Date__c);
    }

    @isTest
    static void testFallsBackToDefaultWhenNoMatchingSlaTarget() {
        Inquiry_Category__c category = TestDataFactory.createInquiryCategory('未設定種別テスト');

        Test.startTest();
        Case c = new Case(Subject = 'テスト問い合わせ', Priority = 'Low', Inquiry_Category__c = category.Id, Status = 'New');
        insert c;
        Test.stopTest();

        Case result = [SELECT SLA_Target_Hours__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(SLADueDateService.DEFAULT_TARGET_HOURS, result.SLA_Target_Hours__c);
    }
}
