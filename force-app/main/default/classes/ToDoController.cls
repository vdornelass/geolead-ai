/**
 * @description Controller Apex para o gerenciamento de tarefas na To-Do List.
 * Utiliza o modelo de segurança 'with sharing' e consultas/DML em 'USER_MODE'.
 */
public with sharing class ToDoController {

    /**
     * @description Recupera todos os itens da lista de tarefas ordenados por status, data e criação.
     * @return Lista de ToDo_Item__c
     */
    @AuraEnabled(cacheable=true)
    public static List<ToDo_Item__c> getTasks() {
        try {
            return [
                SELECT Id, Name, Title__c, Is_Completed__c, Priority__c, Due_Date__c, CreatedDate
                FROM ToDo_Item__c
                WITH USER_MODE
                ORDER BY Is_Completed__c ASC, Due_Date__c ASC NULLS LAST, CreatedDate DESC
            ];
        } catch (Exception ex) {
            throw createAuraException('Erro ao buscar tarefas: ' + ex.getMessage());
        }
    }

    /**
     * @description Cria uma nova tarefa.
     * @param title Título da tarefa (obrigatório)
     * @param priority Nível de prioridade (Baixa, Média, Alta)
     * @param dueDate Data de vencimento
     * @return O registro ToDo_Item__c recém-criado
     */
    @AuraEnabled
    public static ToDo_Item__c createTask(String title, String priority, Date dueDate) {
        if (String.isBlank(title)) {
            throw createAuraException('O título da tarefa é obrigatório.');
        }

        try {
            ToDo_Item__c newItem = new ToDo_Item__c(
                Title__c = title.trim(),
                Priority__c = String.isNotBlank(priority) ? priority : 'Média',
                Due_Date__c = dueDate,
                Is_Completed__c = false
            );

            Database.SaveResult sr = Database.insert(newItem, AccessLevel.USER_MODE);
            if (!sr.isSuccess()) {
                String errorMsg = sr.getErrors()[0].getMessage();
                throw createAuraException('Erro ao criar tarefa: ' + errorMsg);
            }

            return newItem;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            throw createAuraException('Erro ao salvar tarefa: ' + ex.getMessage());
        }
    }

    /**
     * @description Alterna o status de conclusão da tarefa.
     * @param taskId Id da tarefa
     * @param isCompleted Novo status de conclusão
     * @return O registro ToDo_Item__c atualizado
     */
    @AuraEnabled
    public static ToDo_Item__c toggleTaskStatus(Id taskId, Boolean isCompleted) {
        if (taskId == null) {
            throw createAuraException('Identificador da tarefa inválido.');
        }

        try {
            ToDo_Item__c itemToUpdate = new ToDo_Item__c(
                Id = taskId,
                Is_Completed__c = isCompleted != null ? isCompleted : false
            );

            Database.SaveResult sr = Database.update(itemToUpdate, AccessLevel.USER_MODE);
            if (!sr.isSuccess()) {
                String errorMsg = sr.getErrors()[0].getMessage();
                throw createAuraException('Erro ao atualizar status: ' + errorMsg);
            }

            return itemToUpdate;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            throw createAuraException('Erro ao alternar status da tarefa: ' + ex.getMessage());
        }
    }

    /**
     * @description Atualiza os detalhes de uma tarefa existente.
     * @param taskId Id da tarefa
     * @param title Novo título
     * @param priority Nova prioridade
     * @param dueDate Nova data de vencimento
     * @return O registro ToDo_Item__c atualizado
     */
    @AuraEnabled
    public static ToDo_Item__c updateTask(Id taskId, String title, String priority, Date dueDate) {
        if (taskId == null) {
            throw createAuraException('Identificador da tarefa inválido.');
        }
        if (String.isBlank(title)) {
            throw createAuraException('O título da tarefa não pode ser vazio.');
        }

        try {
            ToDo_Item__c itemToUpdate = new ToDo_Item__c(
                Id = taskId,
                Title__c = title.trim(),
                Priority__c = priority,
                Due_Date__c = dueDate
            );

            Database.SaveResult sr = Database.update(itemToUpdate, AccessLevel.USER_MODE);
            if (!sr.isSuccess()) {
                String errorMsg = sr.getErrors()[0].getMessage();
                throw createAuraException('Erro ao atualizar tarefa: ' + errorMsg);
            }

            return itemToUpdate;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            throw createAuraException('Erro ao atualizar tarefa: ' + ex.getMessage());
        }
    }

    /**
     * @description Exclui uma tarefa pelo Id.
     * @param taskId Id da tarefa a ser excluída
     */
    @AuraEnabled
    public static void deleteTask(Id taskId) {
        if (taskId == null) {
            throw createAuraException('Identificador da tarefa inválido.');
        }

        try {
            ToDo_Item__c itemToDelete = new ToDo_Item__c(Id = taskId);
            Database.DeleteResult dr = Database.delete(itemToDelete, AccessLevel.USER_MODE);
            if (!dr.isSuccess()) {
                String errorMsg = dr.getErrors()[0].getMessage();
                throw createAuraException('Erro ao excluir tarefa: ' + errorMsg);
            }
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception ex) {
            throw createAuraException('Erro ao excluir tarefa: ' + ex.getMessage());
        }
    }

    /**
     * @description Método utilitário para gerar AuraHandledException com mensagem formatada para o LWC.
     */
    private static AuraHandledException createAuraException(String message) {
        AuraHandledException ahe = new AuraHandledException(message);
        ahe.setMessage(message);
        return ahe;
    }
}
