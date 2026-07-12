import { LightningElement, api } from 'lwc';

export default class RelatedListCell extends LightningElement {
    @api record;
    @api column;

    get fieldValue() {
        return this.record[this.column.fieldApiName];
    }

    get isEmail() {
        return this.column.fieldType === 'email';
    }

    get isPhone() {
        return this.column.fieldType === 'phone';
    }

    get isText() {
        return this.column.fieldType === 'text';
    }
}
