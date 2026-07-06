@isTest
private class CaseSlaDashboardControllerTest {
    @isTest
    static void testGetOpenCasesWithSlaOrdersByDueDateAscending() {
        Inquiry_Category__c category = TestDataFactory.createInquiryCategory('ダッシュボードテスト種別');
        TestDataFactory.createSlaTarget(category.Id, 'High', 4);
        TestDataFactory.createSlaTarget(category.Id, 'Low', 48);

        Case soonDue = TestDataFactory.createCase('急ぎ', 'High', category.Id);
        Case laterDue = TestDataFactory.createCase('あとで', 'Low', category.Id);

        Test.startTest();
        List<Case> results = CaseSlaDashboardController.getOpenCasesWithSla();
        Test.stopTest();

        System.assertEquals(2, results.size());
        System.assertEquals(soonDue.Id, results[0].Id);
    }

    @isTest
    static void testEscalateCaseSuccessPath() {
        Inquiry_Category__c category = TestDataFactory.createInquiryCategory('手動エスカレーションテスト種別');
        Case c = TestDataFactory.createCase('手動エスカレーション対象', 'High', category.Id);

        Test.startTest();
        Case result = CaseSlaDashboardController.escalateCase(c.Id, '手動エスカレーション理由');
        Test.stopTest();

        System.assertEquals(true, result.Is_Escalated__c);
    }

    @isTest
    static void testEscalateCaseInvalidIdThrowsException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            CaseSlaDashboardController.escalateCase(null, '理由');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }
}
