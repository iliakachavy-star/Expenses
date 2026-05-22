@isTest
private class ExpenseAppControllerTest {

    @isTest
    private static void testCreateExpense() {
        Date expenseDate = Date.newInstance(2026, 5, 10);

        Test.startTest();
        ExpenseAppController.ExpenseDto dto = ExpenseAppController.createExpense(
            1500,
            expenseDate,
            'Test description'
        );
        Test.stopTest();

        System.assertNotEquals(null, dto.id, 'Created expense should have an Id.');
        System.assertEquals(1500, dto.amount, 'DTO should contain the saved amount.');
        System.assertEquals(expenseDate, dto.cardDate, 'DTO should contain the saved date.');
        System.assertEquals('Test description', dto.description, 'DTO should contain the saved description.');

        ExpenseCard__c savedCard = [
            SELECT Amount__c, CardDate__c, Description__c, CardKeeper__c, MonthlyExpense__c
            FROM ExpenseCard__c
            WHERE Id = :dto.id
        ];

        System.assertEquals(UserInfo.getUserId(), savedCard.CardKeeper__c, 'Current user should be the card keeper.');
        System.assertNotEquals(null, savedCard.MonthlyExpense__c, 'Trigger should connect the card to a monthly expense.');
    }

    @isTest
    private static void testGetExpensesForMonth() {
        ExpenseAppController.createExpense(100, Date.newInstance(2026, 5, 3), 'May expense');
        ExpenseAppController.createExpense(200, Date.newInstance(2026, 6, 3), 'June expense');

        Test.startTest();
        List<ExpenseAppController.ExpenseDto> expenses = ExpenseAppController.getExpenses(2026, 5);
        Test.stopTest();

        System.assertEquals(1, expenses.size(), 'Only May expenses should be returned.');
        System.assertEquals(100, expenses[0].amount, 'The returned expense should be the May expense.');
        System.assertEquals(Date.newInstance(2026, 5, 3), expenses[0].cardDate, 'The returned expense should have the May date.');
    }

    @isTest
    private static void testUpdateExpense() {
        ExpenseAppController.ExpenseDto createdDto = ExpenseAppController.createExpense(
            50,
            Date.newInstance(2026, 5, 15),
            'Before update'
        );

        Date updatedDate = Date.newInstance(2026, 6, 20);

        Test.startTest();
        ExpenseAppController.ExpenseDto updatedDto = ExpenseAppController.updateExpense(
            createdDto.id,
            75,
            updatedDate,
            'After update'
        );
        Test.stopTest();

        System.assertEquals(createdDto.id, updatedDto.id, 'Update should return the same expense.');
        System.assertEquals(75, updatedDto.amount, 'Amount should be updated.');
        System.assertEquals(updatedDate, updatedDto.cardDate, 'Date should be updated.');
        System.assertEquals('After update', updatedDto.description, 'Description should be updated.');
    }

    @isTest
    private static void testDeleteExpense() {
        ExpenseAppController.ExpenseDto createdDto = ExpenseAppController.createExpense(
            25,
            Date.newInstance(2026, 5, 8),
            'Delete me'
        );

        Test.startTest();
        ExpenseAppController.deleteExpense(createdDto.id);
        Test.stopTest();

        Integer cardCount = [
            SELECT COUNT()
            FROM ExpenseCard__c
            WHERE Id = :createdDto.id
        ];

        System.assertEquals(0, cardCount, 'Expense should be deleted.');
    }

    @isTest
    private static void testCreateExpenseRequiresPositiveAmount() {
        try {
            ExpenseAppController.createExpense(0, Date.newInstance(2026, 5, 10), 'Invalid amount');
            System.assert(false, 'Expected an exception for amount equal to zero.');
        } catch (AuraHandledException e) {
            System.assert(true, 'Expected validation exception was thrown.');
        }
    }

    @isTest
    private static void testGetExpensesRejectsInvalidMonth() {
        try {
            ExpenseAppController.getExpenses(2026, 13);
            System.assert(false, 'Expected an exception for invalid month.');
        } catch (AuraHandledException e) {
            System.assert(true, 'Expected validation exception was thrown.');
        }
    }
}
