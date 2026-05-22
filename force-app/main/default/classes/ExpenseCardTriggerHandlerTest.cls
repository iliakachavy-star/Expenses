@isTest
private class ExpenseCardTriggerHandlerTest {

    @isTest
    private static void testInsertCreatesAndAssignsMonthlyExpense() {
        ExpenseCard__c card = new ExpenseCard__c(
            Amount__c = 120,
            CardDate__c = Date.newInstance(2026, 5, 12),
            Description__c = 'Trigger insert test'
        );

        Test.startTest();
        insert card;
        Test.stopTest();

        ExpenseCard__c savedCard = [
            SELECT CardKeeper__c, MonthlyExpense__c, MonthlyExpense__r.Keeper__c, MonthlyExpense__r.MonthDate__c
            FROM ExpenseCard__c
            WHERE Id = :card.Id
        ];

        System.assertEquals(UserInfo.getUserId(), savedCard.CardKeeper__c, 'Trigger should default the keeper to the current user.');
        System.assertNotEquals(null, savedCard.MonthlyExpense__c, 'Trigger should assign a monthly expense.');
        System.assertEquals(UserInfo.getUserId(), savedCard.MonthlyExpense__r.Keeper__c, 'Monthly expense should belong to the keeper.');
        System.assertEquals(Date.newInstance(2026, 5, 1), savedCard.MonthlyExpense__r.MonthDate__c, 'Monthly expense should use the first day of the card month.');
    }

    @isTest
    private static void testCardsInSameMonthShareMonthlyExpense() {
        List<ExpenseCard__c> cards = new List<ExpenseCard__c>{
            new ExpenseCard__c(
                Amount__c = 10,
                CardDate__c = Date.newInstance(2026, 5, 1),
                Description__c = 'First card'
            ),
            new ExpenseCard__c(
                Amount__c = 20,
                CardDate__c = Date.newInstance(2026, 5, 31),
                Description__c = 'Second card'
            )
        };

        Test.startTest();
        insert cards;
        Test.stopTest();

        Set<Id> cardIds = new Map<Id, ExpenseCard__c>(cards).keySet();

        List<ExpenseCard__c> savedCards = [
            SELECT MonthlyExpense__c
            FROM ExpenseCard__c
            WHERE Id IN :cardIds
            ORDER BY Amount__c
        ];

        System.assertEquals(
            savedCards[0].MonthlyExpense__c,
            savedCards[1].MonthlyExpense__c,
            'Cards for the same keeper and month should share one monthly expense.'
        );
    }

    @isTest
    private static void testUpdateMovesCardToNewMonthlyExpense() {
        ExpenseCard__c card = new ExpenseCard__c(
            Amount__c = 45,
            CardDate__c = Date.newInstance(2026, 5, 14),
            Description__c = 'Before month change'
        );
        insert card;

        Id originalMonthlyExpenseId = [
            SELECT MonthlyExpense__c
            FROM ExpenseCard__c
            WHERE Id = :card.Id
        ].MonthlyExpense__c;

        card.CardDate__c = Date.newInstance(2026, 6, 14);

        Test.startTest();
        update card;
        Test.stopTest();

        ExpenseCard__c updatedCard = [
            SELECT MonthlyExpense__c, MonthlyExpense__r.MonthDate__c
            FROM ExpenseCard__c
            WHERE Id = :card.Id
        ];

        System.assertNotEquals(originalMonthlyExpenseId, updatedCard.MonthlyExpense__c, 'Changing month should assign another monthly expense.');
        System.assertEquals(Date.newInstance(2026, 6, 1), updatedCard.MonthlyExpense__r.MonthDate__c, 'New monthly expense should match the updated month.');
    }

    @isTest
    private static void testInsertRequiresCardDate() {
        ExpenseCard__c card = new ExpenseCard__c(
            Amount__c = 15,
            Description__c = 'Missing date'
        );

        try {
            insert card;
            System.assert(false, 'Expected insert to fail when CardDate__c is missing.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Card Date is required.'), 'Error should explain that card date is required.');
        }
    }
}
