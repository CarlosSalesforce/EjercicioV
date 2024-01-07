public with sharing class dateSchedulingController {
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchQuery) {
        List<Account> accountList = new List<Account>();
        if(searchQuery != ''){
            String accountName = '%' + searchQuery + '%';
            accountList = [SELECT Id, Name, Appointment_Availability__c, (SELECT Id, Name FROM Contacts) FROM Account WHERE Name LIKE :accountName AND Appointment_Availability__c = true LIMIT 10];
        }
        return accountList;
    }

    @AuraEnabled
    public static String createAppointment(String center, String specialist, String dateAppoint, String timeAppoint, 
                                            String firstName,String lastName, String email, String phone, String observations) {
        List<Contact> clientsConSearchList = new List<Contact>();
        List<Lead> clientsLeadSearchList = new List<Lead>();
        Lead leadToCreate = New Lead();

        System.debug(lastName);
        try {
            if(email != null || phone != null){
                clientsConSearchList = [Select id from Contact where Email = :email OR Phone = :phone Limit 1];
                clientsLeadSearchList = [Select id from Lead where Email = :email OR Phone = :phone Limit 1];
            }

            if(clientsConSearchList.isempty() && clientsLeadSearchList.isempty()){
                leadToCreate.FirstName = firstName;
                leadToCreate.LastName = lastName;
                leadToCreate.Email = email;
                leadToCreate.Phone = phone;
                leadToCreate.Company = 'Appointment';
                insert leadToCreate;
            }

            String combinedDateTimeStr = dateAppoint + ' ' + timeAppoint + ':00';
            Datetime combinedDateTimeUTC = Datetime.valueOf(combinedDateTimeStr);

            // Crea una nueva instancia del objeto personalizado Appointment__c
            Appointment__c newAppointment = new Appointment__c(
                Center__c = center,
                Specialist__c = specialist,
                Time_Slot__c = combinedDateTimeUTC,
                Comments__c = observations,
                Client__c =  !clientsConSearchList.isempty() ? clientsConSearchList[0].id : null
            );
            if(clientsLeadSearchList.isempty() && leadToCreate.id != null){
                newAppointment.Potential_Client__c = leadToCreate.id;
            }else if(!clientsLeadSearchList.isempty()){
                newAppointment.Potential_Client__c = clientsLeadSearchList[0].id;
            }

            insert newAppointment;

            // Devuelve el ID del nuevo registro creado
            return newAppointment.Id;
        } catch (Exception e) {
            // Maneja cualquier error y devuelve un mensaje de error
            return 'Error al crear la cita o el cliente: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String getCenterHours(String centerId, String specialistId, String dateAppoint) {
        String descartedHours = '';
        try {
            DateTime dateAppointStart = Date.valueOf(dateAppoint);
            DateTime dateAppointEnd = dateAppointStart.addDays(1);

            List<Appointment__c> appointList = [Select  id,Center__c, Specialist__c, Time_Slot__c  from Appointment__c Where 
                                                                        Center__c = :centerId AND Specialist__c = :specialistId AND 
                                                                        Time_Slot__c >= :dateAppointStart AND Time_Slot__c < :dateAppointEnd];
            if(!appointList.isempty()){
                for(Appointment__c appoint : appointList){
                    system.debug(appoint);
                    descartedHours = descartedHours == null ? appoint.Time_Slot__c.format('HH:mm') : descartedHours + ',' + appoint.Time_Slot__c.format('HH:mm');
                }
            }
            return descartedHours;
        } catch (Exception e) {
            // Maneja cualquier error y devuelve un mensaje de error
            return 'Error al obtener el horario: ' + e.getMessage();
        }
    }
}