@isTest
private class ExpenseAppControllerTest {
    
    @isTest
    private static void testCreate() {
        Date expenseDate = Date.newInstance(2026, 5, 10);
        
        Test.startTest();
        ExpenseAppController.ExpenseDto dto = ExpenseAppController.createExpense(1500,expenseDate,'Test description');
        Test.stopTest();
        
        System.assertNotEquals(null, dto.id);
        System.assertEquals(1500, dto.amount);
        System.assertEquals(expenseDate, dto.cardDate);
        System.assertEquals('Test description', dto.description);
        
        ExpenseCard__c savedCard = [
            SELECT Amount__c, CardDate__c, Description__c, CardKeeper__c, MonthlyExpense__c
            FROM ExpenseCard__c
            WHERE Id = :dto.id
        ];
        
        System.assertEquals(UserInfo.getUserId(), savedCard.CardKeeper__c );
        System.assertNotEquals(null, savedCard.MonthlyExpense__c);
    }
    
    @isTest
    private static void testGet() {
        ExpenseAppController.createExpense(100, Date.newInstance(2026, 5, 3), 'May expense');
        ExpenseAppController.createExpense(200, Date.newInstance(2026, 6, 3), 'June expense');
        
        Test.startTest();
        List<ExpenseAppController.ExpenseDto> expenses = ExpenseAppController.getExpenses(2026, 5);
        Test.stopTest();
        
        System.assertEquals(1, expenses.size());
        System.assertEquals(100, expenses[0].amount);
        System.assertEquals(Date.newInstance(2026, 5, 3), expenses[0].cardDate);
        System.assertEquals('May expense', expenses[0].description);
    }
    
    @isTest
    private static void testUpdate() {
        ExpenseAppController.ExpenseDto origDto = ExpenseAppController.createExpense(100,Date.newInstance(2026, 5, 3),'Before update');
        
        Date updatedDate = Date.newInstance(2026, 6, 3);
        
        Test.startTest();
        ExpenseAppController.ExpenseDto updatedDto = ExpenseAppController.updateExpense(origDto.id, 200, updatedDate,'After update');
        Test.stopTest();
        
        System.assertEquals(origDto.id, updatedDto.id);
        System.assertEquals(200, updatedDto.amount);
        System.assertEquals(updatedDate, updatedDto.cardDate);
        System.assertEquals('After update', updatedDto.description);
    }
    
    @isTest
    private static void testDelete() {
        ExpenseAppController.ExpenseDto createdDto = ExpenseAppController.createExpense(100,Date.newInstance(2026, 5, 3),'Delete Expense');
        
        Test.startTest();
        ExpenseAppController.deleteExpense(createdDto.id);
        Test.stopTest();
        
        Integer cardCount = [
            SELECT COUNT()
            FROM ExpenseCard__c
            WHERE Id = :createdDto.id
        ];
        
        System.assertEquals(0, cardCount);
    }
}