import { LightningElement, api } from 'lwc';
import getContacts from '@salesforce/apex/RelatedListController.getContacts';

export default class RelatedList extends LightningElement {
    @api recordId;

    contacts = [];

    connectedCallback() {
        this.loadContacts();
    }

    async loadContacts() {
        try {
            this.contacts = await getContacts({
                accountID: this.recordId
            });
        } catch (error) {
            this.contacts = [];
            console.error(error);
        }
    }
}