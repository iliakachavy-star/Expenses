import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';

import getExpenses from '@salesforce/apex/ExpenseAppController.getExpenses';

import EXPENSE_OBJECT from '@salesforce/schema/ExpenseCard__c';
import AMOUNT_FIELD from '@salesforce/schema/ExpenseCard__c.Amount__c';
import CARD_DATE_FIELD from '@salesforce/schema/ExpenseCard__c.CardDate__c';
import DESCRIPTION_FIELD from '@salesforce/schema/ExpenseCard__c.Description__c';

const MONTHS = [
    { label: 'January', value: 1 },
    { label: 'February', value: 2 },
    { label: 'March', value: 3 },
    { label: 'April', value: 4 },
    { label: 'May', value: 5 },
    { label: 'June', value: 6 },
    { label: 'July', value: 7 },
    { label: 'August', value: 8 },
    { label: 'September', value: 9 },
    { label: 'October', value: 10 },
    { label: 'November', value: 11 },
    { label: 'December', value: 12 }
]; 

export default class ExpensePage extends LightningElement {
    expenseObject = EXPENSE_OBJECT;
    amountField = AMOUNT_FIELD;
    cardDateField = CARD_DATE_FIELD;
    descriptionField = DESCRIPTION_FIELD;

    expenses = []; //массив который из apex
    isLoading = false;

    isModalOpen = false;
    selectedRecordId = null; // id записи
    defaultCardDate = null; // дата
    

    selectedMonth = new Date().getMonth() + 1;
    selectedYear = new Date().getFullYear();

    connectedCallback() {
        this.loadExpenses();
    }
get isEditMode() {
    return this.selectedRecordId !== null;
}

get isCreateMode() {
    return this.selectedRecordId === null;
}
    get monthItems() {
        return MONTHS.map(month => {
            return {
                ...month,
                className:
                    month.value === this.selectedMonth
                        ? 'month-item active'
                        : 'month-item'
            };
        });
    }

    get yearItems() {
        const currentYear = new Date().getFullYear();

        const years = [
            currentYear - 2,
            currentYear - 1,
            currentYear,
            currentYear + 1,
            currentYear + 2
        ];

        return years.map(year => {
            return {
                label: String(year),
                value: year,
                className:
                    year === this.selectedYear
                        ? 'year-item active'
                        : 'year-item'
            };
        });
    }

    get hasExpenses() {
        return this.expenses.length > 0;
    }

    get modalTitle() {
        return this.selectedRecordId ? 'Edit Expense Card' : 'New Expense Card';
    }

    get groupedExpenses() {
        const groups = new Map();

        this.expenses.forEach(expense => {
            const dateKey = expense.cardDate;

            if (!groups.has(dateKey)) {
                groups.set(dateKey, {
                    dateKey,
                    dateLabel: this.formatDate(dateKey),
                    items: [],
                    total: 0
                });
            }

            const amount = Number(expense.amount || 0);

            groups.get(dateKey).items.push({
                id: expense.id,
                name: expense.name,
                description: expense.description || '',
                amount,
                amountLabel: this.formatAmount(amount)
            });

            groups.get(dateKey).total += amount;
        }); 

        return Array.from(groups.values()).map(group => {
            return {
                ...group,
                totalLabel: this.formatAmount(group.total)
            };
        });
    }// группирует записи по датам

    get activeSections() {
        if (this.groupedExpenses.length === 0) {
            return [];
        }

        return [this.groupedExpenses[0].dateKey];
    }

    async loadExpenses() {
        this.isLoading = true;

        try {
            this.expenses = await getExpenses({
                yearValue: this.selectedYear,
                monthValue: this.selectedMonth
            });
        } catch (error) {
            this.showError(error);
        } finally {
            this.isLoading = false;
        }
    } // загрузка записей

    handleMonthClick(event) {
        this.selectedMonth = Number(event.currentTarget.dataset.month);
        this.loadExpenses();
    }

    handleYearClick(event) {
        this.selectedYear = Number(event.currentTarget.dataset.year);
        this.loadExpenses();
    }

    openNewModal() {
        this.selectedRecordId = null;
        
        this.defaultCardDate = this.getTodayDate();
        this.isModalOpen = true;
    }

    openEditModal(event) {
        this.selectedRecordId = event.currentTarget.dataset.id;
        this.defaultCardDate = null;;
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        this.selectedRecordId = null;
        this.defaultCardDate = null;
    }


    async handleFormSuccess() {
        this.closeModal();

        this.showToast(
            'Success',
            this.selectedRecordId ? 'Expense Card was updated.' : 'Expense Card was saved.',
            'success'
        );

        await this.loadExpenses();
    }

    handleFormError(event) {
        let message = 'Record was not saved.';

        if (event.detail && event.detail.message) {
            message = event.detail.message;
        }

        this.showToast('Error', message, 'error');
    }

    async handleDelete(event) {
        const recordId = event.currentTarget.dataset.id;

        if (!confirm('Delete this Expense Card?')) {
            return;
        }

        this.isLoading = true;

        try {
            await deleteRecord(recordId);

            this.showToast('Success', 'Expense Card was deleted.', 'success');

            await this.loadExpenses();
        } catch (error) {
            this.showError(error);
        } finally {
            this.isLoading = false;
        }
    }

    formatDate(value) {
        if (!value) {
            return '';
        }

        const parts = value.split('-');

        if (parts.length !== 3) {
            return value;
        }

        return `${parts[2]}.${parts[1]}.${parts[0]}`;
    }

    formatAmount(value) {
        const amount = Number(value || 0);

        if (Number.isInteger(amount)) {
            return `${amount}$`;
        }

        return `${amount.toFixed(2)}$`;
    }

    getTodayDate() {
        const today = new Date();
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, '0');
        const day = String(today.getDate()).padStart(2, '0');

        return `${year}-${month}-${day}`;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    showError(error) {
        let message = 'Unexpected error.';

        if (error && error.body && error.body.message) {
            message = error.body.message;
        } else if (error && error.message) {
            message = error.message;
        }

        this.showToast('Error', message, 'error');
    }
}