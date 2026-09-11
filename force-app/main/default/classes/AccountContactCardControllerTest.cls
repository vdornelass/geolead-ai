@isTest
private class AccountContactCardControllerTest {

    @isTest
    static void testGetAccountCards() {
        Account acc1 = new Account(
            Name = 'Empresa Teste VIP',
            Industry = 'Technology',
            BillingCity = 'Recife',
            Phone = '(81) 9999-8888',
            Rating = 'Hot',
            AnnualRevenue = 60000000
        );
        Account acc2 = new Account(
            Name = 'Empresa Teste Normal',
            Industry = 'Manufacturing',
            BillingCity = 'Caruaru',
            Phone = '(81) 9888-7777',
            Rating = 'Warm'
        );
        insert new List<Account>{ acc1, acc2 };

        Contact con1 = new Contact(
            FirstName = 'Gabriel',
            LastName = 'Silva',
            AccountId = acc1.Id,
            Title = 'VP de Tecnologia',
            Phone = '(81) 9888-1111',
            Email = 'gabriel@teste.com'
        );
        Contact con2 = new Contact(
            FirstName = 'Maria',
            LastName = 'Santos',
            AccountId = acc1.Id,
            Title = 'Gerente de Contas',
            Email = 'maria@teste.com'
        );
        insert new List<Contact>{ con1, con2 };

        Test.startTest();
        List<AccountContactCardController.AccountCardDTO> cards = AccountContactCardController.getAccountCards();
        Test.stopTest();

        System.assert(cards.size() >= 2, 'Deveria retornar ao menos as 2 contas criadas');
        
        AccountContactCardController.AccountCardDTO vipCard;
        for (AccountContactCardController.AccountCardDTO c : cards) {
            if (c.id == acc1.Id) {
                vipCard = c;
                break;
            }
        }
        
        System.assertNotEquals(null, vipCard, 'Conta VIP deve estar presente');
        System.assertEquals(true, vipCard.isVip, 'Conta deve estar marcada como VIP');
        System.assertEquals('Cliente Chave', vipCard.statusLabel, 'Status label deve ser Cliente Chave');
        System.assertEquals(2, vipCard.contactCount, 'Conta deve ter 2 contatos associados');
        System.assertEquals('GS', vipCard.contacts[0].initials, 'Iniciais do Gabriel Silva devem ser GS');
        System.assertEquals('Decisor', vipCard.contacts[0].roleBadge, 'VP deve ter roleBadge Decisor');
    }
}
