@isTest
private class ExpenseCardTriggerHandlerTest {
    
    @isTest
    private static void testAssignME() {
        ExpenseCard__c card = new ExpenseCard__c(Amount__c = 120,CardDate__c = Date.newInstance(2026, 5, 12),Description__c = 'Trigger insert test');
        
        Test.startTest();
        insert card;
        Test.stopTest();
        
        ExpenseCard__c savedCard = [
            SELECT CardKeeper__c, MonthlyExpense__c, MonthlyExpense__r.Keeper__c, MonthlyExpense__r.MonthDate__c
            FROM ExpenseCard__c
            WHERE Id = :card.Id
        ];
        
        System.assertNotEquals(null, savedCard.MonthlyExpense__c);
    }
    
    @isTest
    private static void testCardsSameME() {
        List<ExpenseCard__c> cards = new List<ExpenseCard__c>{
            new ExpenseCard__c(
                Amount__c = 10,
            CardDate__c = Date.newInstance(2026, 5, 1),
            Description__c = 'First card'),
            
            new ExpenseCard__c(
                Amount__c = 20,
            CardDate__c = Date.newInstance(2026, 5, 31),
            Description__c = 'Second card')
                
        };
        
        Test.startTest();
        insert cards;
        Test.stopTest();
        
        
        List<ExpenseCard__c> savedCards = [
            SELECT MonthlyExpense__c
            FROM ExpenseCard__c
            WHERE Id IN :cards
            ORDER BY CardDate__c
        ];
        
        System.assertEquals(savedCards[0].MonthlyExpense__c,savedCards[1].MonthlyExpense__c);
    }
    
    @isTest
    private static void testUpdateCardToNewME() {
        
        ExpenseCard__c card = new ExpenseCard__c(Amount__c = 45,CardDate__c = Date.newInstance(2026, 5, 13),Description__c = 'Before month change');
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
        
        System.assertNotEquals(originalMonthlyExpenseId, updatedCard.MonthlyExpense__c);
        System.assertEquals(Date.newInstance(2026, 6, 1), updatedCard.MonthlyExpense__r.MonthDate__c);
    }
}