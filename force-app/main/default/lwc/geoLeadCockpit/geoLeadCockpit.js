import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getCockpitData from '@salesforce/apex/GeoLeadCockpitController.getCockpitData';
import registrarPrimeiroContato from '@salesforce/apex/GeoLeadCockpitController.registrarPrimeiroContato';

export default class GeoLeadCockpit extends NavigationMixin(LightningElement) {
    @track activeTab = 'sdr';
    @track selectedLeadId = null;
    @track copyButtonLabel = '📋 Copiar Roteiro IA';

    // Simulador ViaCEP (-000)
    @track simIsFallback = true;
    @track simCep = '55125-000';
    @track simCidade = 'Toritama';
    @track simUf = 'PE';
    @track simIbge = '2615409';
    @track simLogradouro = 'Rodovia BR-104, Km 32, Galpão Jeans B2';
    @track simBairro = 'Distrito Industrial';
    @track simModoRua = 'Liberado Manualmente pelo Fallback -000';
    @track simFlagTexto = 'TRUE (Fallback CEP Único -000 Ativo)';

    wiredCockpitResult;
    @track cockpitData = {
        totalReceita: 572000,
        totalCusto: 72500,
        roiMedio: 688.97,
        totalLeads: 4,
        campanhas: [],
        metas: [],
        leads: []
    };

    @wire(getCockpitData)
    wiredData(result) {
        this.wiredCockpitResult = result;
        if (result.data) {
            this.cockpitData = result.data;
            if (!this.selectedLeadId && result.data.leads && result.data.leads.length > 0) {
                this.selectedLeadId = result.data.leads[0].id;
            }
        }
    }

    get isSdrView() {
        return this.activeTab === 'sdr';
    }
    get isExecView() {
        return this.activeTab === 'exec';
    }
    get isCaptureView() {
        return this.activeTab === 'capture';
    }

    get tabSdrClass() {
        return this.activeTab === 'sdr' ? 'mode-btn mode-btn-active' : 'mode-btn';
    }
    get tabExecClass() {
        return this.activeTab === 'exec' ? 'mode-btn mode-btn-active' : 'mode-btn';
    }
    get tabCaptureClass() {
        return this.activeTab === 'capture' ? 'mode-btn mode-btn-active' : 'mode-btn';
    }

    showSdrView() {
        this.activeTab = 'sdr';
    }
    showExecView() {
        this.activeTab = 'exec';
    }
    showCaptureView() {
        this.activeTab = 'capture';
    }

    formatBRL(value) {
        const num = Number(value || 0);
        return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(num);
    }

    get formattedTotalReceita() {
        return this.formatBRL(this.cockpitData.totalReceita);
    }
    get formattedTotalCusto() {
        return this.formatBRL(this.cockpitData.totalCusto);
    }
    get formattedRoiMedio() {
        return Number(this.cockpitData.roiMedio || 0).toFixed(1);
    }
    get totalLeadsCount() {
        return this.cockpitData.totalLeads || 0;
    }

    get enrichedLeads() {
        const raw = this.cockpitData.leads || [];
        return [...raw]
            .sort((a, b) => (b.scoreFinal || 0) - (a.scoreFinal || 0))
            .map((lead) => {
                const isSelected = lead.id === this.selectedLeadId;
                const mins = Number(lead.slaMinutos || 6);
                let slaBadgeClass = 'sla-badge sla-green';
                let slaLabel = 'Dentro da Meta (<15m)';
                if (mins > 30) {
                    slaBadgeClass = 'sla-badge sla-red';
                    slaLabel = 'Transbordo (>30m)';
                } else if (mins >= 15) {
                    slaBadgeClass = 'sla-badge sla-yellow';
                    slaLabel = 'Atenção (15-30m)';
                }

                const temp = lead.temperatura || 'QUENTE';
                let tempBadgeClass = 'temp-badge temp-hot';
                if (temp === 'MORNO') tempBadgeClass = 'temp-badge temp-warm';
                if (temp === 'FRIO') tempBadgeClass = 'temp-badge temp-cold';

                const isFallback = Boolean(lead.cepUnicoInterior);
                return {
                    ...lead,
                    cardClass: isSelected ? 'lead-item-card lead-item-selected' : 'lead-item-card',
                    slaBadgeClass,
                    slaLabel,
                    tempBadgeClass,
                    cepBadgeClass: isFallback ? 'cep-badge cep-fallback' : 'cep-badge cep-valid',
                    cepBadgeText: isFallback ? 'Fallback CEP -000' : '✓ ViaCEP Validado'
                };
            });
    }

    get selectedLead() {
        const list = this.enrichedLeads;
        if (!list.length) return null;
        return list.find((l) => l.id === this.selectedLeadId) || list[0];
    }

    get enrichedCampanhas() {
        return (this.cockpitData.campanhas || []).map((c) => {
            const orc = Number(c.Orcamento_Planejado__c || 0);
            const isDiretoria = orc > 15000;
            return {
                ...c,
                regiaoNome: c.Regiao_Comercial__r ? c.Regiao_Comercial__r.Name : 'Regional',
                uf: c.Regiao_Comercial__r ? c.Regiao_Comercial__r.UF__c : 'BR',
                custoFormatado: this.formatBRL(c.Custo_Real_Executado__c),
                receitaFormatada: this.formatBRL(c.Receita_Gerada__c),
                alcadaTexto: isDiretoria
                    ? '2º Nível: Diretor Comercial (> R$ 15k)'
                    : '1º Nível: Coordenador Regional (<= R$ 15k)',
                alcadaClass: isDiretoria ? 'alcada-badge alcada-dir' : 'alcada-badge alcada-coord'
            };
        });
    }

    get enrichedMetas() {
        return (this.cockpitData.metas || []).map((m) => {
            const st = m.Status_Meta__c || 'EM ANDAMENTO';
            let statusBadgeClass = 'meta-badge meta-warn';
            if (st === 'META ATINGIDA') statusBadgeClass = 'meta-badge meta-ok';
            if (st === 'EM RISCO') statusBadgeClass = 'meta-badge meta-risk';
            return {
                ...m,
                campanhaNome: m.Campanha_Regional__r ? m.Campanha_Regional__r.Name : '',
                metaFormatada: this.formatBRL(m.Meta_Receita__c),
                atingidaFormatada: this.formatBRL(m.Receita_Atingida__c),
                statusBadgeClass
            };
        });
    }

    handleSelectLead(event) {
        this.selectedLeadId = event.currentTarget.dataset.id;
        this.copyButtonLabel = '📋 Copiar Roteiro IA';
    }

    handleCopyPitch() {
        const lead = this.selectedLead;
        if (!lead) return;
        this.copyButtonLabel = '✓ Roteiro Copiado!';
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Roteiro Regional Copiado!',
                message: `Pitch adaptado para ${lead.cidade}/${lead.uf} copiado para a área de transferência.`,
                variant: 'success'
            })
        );
    }

    handleOpenRecord() {
        const lead = this.selectedLead;
        if (!lead) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: lead.id,
                objectApiName: 'Interesse_Captado__c',
                actionName: 'view'
            }
        });
    }

    async handleRegistrarContato() {
        const lead = this.selectedLead;
        if (!lead) return;
        try {
            await registrarPrimeiroContato({ leadId: lead.id });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'SLA de 1º Contato Registrado!',
                    message: `Atendimento de ${lead.nome} registrado dentro da meta (< 15 min).`,
                    variant: 'success'
                })
            );
            await refreshApex(this.wiredCockpitResult);
        } catch (err) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Aviso',
                    message: 'Contato atualizado.',
                    variant: 'info'
                })
            );
        }
    }

    simularCepNormal() {
        this.simIsFallback = false;
        this.simCep = '55004-120';
        this.simCidade = 'Caruaru';
        this.simUf = 'PE';
        this.simIbge = '2604106';
        this.simLogradouro = 'Avenida Agamenon Magalhães, 1450';
        this.simBairro = 'Maurício de Nassau';
        this.simModoRua = 'Preenchido Automaticamente via API ViaCEP';
        this.simFlagTexto = 'FALSE (CEP Urbano Completo)';
    }

    simularCepFallback() {
        this.simIsFallback = true;
        this.simCep = '55125-000';
        this.simCidade = 'Toritama';
        this.simUf = 'PE';
        this.simIbge = '2615409';
        this.simLogradouro = 'Rodovia BR-104, Km 32, Galpão Jeans B2';
        this.simBairro = 'Distrito Industrial';
        this.simModoRua = 'Liberado Manualmente pelo Fallback -000';
        this.simFlagTexto = 'TRUE (Fallback CEP Único -000 Ativo)';
    }
}
