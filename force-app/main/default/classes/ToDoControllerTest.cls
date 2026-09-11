/**
 * @description Classe de testes para ToDoController, garantindo cobertura completa e validação de regras de negócio.
 */
@isTest
private class ToDoControllerTest {

    @testSetup
    static void setupTestData() {
        List<ToDo_Item__c> items = new List<ToDo_Item__c>{
            new ToDo_Item__c(
                Title__c = 'Tarefa de Teste 1',
                Priority__c = 'Alta',
                Due_Date__c = Date.today().addDays(2),
                Is_Completed__c = false
            ),
            new ToDo_Item__c(
                Title__c = 'Tarefa de Teste 2',
                Priority__c = 'Baixa',
                Due_Date__c = Date.today().addDays(5),
                Is_Completed__c = true
            )
        };
        insert items;
    }

    @isTest
    static void testGetTasks() {
        Test.startTest();
        List<ToDo_Item__c> results = ToDoController.getTasks();
        Test.stopTest();

        System.assertNotEquals(null, results, 'A lista de tarefas não deve ser nula');
        System.assertEquals(2, results.size(), 'Deveriam existir 2 tarefas');
        // A tarefa pendente deve vir antes da concluída pela ordenação
        System.assertEquals(false, results[0].Is_Completed__c, 'A primeira tarefa deve ser a pendente');
    }

    @isTest
    static void testCreateTaskSuccess() {
        Test.startTest();
        ToDo_Item__c created = ToDoController.createTask('Nova Tarefa Teste', 'Média', Date.today().addDays(3));
        Test.stopTest();

        System.assertNotEquals(null, created.Id, 'O registro criado deve possuir Id');
        ToDo_Item__c queried = [SELECT Title__c, Priority__c, Due_Date__c, Is_Completed__c FROM ToDo_Item__c WHERE Id = :created.Id];
        System.assertEquals('Nova Tarefa Teste', queried.Title__c, 'O título deve corresponder ao informado');
        System.assertEquals('Média', queried.Priority__c, 'A prioridade deve ser Média');
        System.assertEquals(false, queried.Is_Completed__c, 'O status inicial deve ser não concluído');
    }

    @isTest
    static void testCreateTaskBlankTitleValidation() {
        Test.startTest();
        try {
            ToDoController.createTask('', 'Alta', Date.today());
            System.assert(false, 'Deveria lançar AuraHandledException ao passar título em branco');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @isTest
    static void testToggleTaskStatus() {
        ToDo_Item__c item = [SELECT Id, Is_Completed__c FROM ToDo_Item__c WHERE Is_Completed__c = false LIMIT 1];

        Test.startTest();
        ToDo_Item__c updated = ToDoController.toggleTaskStatus(item.Id, true);
        Test.stopTest();

        System.assertEquals(true, updated.Is_Completed__c, 'O status retornado deve ser concluído (true)');
        ToDo_Item__c verified = [SELECT Is_Completed__c FROM ToDo_Item__c WHERE Id = :item.Id];
        System.assertEquals(true, verified.Is_Completed__c, 'O registro no banco deve estar como concluído');
    }

    @isTest
    static void testToggleTaskStatusNullId() {
        Test.startTest();
        try {
            ToDoController.toggleTaskStatus(null, true);
            System.assert(false, 'Deveria lançar AuraHandledException para Id nulo');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateTaskSuccess() {
        ToDo_Item__c item = [SELECT Id FROM ToDo_Item__c LIMIT 1];
        Date newDate = Date.today().addDays(10);

        Test.startTest();
        ToDo_Item__c updated = ToDoController.updateTask(item.Id, 'Título Alterado', 'Alta', newDate);
        Test.stopTest();

        System.assertNotEquals(null, updated, 'O objeto atualizado não deve ser nulo');
        ToDo_Item__c queried = [SELECT Title__c, Priority__c, Due_Date__c FROM ToDo_Item__c WHERE Id = :item.Id];
        System.assertEquals('Título Alterado', queried.Title__c, 'O título deveria ter sido atualizado');
        System.assertEquals('Alta', queried.Priority__c, 'A prioridade deveria ter sido atualizada');
        System.assertEquals(newDate, queried.Due_Date__c, 'A data de vencimento deveria ter sido atualizada');
    }

    @isTest
    static void testUpdateTaskBlankTitle() {
        ToDo_Item__c item = [SELECT Id FROM ToDo_Item__c LIMIT 1];

        Test.startTest();
        try {
            ToDoController.updateTask(item.Id, '   ', 'Alta', Date.today());
            System.assert(false, 'Deveria lançar exceção com título em branco');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteTaskSuccess() {
        ToDo_Item__c item = [SELECT Id FROM ToDo_Item__c LIMIT 1];

        Test.startTest();
        ToDoController.deleteTask(item.Id);
        Test.stopTest();

        List<ToDo_Item__c> remaining = [SELECT Id FROM ToDo_Item__c WHERE Id = :item.Id];
        System.assertEquals(0, remaining.size(), 'O registro deveria ter sido excluído');
    }

    @isTest
    static void testDeleteTaskNullId() {
        Test.startTest();
        try {
            ToDoController.deleteTask(null);
            System.assert(false, 'Deveria lançar exceção para Id nulo na exclusão');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }
}
