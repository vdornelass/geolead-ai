import { LightningElement, api, track } from 'lwc';

export default class ToDoItem extends LightningElement {
    @api task;

    @track isEditing = false;
    @track editTitle = '';
    @track editPriority = '';
    @track editDueDate = '';

    priorityOptions = [
        { label: 'Baixa', value: 'Baixa' },
        { label: 'Média', value: 'Média' },
        { label: 'Alta', value: 'Alta' }
    ];

    get containerClass() {
        let baseClass = 'slds-item slds-m-bottom_x-small task-card';
        if (this.task?.Is_Completed__c) {
            baseClass += ' task-completed';
        }
        return baseClass;
    }

    get titleClass() {
        return this.task?.Is_Completed__c 
            ? 'slds-text-heading_small task-title strike-through' 
            : 'slds-text-heading_small task-title';
    }

    get isOverdue() {
        if (!this.task || this.task.Is_Completed__c || !this.task.Due_Date__c) {
            return false;
        }
        const today = new Date().toISOString().split('T')[0];
        return this.task.Due_Date__c < today;
    }

    get priorityBadgeClass() {
        const priority = this.task?.Priority__c;
        if (priority === 'Alta') {
            return 'slds-badge slds-theme_error priority-badge';
        } else if (priority === 'Média') {
            return 'slds-badge slds-theme_warning priority-badge';
        }
        return 'slds-badge slds-badge_lightest priority-badge';
    }

    get formattedDueDate() {
        if (!this.task?.Due_Date__c) return '';
        const parts = this.task.Due_Date__c.split('-');
        if (parts.length === 3) {
            return `${parts[2]}/${parts[1]}/${parts[0]}`;
        }
        return this.task.Due_Date__c;
    }

    get dueDateClass() {
        return this.isOverdue 
            ? 'slds-text-color_error slds-m-left_small slds-text-body_small due-date overdue' 
            : 'slds-text-color_weak slds-m-left_small slds-text-body_small due-date';
    }

    get dueDateIcon() {
        return this.isOverdue ? 'utility:warning' : 'utility:event';
    }

    get dueDateIconVariant() {
        return this.isOverdue ? 'error' : null;
    }

    handleCheckboxChange(event) {
        const isCompleted = event.target.checked;
        this.dispatchEvent(new CustomEvent('toggle', {
            detail: {
                id: this.task.Id,
                isCompleted: isCompleted
            },
            bubbles: true,
            composed: true
        }));
    }

    handleStartEdit() {
        this.editTitle = this.task.Title__c;
        this.editPriority = this.task.Priority__c || 'Média';
        this.editDueDate = this.task.Due_Date__c || '';
        this.isEditing = true;
    }

    handleCancelEdit() {
        this.isEditing = false;
    }

    handleTitleChange(event) {
        this.editTitle = event.target.value;
    }

    handlePriorityChange(event) {
        this.editPriority = event.detail.value;
    }

    handleDueDateChange(event) {
        this.editDueDate = event.target.value;
    }

    handleSaveEdit() {
        if (!this.editTitle || !this.editTitle.trim()) {
            return;
        }

        this.dispatchEvent(new CustomEvent('update', {
            detail: {
                id: this.task.Id,
                title: this.editTitle.trim(),
                priority: this.editPriority,
                dueDate: this.editDueDate || null
            },
            bubbles: true,
            composed: true
        }));

        this.isEditing = false;
    }

    handleDelete() {
        this.dispatchEvent(new CustomEvent('delete', {
            detail: {
                id: this.task.Id
            },
            bubbles: true,
            composed: true
        }));
    }
}
