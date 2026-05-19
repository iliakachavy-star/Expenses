trigger ExpenseCardTrigger on ExpenseCard__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ExpenseCardTriggerHandler.beforeInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            ExpenseCardTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}