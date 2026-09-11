import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAccountCards from '@salesforce/apex/AccountContactCardController.getAccountCards';

export default class AccountContactCardView extends NavigationMixin(LightningElement) {
    @track rawAccounts = [];
    searchTerm = '';
    activeFilter = 'all'; // 'all', 'withContacts', 'tech', 'vip'
    sortOrder = 'asc'; // 'asc', 'desc'
    isAllExpanded = true;
    isLoading = true;

    // Modal state
    isModalOpen = false;
    selectedAccountId = '';
    selectedAccountName = '';

    wiredAccountsResult;

    @wire(getAccountCards)
    wiredGetAccounts(result) {
        this.wiredAccountsResult = result;
        const { data, error } = result;
        if (data) {
            this.rawAccounts = data.map(item => this.mapAccountItem(item, true));
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            this.showToast('Erro', 'Erro ao carregar dados das contas: ' + (error.body ? error.body.message : error), 'error');
        }
    }

    mapAccountItem(item, defaultExpanded = true) {
        const contactCount = item.contacts ? item.contacts.length : 0;
        let headerLabel = 'NENHUM CONTATO';
        if (contactCount === 1) {
            headerLabel = '1 CONTATO ASSOCIADO';
        } else if (contactCount > 1) {
            headerLabel = `${contactCount} CONTATOS ASSOCIADOS`;
        }

        let badgeClass = 'status-badge status-default';
        if (item.statusVariant === 'vip') {
            badgeClass = 'status-badge status-vip';
        } else if (item.statusVariant === 'success') {
            badgeClass = 'status-badge status-success';
        } else if (item.statusVariant === 'warning') {
            badgeClass = 'status-badge status-warning';
        }

        const contactsFormatted = (item.contacts || []).map(con => ({
            ...con,
            emailMailtoUrl: con.hasEmail ? `mailto:${con.email}` : '#'
        }));

        return {
            ...item,
            isExpanded: defaultExpanded,
            chevronIcon: defaultExpanded ? 'utility:chevrondown' : 'utility:chevronright',
            contactHeaderLabel: headerLabel,
            statusBadgeClass: badgeClass,
            phoneCallUrl: item.hasPhone ? `tel:${item.phone}` : '#',
            contacts: contactsFormatted
        };
    }

    // Getters for header statistics
    get totalAccounts() {
        return this.rawAccounts.length;
    }

    get totalContacts() {
        return this.rawAccounts.reduce((acc, curr) => acc + (curr.contactCount || 0), 0);
    }

    get totalVips() {
        return this.rawAccounts.filter(acc => acc.isVip).length;
    }

    get accountsWithContactsCount() {
        return this.rawAccounts.filter(acc => acc.contactCount > 0).length;
    }

    // Filter Chips dynamic classes
    get isFilterAll() {
        return this.activeFilter === 'all';
    }

    get chipAllClass() {
        return `filter-chip ${this.activeFilter === 'all' ? 'active-chip' : ''}`;
    }

    get chipWithContactsClass() {
        return `filter-chip ${this.activeFilter === 'withContacts' ? 'active-chip' : ''}`;
    }

    get chipTechClass() {
        return `filter-chip ${this.activeFilter === 'tech' ? 'active-chip' : ''}`;
    }

    get chipVipClass() {
        return `filter-chip ${this.activeFilter === 'vip' ? 'active-chip' : ''}`;
    }

    get expandAllLabel() {
        return this.isAllExpanded ? 'Recolher Todos' : 'Expandir Todos';
    }

    get sortLabel() {
        return this.sortOrder === 'asc' ? 'Recentes / A-Z' : 'Z-A';
    }

    // Filtered and sorted accounts list
    get filteredAccounts() {
        let list = [...this.rawAccounts];

        // 1. Filter by Active Chip
        if (this.activeFilter === 'withContacts') {
            list = list.filter(acc => acc.contactCount > 0);
        } else if (this.activeFilter === 'tech') {
            list = list.filter(acc => (acc.industry || '').toLowerCase().includes('tech') || (acc.industry || '').toLowerCase().includes('elec'));
        } else if (this.activeFilter === 'vip') {
            list = list.filter(acc => acc.isVip);
        }

        // 2. Filter by search term
        if (this.searchTerm && this.searchTerm.trim() !== '') {
            const term = this.searchTerm.trim().toLowerCase();
            list = list.filter(acc => {
                const nameMatch = (acc.name || '').toLowerCase().includes(term);
                const industryMatch = (acc.industry || '').toLowerCase().includes(term);
                const locationMatch = (acc.location || '').toLowerCase().includes(term);
                const phoneMatch = (acc.phone || '').toLowerCase().includes(term);
                const contactMatch = (acc.contacts || []).some(con => 
                    (con.name || '').toLowerCase().includes(term) ||
                    (con.title || '').toLowerCase().includes(term) ||
                    (con.email || '').toLowerCase().includes(term)
                );
                return nameMatch || industryMatch || locationMatch || phoneMatch || contactMatch;
            });
        }

        // 3. Sort
        list.sort((a, b) => {
            const nameA = (a.name || '').toLowerCase();
            const nameB = (b.name || '').toLowerCase();
            if (this.sortOrder === 'asc') {
                return nameA.localeCompare(nameB);
            }
            return nameB.localeCompare(nameA);
        });

        return list;
    }

    get displayedCount() {
        return this.filteredAccounts.length;
    }

    get isListEmpty() {
        return this.displayedCount === 0 && !this.isLoading;
    }

    // Event Handlers
    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleClearSearch() {
        this.searchTerm = '';
    }

    handleFilterAll() {
        this.activeFilter = 'all';
    }

    handleFilterWithContacts() {
        this.activeFilter = 'withContacts';
    }

    handleFilterTech() {
        this.activeFilter = 'tech';
    }

    handleFilterVip() {
        this.activeFilter = 'vip';
    }

    handleClearFilters() {
        this.searchTerm = '';
        this.activeFilter = 'all';
    }

    handleToggleSort() {
        this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
    }

    handleToggleExpandAll() {
        this.isAllExpanded = !this.isAllExpanded;
        this.rawAccounts = this.rawAccounts.map(acc => ({
            ...acc,
            isExpanded: this.isAllExpanded,
            chevronIcon: this.isAllExpanded ? 'utility:chevrondown' : 'utility:chevronright'
        }));
    }

    handleToggleCard(event) {
        const accountId = event.currentTarget.dataset.id;
        this.rawAccounts = this.rawAccounts.map(acc => {
            if (acc.id === accountId) {
                const nextState = !acc.isExpanded;
                return {
                    ...acc,
                    isExpanded: nextState,
                    chevronIcon: nextState ? 'utility:chevrondown' : 'utility:chevronright'
                };
            }
            return acc;
        });
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredAccountsResult)
            .then(() => {
                this.isLoading = false;
                this.showToast('Sucesso', 'Lista de contas atualizada com sucesso!', 'success');
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Erro', 'Não foi possível atualizar os dados', 'error');
            });
    }

    // Navigation handlers
    handleNavigateToAccount(event) {
        const accountId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    handleNavigateToContact(event) {
        const contactId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: contactId,
                objectApiName: 'Contact',
                actionName: 'view'
            }
        });
    }

    handleCreateAccount() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'new'
            }
        });
    }

    // Modal handlers
    handleOpenAddContactModal(event) {
        this.selectedAccountId = event.currentTarget.dataset.id;
        this.selectedAccountName = event.currentTarget.dataset.name || 'Conta';
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
        this.selectedAccountId = '';
        this.selectedAccountName = '';
    }

    handleContactCreated(event) {
        this.showToast('Sucesso', 'Contato criado com sucesso!', 'success');
        this.handleCloseModal();
        this.handleRefresh();
    }

    handleContactError(event) {
        this.showToast('Erro ao criar contato', event.detail ? event.detail.message : 'Verifique os campos obrigatórios.', 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}
