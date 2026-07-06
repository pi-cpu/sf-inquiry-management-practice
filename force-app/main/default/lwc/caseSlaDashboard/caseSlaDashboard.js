import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpenCasesWithSla from '@salesforce/apex/CaseSlaDashboardController.getOpenCasesWithSla';
import escalateCase from '@salesforce/apex/CaseSlaDashboardController.escalateCase';

const COLUMNS = [
    { label: 'ケース番号', fieldName: 'CaseNumber', type: 'text' },
    { label: '件名', fieldName: 'Subject', type: 'text' },
    { label: '種別', fieldName: 'categoryName', type: 'text' },
    { label: '優先度', fieldName: 'Priority', type: 'text' },
    { label: '状況', fieldName: 'Status', type: 'text' },
    {
        label: 'SLA期限',
        fieldName: 'SLA_Due_Date__c',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    },
    {
        label: 'SLA状態',
        fieldName: 'slaStatusLabel',
        type: 'text',
        cellAttributes: { class: { fieldName: 'slaStatusClass' } }
    },
    { label: 'エスカレーション', fieldName: 'escalationStatusLabel', type: 'text' },
    {
        type: 'button',
        typeAttributes: {
            label: 'エスカレーション',
            name: 'escalate',
            variant: 'destructive',
            disabled: { fieldName: 'isEscalateDisabled' }
        }
    }
];

const WARNING_THRESHOLD_HOURS = 2;

export default class CaseSlaDashboard extends LightningElement {
    columns = COLUMNS;
    cases = [];
    wiredCasesResult;

    @wire(getOpenCasesWithSla)
    wiredCases(result) {
        this.wiredCasesResult = result;
        if (result.data) {
            this.cases = result.data.map((caseRecord) => this.decorateCase(caseRecord));
        } else if (result.error) {
            this.showToast('エラー', 'ケース一覧の取得に失敗しました。', 'error');
        }
    }

    decorateCase(caseRecord) {
        const now = new Date();
        const dueDate = caseRecord.SLA_Due_Date__c ? new Date(caseRecord.SLA_Due_Date__c) : null;
        const isBreached = caseRecord.Is_SLA_Breached__c || (dueDate && dueDate < now);

        let slaStatusLabel = '順調';
        let slaStatusClass = 'slds-text-color_success';
        if (isBreached) {
            slaStatusLabel = '超過';
            slaStatusClass = 'slds-text-color_error';
        } else if (dueDate) {
            const hoursRemaining = (dueDate.getTime() - now.getTime()) / (1000 * 60 * 60);
            if (hoursRemaining <= WARNING_THRESHOLD_HOURS) {
                slaStatusLabel = '警告';
                slaStatusClass = 'slds-text-color_warning';
            }
        }

        return {
            ...caseRecord,
            categoryName: caseRecord.Inquiry_Category__r ? caseRecord.Inquiry_Category__r.Name : '',
            slaStatusLabel,
            slaStatusClass,
            escalationStatusLabel: caseRecord.Is_Escalated__c ? 'エスカレーション済み' : '未対応',
            isEscalateDisabled: caseRecord.Is_Escalated__c
        };
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'escalate') {
            this.escalate(row.Id);
        }
    }

    escalate(caseId) {
        escalateCase({ caseId, reason: '手動エスカレーション（サポートエージェント操作）' })
            .then(() => {
                this.showToast('成功', 'ケースをエスカレーションしました。', 'success');
                return refreshApex(this.wiredCasesResult);
            })
            .catch((error) => {
                this.showToast('エラー', this.extractErrorMessage(error), 'error');
            });
    }

    extractErrorMessage(error) {
        return (error && error.body && error.body.message) || '予期しないエラーが発生しました。';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
