import getExpenses from '@salesforce/apex/ExpenseAppController.getExpenses';
import { LightningElement } from 'lwc';

export default class RelatedList extends LightningElement {

    async loadExpenses() {

        try {
            this.expenses = await getExpenses({
                yearValue: this.selectedYear,
                monthValue: this.selectedMonth
            });
        } catch (error) {
            this.showError(error);
        }
    } 
}