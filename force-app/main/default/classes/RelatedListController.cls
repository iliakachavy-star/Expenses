public with sharing class RelatedListController {
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContacts(Id accountID){
        return [
        SELECT Id, Name, Email, Phone, Title
        FROM Contact
        WHERE AccountId =: accountID
        ORDER BY Id
        ];
    }
}
