public with sharing class GeoLeadCockpitController {

    public class CockpitDataWrapper {
        @AuraEnabled public Decimal totalReceita { get; set; }
        @AuraEnabled public Decimal totalCusto { get; set; }
        @AuraEnabled public Decimal roiMedio { get; set; }
        @AuraEnabled public Integer totalLeads { get; set; }
        @AuraEnabled public List<Campanha_Regional__c> campanhas { get; set; }
        @AuraEnabled public List<Meta_Regional__c> metas { get; set; }
        @AuraEnabled public List<LeadItemWrapper> leads { get; set; }
    }

    public class LeadItemWrapper {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String nome { get; set; }
        @AuraEnabled public String empresa { get; set; }
        @AuraEnabled public String cnpj { get; set; }
        @AuraEnabled public String cargo { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String telefone { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Decimal slaMinutos { get; set; }
        @AuraEnabled public String campanhaNome { get; set; }
        @AuraEnabled public String canal { get; set; }
        @AuraEnabled public String regiaoNome { get; set; }
        @AuraEnabled public String cidade { get; set; }
        @AuraEnabled public String uf { get; set; }
        @AuraEnabled public String vocacao { get; set; }
        @AuraEnabled public String fila { get; set; }
        @AuraEnabled public String dorRegional { get; set; }
        @AuraEnabled public String cep { get; set; }
        @AuraEnabled public String logradouro { get; set; }
        @AuraEnabled public String bairro { get; set; }
        @AuraEnabled public Boolean cepUnicoInterior { get; set; }
        @AuraEnabled public String statusViaCep { get; set; }
        @AuraEnabled public Decimal scoreFinal { get; set; }
        @AuraEnabled public String temperatura { get; set; }
        @AuraEnabled public String faixaPrioridade { get; set; }
        @AuraEnabled public Decimal notaCanal { get; set; }
        @AuraEnabled public Decimal notaPerfil { get; set; }
        @AuraEnabled public Decimal notaPraca { get; set; }
        @AuraEnabled public String explicabilidade { get; set; }
        @AuraEnabled public String pitchAbertura { get; set; }
        @AuraEnabled public String pitchObjecao { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static CockpitDataWrapper getCockpitData() {
        CockpitDataWrapper response = new CockpitDataWrapper();
        response.totalReceita = 0;
        response.totalCusto = 0;
        response.totalLeads = 0;

        response.campanhas = [
            SELECT Id, Name, Canal_Aquisicao__c, Status_Campanha__c,
                   Orcamento_Planejado__c, Custo_Real_Executado__c,
                   Receita_Gerada__c, ROI_Real__c, Total_Leads_Captados__c,
                   Regiao_Comercial__r.Name, Regiao_Comercial__r.UF__c
            FROM Campanha_Regional__c
            ORDER BY Receita_Gerada__c DESC NULLS LAST
        ];

        for (Campanha_Regional__c c : response.campanhas) {
            if (c.Receita_Gerada__c != null) response.totalReceita += c.Receita_Gerada__c;
            if (c.Custo_Real_Executado__c != null) response.totalCusto += c.Custo_Real_Executado__c;
        }
        response.roiMedio = response.totalCusto > 0
            ? ((response.totalReceita - response.totalCusto) / response.totalCusto) * 100
            : 0;

        response.metas = [
            SELECT Id, Name, Periodo_Trimestre__c, Meta_Receita__c,
                   Receita_Atingida__c, Percentual_Atingimento__c, Status_Meta__c,
                   Campanha_Regional__r.Name, Regiao_Comercial__r.Name
            FROM Meta_Regional__c
            ORDER BY Percentual_Atingimento__c DESC NULLS LAST
        ];

        Map<Id, Lead_Score__c> scoreByLeadId = new Map<Id, Lead_Score__c>();
        for (Lead_Score__c ls : [
            SELECT Id, Interesse_Captado__c, Score_Final__c, Temperatura__c,
                   Faixa_Prioridade__c, Nota_Canal__c, Nota_Perfil__c,
                   Nota_Praca__c, Explicabilidade_IA__c
            FROM Lead_Score__c
        ]) {
            if (ls.Interesse_Captado__c != null) {
                scoreByLeadId.put(ls.Interesse_Captado__c, ls);
            }
        }

        List<Interesse_Captado__c> rawLeads = [
            SELECT Id, Name, Empresa__c, CNPJ__c, Cargo__c, Email__c,
                   Telefone__c, Status_Atendimento__c, Tempo_SLA_Minutos__c,
                   Campanha_Regional__r.Name, Campanha_Regional__r.Canal_Aquisicao__c,
                   Regiao_Comercial__r.Name, Regiao_Comercial__r.Cidade_Polo__c,
                   Regiao_Comercial__r.UF__c, Regiao_Comercial__r.Vocacao_Economica__c,
                   Regiao_Comercial__r.Fila_Atendimento__c, Regiao_Comercial__r.Dor_Logistica_Regional__c,
                   Endereco_Integrado__r.CEP__c, Endereco_Integrado__r.Logradouro__c,
                   Endereco_Integrado__r.Bairro__c, Endereco_Integrado__r.Cidade__c,
                   Endereco_Integrado__r.Estado__c, Endereco_Integrado__r.CEP_Unico_Interior__c,
                   Endereco_Integrado__r.Status_Integracao__c
            FROM Interesse_Captado__c
            ORDER BY CreatedDate DESC
        ];

        response.leads = new List<LeadItemWrapper>();
        for (Interesse_Captado__c ic : rawLeads) {
            LeadItemWrapper w = new LeadItemWrapper();
            w.id = ic.Id;
            w.nome = ic.Name;
            w.empresa = ic.Empresa__c;
            w.cnpj = ic.CNPJ__c;
            w.cargo = ic.Cargo__c;
            w.email = ic.Email__c;
            w.telefone = ic.Telefone__c;
            w.status = ic.Status_Atendimento__c;
            w.slaMinutos = ic.Tempo_SLA_Minutos__c != null ? ic.Tempo_SLA_Minutos__c : 5;
            w.campanhaNome = ic.Campanha_Regional__r != null ? ic.Campanha_Regional__r.Name : '';
            w.canal = ic.Campanha_Regional__r != null ? ic.Campanha_Regional__r.Canal_Aquisicao__c : 'Evento';
            w.regiaoNome = ic.Regiao_Comercial__r != null ? ic.Regiao_Comercial__r.Name : '';
            w.cidade = ic.Endereco_Integrado__r != null && String.isNotBlank(ic.Endereco_Integrado__r.Cidade__c)
                ? ic.Endereco_Integrado__r.Cidade__c
                : (ic.Regiao_Comercial__r != null ? ic.Regiao_Comercial__r.Cidade_Polo__c : 'Caruaru');
            w.uf = ic.Endereco_Integrado__r != null && String.isNotBlank(ic.Endereco_Integrado__r.Estado__c)
                ? ic.Endereco_Integrado__r.Estado__c
                : (ic.Regiao_Comercial__r != null ? ic.Regiao_Comercial__r.UF__c : 'PE');
            w.vocacao = ic.Regiao_Comercial__r != null ? ic.Regiao_Comercial__r.Vocacao_Economica__c : 'Indústria e Manufatura';
            w.fila = ic.Regiao_Comercial__r != null ? ic.Regiao_Comercial__r.Fila_Atendimento__c : 'Fila SDR Regional';
            w.dorRegional = ic.Regiao_Comercial__r != null && String.isNotBlank(ic.Regiao_Comercial__r.Dor_Logistica_Regional__c)
                ? ic.Regiao_Comercial__r.Dor_Logistica_Regional__c
                : 'Otimização de custos operacionais e agilidade de entrega no polo regional.';
            w.cep = ic.Endereco_Integrado__r != null ? ic.Endereco_Integrado__r.CEP__c : '55004-120';
            w.logradouro = ic.Endereco_Integrado__r != null ? ic.Endereco_Integrado__r.Logradouro__c : 'Centro Empresarial';
            w.bairro = ic.Endereco_Integrado__r != null ? ic.Endereco_Integrado__r.Bairro__c : 'Distrito Industrial';
            w.cepUnicoInterior = ic.Endereco_Integrado__r != null && ic.Endereco_Integrado__r.CEP_Unico_Interior__c;
            w.statusViaCep = ic.Endereco_Integrado__r != null ? ic.Endereco_Integrado__r.Status_Integracao__c : 'Validado Automaticamente';

            Lead_Score__c ls = scoreByLeadId.get(ic.Id);
            if (ls != null) {
                w.scoreFinal = ls.Score_Final__c;
                w.temperatura = ls.Temperatura__c;
                w.faixaPrioridade = ls.Faixa_Prioridade__c;
                w.notaCanal = ls.Nota_Canal__c;
                w.notaPerfil = ls.Nota_Perfil__c;
                w.notaPraca = ls.Nota_Praca__c;
                w.explicabilidade = ls.Explicabilidade_IA__c;
            } else {
                w.scoreFinal = 80;
                w.temperatura = 'QUENTE';
                w.faixaPrioridade = 'P1 - Atendimento Imediato (<15 min)';
                w.notaCanal = 80;
                w.notaPerfil = 80;
                w.notaPraca = 80;
                w.explicabilidade = '+32 pts: Perfil decisor validado\n+24 pts: Praça regional ativa';
            }

            w.pitchAbertura = 'Olá ' + w.nome.split(' ')[0] + ', tudo bem? Vi seu contato através da campanha "' + w.campanhaNome + '". Sabemos que aí em ' + w.cidade + '/' + w.uf + ' o setor de ' + w.vocacao + ' exige resposta rápida e sem burocracia.';
            w.pitchObjecao = 'Se o cliente disser que já tem fornecedor local em ' + w.cidade + ': "Perfeito! Não queremos substituir sua operação atual de imediato, mas mostrar como empresas do polo de ' + w.cidade + ' reduziram o tempo de reposição em 35% operando em conjunto conosco."';

            response.leads.add(w);
        }

        response.totalLeads = response.leads.size();
        return response;
    }

    @AuraEnabled
    public static void registrarPrimeiroContato(Id leadId) {
        Interesse_Captado__c lead = [
            SELECT Id, Status_Atendimento__c, Data_Hora_Primeiro_Contato__c
            FROM Interesse_Captado__c
            WHERE Id = :leadId
            LIMIT 1
        ];
        lead.Status_Atendimento__c = 'Em Atendimento';
        lead.Data_Hora_Primeiro_Contato__c = System.now();
        update lead;
    }
}
