public with sharing class ExpenseAppController {

    public class ExpenseDto {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Date cardDate;
        @AuraEnabled public String description;
    } // для передачи на фронтенд

    @AuraEnabled
    public static List<ExpenseDto> getExpenses(Integer yearValue, Integer monthValue) {
        Date todayDate = Date.today();

        Integer targetYear = yearValue == null ? todayDate.year() : yearValue;
        Integer targetMonth = monthValue == null ? todayDate.month() : monthValue;

        if (targetMonth < 1 || targetMonth > 12) {
            throw new AuraHandledException('Invalid month value.');
        }

        Date startDate = Date.newInstance(targetYear, targetMonth, 1); //первое число нужного мес
        Date endDate = startDate.addMonths(1); //первое на след мес

        Id currentUserId = UserInfo.getUserId();

        List<ExpenseDto> result = new List<ExpenseDto>(); 

        List<ExpenseCard__c> cards = [
            SELECT Id, Name, Amount__c, CardDate__c, Description__c
            FROM ExpenseCard__c
            WHERE CardKeeper__c = :currentUserId
            AND CardDate__c >= :startDate
            AND CardDate__c < :endDate
            ORDER BY CardDate__c ASC, CreatedDate ASC
        ];

        for (ExpenseCard__c card : cards) {
            result.add(toDto(card));
        }

        return result;
    }

    @AuraEnabled
    public static ExpenseDto createExpense(
        Decimal amount,
        Date cardDate,
        String description
    ) {
        validateExpenseInput(amount, cardDate);

        ExpenseCard__c card = new ExpenseCard__c();
        card.Amount__c = amount;
        card.CardDate__c = cardDate;
        card.Description__c = description;
        card.CardKeeper__c = UserInfo.getUserId();

        insert card;

        ExpenseCard__c insertedCard = [
            SELECT Id, Name, Amount__c, CardDate__c, Description__c
            FROM ExpenseCard__c
            WHERE Id = :card.Id
            LIMIT 1
        ];

        return toDto(insertedCard);
    }

    @AuraEnabled
    public static ExpenseDto updateExpense(
        Id expenseId,
        Decimal amount,
        Date cardDate,
        String description
    ) {
        if (expenseId == null) {
            throw new AuraHandledException('Expense Id is required.');
        }

        validateExpenseInput(amount, cardDate);

        Id currentUserId = UserInfo.getUserId();

        List<ExpenseCard__c> cards = [
            SELECT Id, Name, Amount__c, CardDate__c, Description__c, CardKeeper__c
            FROM ExpenseCard__c
            WHERE Id = :expenseId
            AND CardKeeper__c = :currentUserId
            LIMIT 1
        ];

        if (cards.isEmpty()) {
            throw new AuraHandledException('Expense Card was not found or you do not have access.');
        }

        ExpenseCard__c card = cards[0];
        card.Amount__c = amount;
        card.CardDate__c = cardDate;
        card.Description__c = description;

        /*
         * Если CardDate__c поменяется на другой месяц,
         * trigger перепривяжет Expense Card к другому Monthly Expense.
         */
        update card;

        ExpenseCard__c updatedCard = [
            SELECT Id, Name, Amount__c, CardDate__c, Description__c
            FROM ExpenseCard__c
            WHERE Id = :card.Id
            LIMIT 1
        ];

        return toDto(updatedCard);
    }

    @AuraEnabled
    public static void deleteExpense(Id expenseId) {
        if (expenseId == null) {
            throw new AuraHandledException('Expense Id is required.');
        }

        Id currentUserId = UserInfo.getUserId();

        List<ExpenseCard__c> cards = [
            SELECT Id, CardKeeper__c
            FROM ExpenseCard__c
            WHERE Id = :expenseId
            AND CardKeeper__c = :currentUserId
            LIMIT 1
        ];
        if (cards.isEmpty()) {
            throw new AuraHandledException('Expense Card was not found or you do not have access.');
        }

        delete cards[0];
    }

    private static void validateExpenseInput(Decimal amount, Date cardDate) {
        if (amount == null) {
            throw new AuraHandledException('Amount is required.');
        }

        if (amount <= 0) {
            throw new AuraHandledException('Amount must be greater than 0.');
        }

        if (cardDate == null) {
            throw new AuraHandledException('Card Date is required.');
        }
    }

    private static ExpenseDto toDto(ExpenseCard__c card) {
        ExpenseDto dto = new ExpenseDto();
        dto.id = card.Id;
        dto.name = card.Name;
        dto.amount = card.Amount__c;
        dto.cardDate = card.CardDate__c;
        dto.description = card.Description__c;
        return dto;
    }
}