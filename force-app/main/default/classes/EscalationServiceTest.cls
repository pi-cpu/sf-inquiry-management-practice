@isTest
private class EscalationServiceTest {
    @isTest
    static void testSetsEscalationFields() {
        Inquiry_Category__c category = TestDataFactory.createInquiryCategory('エスカレーションテスト種別');
        Case c = TestDataFactory.createCase('テスト', 'High', category.Id);
        List<Case> cases = new List<Case>{ c };

        Test.startTest();
        EscalationService.escalateCases(cases, 'テスト理由');
        Test.stopTest();

        System.assertEquals(true, cases[0].Is_Escalated__c);
        System.assertEquals('テスト理由', cases[0].Escalation_Reason__c);
        System.assertNotEquals(null, cases[0].Escalated_Date__c);
    }

    @isTest
    static void testHandlesOwnerWithoutManagerGracefully() {
        Inquiry_Category__c category = TestDataFactory.createInquiryCategory('担当者上司なしテスト種別');
        Case c = TestDataFactory.createCase('テスト', 'High', category.Id);
        List<Case> cases = new List<Case>{ c };

        Test.startTest();
        EscalationService.escalateCases(cases, 'テスト理由2');
        Test.stopTest();

        System.assertEquals(true, cases[0].Is_Escalated__c);
    }
}
