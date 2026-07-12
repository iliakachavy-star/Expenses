import { LightningElement, api, wire } from 'lwc';
import getContacts from '@salesforce/apex/RelatedListController.getContacts';

const COLUMNS = [
    { label: 'Name', fieldApiName: 'Name', fieldType: 'text' },
    { label: 'Email', fieldApiName: 'Email', fieldType: 'email' },
    { label: 'Phone', fieldApiName: 'Phone', fieldType: 'phone' },
    { label: 'Title', fieldApiName: 'Title', fieldType: 'text' }
];

export default class RelatedList extends LightningElement {
    @api recordId;

    contacts = [];
    columns = COLUMNS;
    isLoading = true;

    @wire(getContacts, { accountID: '$recordId' })
    wiredContacts({ data, error }) {
        if (data) {
            this.contacts = data;
        } else if (error) {
            this.contacts = [];
            console.error(error);
        }

        this.isLoading = false;
    }
}
