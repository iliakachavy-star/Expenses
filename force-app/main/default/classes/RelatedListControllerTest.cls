@isTest
private with sharing class RelatedListControllerTest {
    @isTest
    private static void testGet() {
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;
        
        Contact contact1 = new Contact(LastName='Contact 1', AccountId=testAccount.Id);
        Contact contact2 = new Contact(LastName='Contact 2', AccountId=testAccount.Id);
        insert new List<Contact>{contact1, contact2};
        
        Test.startTest();
        List<Contact> contacts = RelatedListController.getContacts(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals(2, contacts.size());
        System.assertEquals('Contact 1', contacts[0].Name);
        System.assertEquals('Contact 2', contacts[1].Name);
        
    }
}