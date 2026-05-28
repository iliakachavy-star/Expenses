public with sharing class RelatedListController {
    
    public static List<Contact> getContacts(Id accountID){
        return [
        SELECT Id, Name, Email, Phone, Title
        FROM Contact
        WHERE AccountId =: accountID
        ORDER BY Id
        ];
    }
}