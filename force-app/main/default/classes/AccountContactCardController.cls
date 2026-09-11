public with sharing class AccountContactCardController {

    @AuraEnabled(cacheable=true)
    public static List<AccountCardDTO> getAccountCards() {
        List<AccountCardDTO> dtoList = new List<AccountCardDTO>();

        List<Account> accounts = [
            SELECT Id, Name, Industry, BillingCity, BillingState, Phone, Rating, AnnualRevenue,
                (SELECT Id, Name, FirstName, LastName, Title, Phone, Email FROM Contacts ORDER BY Name ASC)
            FROM Account
            WITH USER_MODE
            ORDER BY Name ASC
            LIMIT 50
        ];

        for (Account acc : accounts) {
            AccountCardDTO card = new AccountCardDTO();
            card.id = acc.Id;
            card.name = acc.Name;
            card.industry = String.isNotBlank(acc.Industry) ? acc.Industry : 'Geral';
            
            List<String> locParts = new List<String>();
            if (String.isNotBlank(acc.BillingCity)) {
                locParts.add(acc.BillingCity);
            }
            if (String.isNotBlank(acc.BillingState)) {
                locParts.add(acc.BillingState);
            }
            card.location = !locParts.isEmpty() ? String.join(locParts, ', ') : 'Localização não informada';
            
            card.phone = String.isNotBlank(acc.Phone) ? acc.Phone : '';
            card.hasPhone = String.isNotBlank(acc.Phone);
            
            // Classificação e status
            if (acc.Rating == 'Hot' || (acc.AnnualRevenue != null && acc.AnnualRevenue >= 50000000)) {
                card.statusLabel = 'Cliente Chave';
                card.statusVariant = 'vip';
                card.isVip = true;
            } else if (acc.Rating == 'Warm' || (acc.Contacts != null && !acc.Contacts.isEmpty())) {
                card.statusLabel = 'Ativa';
                card.statusVariant = 'success';
                card.isVip = false;
            } else {
                card.statusLabel = 'Em Prospecção';
                card.statusVariant = 'warning';
                card.isVip = false;
            }

            card.iconName = getIndustryIcon(acc.Industry);

            card.contacts = new List<ContactDTO>();
            if (acc.Contacts != null && !acc.Contacts.isEmpty()) {
                for (Contact con : acc.Contacts) {
                    ContactDTO cDto = new ContactDTO();
                    cDto.id = con.Id;
                    cDto.name = con.Name;
                    cDto.title = String.isNotBlank(con.Title) ? con.Title : 'Contato Associado';
                    cDto.phone = String.isNotBlank(con.Phone) ? con.Phone : (card.hasPhone ? card.phone : '');
                    cDto.email = String.isNotBlank(con.Email) ? con.Email : '';
                    cDto.hasEmail = String.isNotBlank(con.Email);
                    
                    cDto.initials = getInitials(con.FirstName, con.LastName, con.Name);
                    cDto.roleBadge = getRoleBadge(con.Title);
                    
                    card.contacts.add(cDto);
                }
            }
            card.contactCount = card.contacts.size();
            dtoList.add(card);
        }

        return dtoList;
    }

    private static String getInitials(String first, String last, String fullName) {
        String initials = '';
        if (String.isNotBlank(first)) {
            initials += first.substring(0, 1).toUpperCase();
        }
        if (String.isNotBlank(last)) {
            initials += last.substring(0, 1).toUpperCase();
        }
        if (String.isBlank(initials) && String.isNotBlank(fullName)) {
            List<String> parts = fullName.split(' ');
            if (parts.size() >= 2) {
                initials = parts[0].substring(0, 1).toUpperCase() + parts[parts.size() - 1].substring(0, 1).toUpperCase();
            } else {
                initials = fullName.substring(0, Math.min(2, fullName.length())).toUpperCase();
            }
        }
        return String.isNotBlank(initials) ? initials : 'CT';
    }

    private static String getIndustryIcon(String industry) {
        if (String.isBlank(industry)) return 'standard:account';
        String ind = industry.toLowerCase();
        if (ind.contains('tech') || ind.contains('elec')) return 'standard:custom_notification';
        if (ind.contains('apparel') || ind.contains('manuf')) return 'standard:work_order';
        if (ind.contains('construct')) return 'standard:home';
        if (ind.contains('hospit')) return 'standard:service_resource';
        if (ind.contains('energy')) return 'standard:lightning_usage';
        if (ind.contains('bio') || ind.contains('health')) return 'standard:health_and_wellness';
        return 'standard:account';
    }

    private static String getRoleBadge(String title) {
        if (String.isBlank(title)) return '';
        String t = title.toLowerCase();
        if (t.contains('vp') || t.contains('cfo') || t.contains('ceo') || t.contains('diretor') || t.contains('president')) {
            return 'Decisor';
        }
        if (t.contains('svp') || t.contains('gerente') || t.contains('senior') || t.contains('lead')) {
            return 'Key Contact';
        }
        return '';
    }

    public class AccountCardDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String industry { get; set; }
        @AuraEnabled public String location { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public Boolean hasPhone { get; set; }
        @AuraEnabled public String statusLabel { get; set; }
        @AuraEnabled public String statusVariant { get; set; }
        @AuraEnabled public Boolean isVip { get; set; }
        @AuraEnabled public String iconName { get; set; }
        @AuraEnabled public Integer contactCount { get; set; }
        @AuraEnabled public List<ContactDTO> contacts { get; set; }
    }

    public class ContactDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public Boolean hasEmail { get; set; }
        @AuraEnabled public String initials { get; set; }
        @AuraEnabled public String roleBadge { get; set; }
    }
}
