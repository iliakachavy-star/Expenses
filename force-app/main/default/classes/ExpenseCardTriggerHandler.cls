public without sharing class ExpenseCardTriggerHandler {
    

    public static void beforeInsert(List<ExpenseCard__c> newCards) {
        assignMonthlyExpenses(newCards, null, true);
    }

    public static void beforeUpdate(
        List<ExpenseCard__c> newCards,
        Map<Id, ExpenseCard__c> oldMap
    ) {
        assignMonthlyExpenses(newCards, oldMap, false);
    }

    private static void assignMonthlyExpenses(
        List<ExpenseCard__c> cards, // записи для обработки
        Map<Id, ExpenseCard__c> oldMap, // старые версии 
        Boolean isInsert //флаг вставки
    ) {
        List<ExpenseCard__c> cardsToProcess = new List<ExpenseCard__c>(); // карточки из cards (некоторые не надо будет обрабатывать фактически)

        Set<Id> keeperIds = new Set<Id>(); //чтобы без дубликатов
        Set<Date> monthDates = new Set<Date>();

        for (ExpenseCard__c card : cards) {
            
        //валидация
            if (card.CardKeeper__c == null) {
                card.CardKeeper__c = UserInfo.getUserId();
            }

            if (card.CardDate__c == null) {
                card.addError('Card Date is required.');
                continue;
            }

            if (card.CardKeeper__c == null) {
                card.addError('Card Keeper is required.');
                continue;
            }

            Boolean shouldProcess = isInsert; // при вставке всегда обрабатывать

            if (!isInsert) {
                ExpenseCard__c oldCard = oldMap.get(card.Id);

                Boolean dateChanged = card.CardDate__c != oldCard.CardDate__c;
                Boolean keeperChanged = card.CardKeeper__c != oldCard.CardKeeper__c;
                Boolean monthlyExpenseEmpty = card.MonthlyExpense__c == null;

                shouldProcess = dateChanged || keeperChanged || monthlyExpenseEmpty;
                //есть ли смысл обновлять
            }

            if (shouldProcess) {
                Date monthDate = getFirstDayOfMonth(card.CardDate__c);

                cardsToProcess.add(card);
                keeperIds.add(card.CardKeeper__c);
                monthDates.add(monthDate);
            }
        }

        if (cardsToProcess.isEmpty()) {
            return;
        }

        /*
            ищем Monthly Expense по:
         * Keeper__c + MonthDate__c.
         */
        Map<String, MonthlyExpense__c> monthlyByKey = new Map<String, MonthlyExpense__c>();
            //ключ KeeperID_MonthDate
        for (MonthlyExpense__c monthly : [
            SELECT Id, Keeper__c, MonthDate__c
            FROM MonthlyExpense__c
            WHERE Keeper__c IN :keeperIds
            AND MonthDate__c IN :monthDates
            ORDER BY CreatedDate ASC
        ]) {
           
            String key = buildKey(monthly.Keeper__c, monthly.MonthDate__c);

            
            if (!monthlyByKey.containsKey(key)) {
                monthlyByKey.put(key, monthly);
            }
        } //существующие экспенсы 

        List<MonthlyExpense__c> monthlyToInsert = new List<MonthlyExpense__c>();

        for (ExpenseCard__c card : cardsToProcess) {
            Date monthDate = getFirstDayOfMonth(card.CardDate__c);
            String key = buildKey(card.CardKeeper__c, monthDate);

            if (!monthlyByKey.containsKey(key)) {
                MonthlyExpense__c monthly = new MonthlyExpense__c();
                monthly.Keeper__c = card.CardKeeper__c;
                monthly.OwnerId = card.CardKeeper__c;
                monthly.MonthDate__c = monthDate;
                monthly.Balance__c = 0;

                monthlyByKey.put(key, monthly);
                monthlyToInsert.add(monthly); // создание необходимых
            }
        }

        if (!monthlyToInsert.isEmpty()) {
            insert monthlyToInsert;
        }

        for (ExpenseCard__c card : cardsToProcess) {
            Date monthDate = getFirstDayOfMonth(card.CardDate__c);
            String key = buildKey(card.CardKeeper__c, monthDate);

            MonthlyExpense__c monthly = monthlyByKey.get(key);

            if (monthly == null || monthly.Id == null) {
                card.addError('Monthly Expense could not be created or found.');
            } else {
                card.MonthlyExpense__c = monthly.Id;
            }
        } // привязка карточки к экспенсу
    }

    private static Date getFirstDayOfMonth(Date sourceDate) {
        return Date.newInstance(sourceDate.year(), sourceDate.month(), 1);
    }

    private static String buildKey(Id keeperId, Date monthDate) {
        return String.valueOf(keeperId) + '_' + String.valueOf(monthDate);
    }
}