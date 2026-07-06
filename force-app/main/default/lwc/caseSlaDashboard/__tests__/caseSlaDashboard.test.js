import { createElement } from 'lwc';
import CaseSlaDashboard from 'c/caseSlaDashboard';
import getOpenCasesWithSla from '@salesforce/apex/CaseSlaDashboardController.getOpenCasesWithSla';
import escalateCase from '@salesforce/apex/CaseSlaDashboardController.escalateCase';
import { refreshApex } from '@salesforce/apex';

jest.mock(
    '@salesforce/apex/CaseSlaDashboardController.getOpenCasesWithSla',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/CaseSlaDashboardController.escalateCase',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex',
    () => ({ refreshApex: jest.fn(() => Promise.resolve()) }),
    { virtual: true }
);

async function flushPromises() {
    return Promise.resolve();
}

function buildCase(overrides) {
    return {
        Id: '500000000000001AAA',
        CaseNumber: '00001001',
        Subject: 'テスト問い合わせ',
        Priority: 'High',
        Status: 'New',
        Inquiry_Category__r: { Name: '製品不良' },
        SLA_Due_Date__c: '2026-07-10T00:00:00.000+0000',
        Is_SLA_Breached__c: false,
        Is_Escalated__c: false,
        Owner: { Name: 'サポート担当者' },
        ...overrides
    };
}

describe('c-case-sla-dashboard', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders the empty state when no open cases are returned', async () => {
        const element = createElement('c-case-sla-dashboard', { is: CaseSlaDashboard });
        document.body.appendChild(element);

        getOpenCasesWithSla.emit([]);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeNull();
        const emptyMessage = element.shadowRoot.querySelector('.slds-p-around_medium p');
        expect(emptyMessage.textContent).toBe('対応中の問い合わせはありません。');
    });

    it('renders a datatable row for each open case with decorated SLA fields', async () => {
        const element = createElement('c-case-sla-dashboard', { is: CaseSlaDashboard });
        document.body.appendChild(element);

        const mockCases = [buildCase({})];
        getOpenCasesWithSla.emit(mockCases);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data).toHaveLength(1);
        expect(datatable.data[0].categoryName).toBe('製品不良');
        expect(datatable.data[0].escalationStatusLabel).toBe('未対応');
        expect(datatable.data[0].isEscalateDisabled).toBe(false);
    });

    it('marks a case as overdue (超過) when SLA is already breached', async () => {
        const element = createElement('c-case-sla-dashboard', { is: CaseSlaDashboard });
        document.body.appendChild(element);

        const mockCases = [buildCase({ Is_SLA_Breached__c: true })];
        getOpenCasesWithSla.emit(mockCases);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable.data[0].slaStatusLabel).toBe('超過');
        expect(datatable.data[0].slaStatusClass).toBe('slds-text-color_error');
    });

    it('marks a case as healthy (順調) when SLA due date is far in the future', async () => {
        const element = createElement('c-case-sla-dashboard', { is: CaseSlaDashboard });
        document.body.appendChild(element);

        const farFuture = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString();
        const mockCases = [buildCase({ SLA_Due_Date__c: farFuture })];
        getOpenCasesWithSla.emit(mockCases);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable.data[0].slaStatusLabel).toBe('順調');
        expect(datatable.data[0].slaStatusClass).toBe('slds-text-color_success');
    });

    it('marks a case as escalated when Is_Escalated__c is true and disables the escalate button', async () => {
        const element = createElement('c-case-sla-dashboard', { is: CaseSlaDashboard });
        document.body.appendChild(element);

        const mockCases = [buildCase({ Is_Escalated__c: true })];
        getOpenCasesWithSla.emit(mockCases);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable.data[0].escalationStatusLabel).toBe('エスカレーション済み');
        expect(datatable.data[0].isEscalateDisabled).toBe(true);
    });

    it('shows an error toast when the wire adapter returns an error', async () => {
        const element = createElement('c-case-sla-dashboard', { is: CaseSlaDashboard });
        const toastHandler = jest.fn();
        element.addEventListener('lightning__showtoast', toastHandler);
        document.body.appendChild(element);

        getOpenCasesWithSla.error(new Error('boom'));
        await flushPromises();

        expect(toastHandler).toHaveBeenCalledTimes(1);
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
    });

    it('calls escalateCase and shows a success toast when the row action is triggered', async () => {
        escalateCase.mockResolvedValue(buildCase({ Is_Escalated__c: true }));

        const element = createElement('c-case-sla-dashboard', { is: CaseSlaDashboard });
        const toastHandler = jest.fn();
        element.addEventListener('lightning__showtoast', toastHandler);
        document.body.appendChild(element);

        const mockCases = [buildCase({})];
        getOpenCasesWithSla.emit(mockCases);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: {
                    action: { name: 'escalate' },
                    row: mockCases[0]
                }
            })
        );
        await flushPromises();

        expect(escalateCase).toHaveBeenCalledWith({
            caseId: mockCases[0].Id,
            reason: '手動エスカレーション（サポートエージェント操作）'
        });
        expect(refreshApex).toHaveBeenCalledTimes(1);
        expect(toastHandler).toHaveBeenCalledTimes(1);
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('success');
    });

    it('shows an error toast with the server message when escalateCase fails', async () => {
        escalateCase.mockRejectedValue({ body: { message: 'エスカレーションに失敗しました' } });

        const element = createElement('c-case-sla-dashboard', { is: CaseSlaDashboard });
        const toastHandler = jest.fn();
        element.addEventListener('lightning__showtoast', toastHandler);
        document.body.appendChild(element);

        const mockCases = [buildCase({})];
        getOpenCasesWithSla.emit(mockCases);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: {
                    action: { name: 'escalate' },
                    row: mockCases[0]
                }
            })
        );
        await flushPromises();

        expect(toastHandler).toHaveBeenCalledTimes(1);
        expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
        expect(toastHandler.mock.calls[0][0].detail.message).toBe('エスカレーションに失敗しました');
    });

    it('ignores row actions other than escalate', async () => {
        const element = createElement('c-case-sla-dashboard', { is: CaseSlaDashboard });
        document.body.appendChild(element);

        const mockCases = [buildCase({})];
        getOpenCasesWithSla.emit(mockCases);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: {
                    action: { name: 'view' },
                    row: mockCases[0]
                }
            })
        );
        await flushPromises();

        expect(escalateCase).not.toHaveBeenCalled();
    });
});
