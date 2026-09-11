import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getTasks from '@salesforce/apex/ToDoController.getTasks';
import createTask from '@salesforce/apex/ToDoController.createTask';
import toggleTaskStatus from '@salesforce/apex/ToDoController.toggleTaskStatus';
import updateTask from '@salesforce/apex/ToDoController.updateTask';
import deleteTask from '@salesforce/apex/ToDoController.deleteTask';

export default class ToDoApp extends LightningElement {
    @track tasks = [];
    wiredTasksResult;

    @track isLoading = false;
    @track newTitle = '';
    @track newPriority = 'Média';
    @track newDueDate = '';
    @track currentFilter = 'ALL'; // 'ALL' | 'PENDING' | 'COMPLETED'
    @track searchTerm = '';

    priorityOptions = [
        { label: 'Baixa', value: 'Baixa' },
        { label: 'Média', value: 'Média' },
        { label: 'Alta', value: 'Alta' }
    ];

    @wire(getTasks)
    wiredGetTasks(result) {
        this.wiredTasksResult = result;
        const { data, error } = result;
        if (data) {
            this.tasks = data;
        } else if (error) {
            this.showToast('Erro', this.extractErrorMessage(error), 'error');
        }
    }

    // --- Contadores & Métricas ---
    get totalCount() {
        return this.tasks ? this.tasks.length : 0;
    }

    get pendingCount() {
        return this.tasks ? this.tasks.filter(task => !task.Is_Completed__c).length : 0;
    }

    get completedCount() {
        return this.tasks ? this.tasks.filter(task => task.Is_Completed__c).length : 0;
    }

    get completionPercentage() {
        if (this.totalCount === 0) return 0;
        return Math.round((this.completedCount / this.totalCount) * 100);
    }

    // --- Filtros & Busca ---
    get allButtonVariant() {
        return this.currentFilter === 'ALL' ? 'brand' : 'neutral';
    }

    get pendingButtonVariant() {
        return this.currentFilter === 'PENDING' ? 'brand' : 'neutral';
    }

    get completedButtonVariant() {
        return this.currentFilter === 'COMPLETED' ? 'brand' : 'neutral';
    }

    get allFilterLabel() {
        return `Todas (${this.totalCount})`;
    }

    get pendingFilterLabel() {
        return `Pendentes (${this.pendingCount})`;
    }

    get completedFilterLabel() {
        return `Concluídas (${this.completedCount})`;
    }

    get isAddDisabled() {
        return !this.newTitle || !this.newTitle.trim();
    }

    get filteredTasks() {
        let list = this.tasks || [];

        // Filtro de status
        if (this.currentFilter === 'PENDING') {
            list = list.filter(t => !t.Is_Completed__c);
        } else if (this.currentFilter === 'COMPLETED') {
            list = list.filter(t => t.Is_Completed__c);
        }

        // Filtro de busca textual
        if (this.searchTerm && this.searchTerm.trim()) {
            const query = this.searchTerm.trim().toLowerCase();
            list = list.filter(t => t.Title__c && t.Title__c.toLowerCase().includes(query));
        }

        return list;
    }

    get hasTasks() {
        return this.filteredTasks && this.filteredTasks.length > 0;
    }

    get emptyStateTitle() {
        if (this.totalCount === 0) {
            return 'Nenhuma tarefa criada';
        }
        return 'Nenhum resultado encontrado';
    }

    get emptyStateSubtitle() {
        if (this.totalCount === 0) {
            return 'Comece adicionando uma nova tarefa no formulário acima.';
        }
        return 'Tente alterar os filtros ou o termo de pesquisa.';
    }

    // --- Manipulação de Entradas da Nova Tarefa ---
    handleNewTitleChange(event) {
        this.newTitle = event.target.value;
    }

    handleNewPriorityChange(event) {
        this.newPriority = event.detail.value;
    }

    handleNewDueDateChange(event) {
        this.newDueDate = event.target.value;
    }

    handleKeyUp(event) {
        if (event.keyCode === 13 && !this.isAddDisabled) {
            this.handleAddTask();
        }
    }

    // --- Filtros & Busca Handlers ---
    handleFilterAll() {
        this.currentFilter = 'ALL';
    }

    handleFilterPending() {
        this.currentFilter = 'PENDING';
    }

    handleFilterCompleted() {
        this.currentFilter = 'COMPLETED';
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredTasksResult)
            .then(() => {
                this.showToast('Sucesso', 'Lista de tarefas atualizada.', 'info');
            })
            .catch(error => {
                this.showToast('Erro', this.extractErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // --- Operações DML (Criação, Atualização, Exclusão) ---
    async handleAddTask() {
        if (this.isAddDisabled) return;

        this.isLoading = true;
        try {
            await createTask({
                title: this.newTitle.trim(),
                priority: this.newPriority,
                dueDate: this.newDueDate || null
            });

            this.showToast('Sucesso', 'Tarefa adicionada com sucesso!', 'success');
            this.newTitle = '';
            this.newPriority = 'Média';
            this.newDueDate = '';
            await refreshApex(this.wiredTasksResult);
        } catch (error) {
            this.showToast('Erro ao criar tarefa', this.extractErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleToggleTask(event) {
        const { id, isCompleted } = event.detail;
        this.isLoading = true;

        try {
            await toggleTaskStatus({ taskId: id, isCompleted });
            await refreshApex(this.wiredTasksResult);
            const statusMsg = isCompleted ? 'Tarefa concluída!' : 'Tarefa reaberta.';
            this.showToast('Status Atualizado', statusMsg, 'success');
        } catch (error) {
            this.showToast('Erro ao atualizar status', this.extractErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleUpdateTask(event) {
        const { id, title, priority, dueDate } = event.detail;
        this.isLoading = true;

        try {
            await updateTask({ taskId: id, title, priority, dueDate });
            this.showToast('Sucesso', 'Tarefa atualizada com sucesso!', 'success');
            await refreshApex(this.wiredTasksResult);
        } catch (error) {
            this.showToast('Erro ao atualizar tarefa', this.extractErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleDeleteTask(event) {
        const { id } = event.detail;
        this.isLoading = true;

        try {
            await deleteTask({ taskId: id });
            this.showToast('Sucesso', 'Tarefa excluída com sucesso!', 'success');
            await refreshApex(this.wiredTasksResult);
        } catch (error) {
            this.showToast('Erro ao excluir tarefa', this.extractErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // --- Utilitários ---
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(toastEvent);
    }

    extractErrorMessage(error) {
        if (!error) return 'Erro desconhecido.';
        if (typeof error === 'string') return error;
        if (error.body) {
            if (typeof error.body.message === 'string') {
                return error.body.message;
            }
            if (Array.isArray(error.body)) {
                return error.body.map(e => e.message).join(', ');
            }
        }
        if (error.message) return error.message;
        return JSON.stringify(error);
    }
}
