@isTest
private with sharing class RelatedListContollerTest {
    @isTest
    private static void testGetContacts() {
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;
        
        Contact contact1 = new Contact(FirstName='Ilia', LastName='Topuria', AccountId=testAccount.Id);
        Contact contact2 = new Contact(FirstName='Justin', LastName='Gaethje', AccountId=testAccount.Id);
        insert new List<Contact>{contact1, contact2};
        
        Test.startTest();
        List<Contact> contacts = RelatedListController.getContacts(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals(2, contacts.size());
        System.assertEquals('Ilia', contacts[0].FirstName);
        System.assertEquals('Justin', contacts[1].FirstName);
        System.assertEquals('Topuria', contacts[0].LastName);
        System.assertEquals('Gaethje', contacts[1].LastName);
        System.assertEquals(testAccount.Id, contacts[0].AccountId);
        System.assertEquals(testAccount.Id, contacts[1].AccountId);
        
        
    }
}