@isTest
private class CaseEscalationBatchTest {
    @isTest
    static void testBatchEscalatesOverdueOpenCases() {
        Inquiry_Category__c category = TestDataFactory.createInquiryCategory('バッチテスト種別');
        TestDataFactory.createSlaTarget(category.Id, 'High', 4);

        Case overdueCase = TestDataFactory.createCase('期限切れテスト', 'High', category.Id);
        overdueCase.SLA_Due_Date__c = Datetime.now().addDays(-1);
        update overdueCase;

        Test.startTest();
        Database.executeBatch(new CaseEscalationBatch());
        Test.stopTest();

        Case result = [SELECT Is_SLA_Breached__c, Is_Escalated__c, Escalation_Reason__c FROM Case WHERE Id = :overdueCase.Id];
        System.assertEquals(true, result.Is_SLA_Breached__c);
        System.assertEquals(true, result.Is_Escalated__c);
        System.assertEquals(CaseEscalationBatch.AUTO_ESCALATION_REASON, result.Escalation_Reason__c);
    }

    @isTest
    static void testScheduledExecutionEnqueuesBatch() {
        Test.startTest();
        String jobId = System.schedule('SLA超過エスカレーションバッチ_テスト', '0 0 1 * * ?', new CaseEscalationBatch());
        Test.stopTest();

        System.assertNotEquals(null, jobId);
    }
}
