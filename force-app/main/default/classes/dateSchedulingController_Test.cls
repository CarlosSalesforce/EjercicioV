@isTest
private class dateSchedulingController_Test {

    public static map<String,String> generateDataRecieved (Id cuenta, Id especialista){
        Map<String,String> dataRecieved = new Map<String, String>{
            'center' => cuenta,
            'specialist' => especialista,
            'dateAppoint' => '2024-01-07',
            'timeAppoint' => '10:30',
            'firstName' => 'Nuevo',
            'lastName' => 'Lead',
            'email' => 'cliente@gmail.com',
            'phone' => '112223344',
            'observations' => 'Texto de ejemplo'
        };
        return dataRecieved;
    }

    public static Account initializeAccount(){
        Account cuenta = new Account(Name = 'Mi Cuenta de Prueba', Appointment_Availability__c = true);
        insert cuenta;
        return cuenta;
    }

    @isTest
    static void testBuscarCuentaConContactoAsociado() {
        Account cuenta = initializeAccount();

        Contact contacto = new Contact(FirstName = 'Juan', LastName = 'Perez', AccountId = cuenta.Id);
        insert contacto;

        Test.startTest();
        List<Account> cuentasConContacto = dateSchedulingController.searchAccounts('Prueba');
        Test.stopTest();

        Assert.areNotEqual(0, cuentasConContacto.size(), 'No se encontraron cuentas con contacto asociado.');
    }

    @isTest
    static void testCrearCitaEncontrandoContacto() {
        Account cuenta = initializeAccount();

        List<Contact> contactInsertList = new List<Contact>();
        Contact especialista = new Contact(FirstName = 'Juan', LastName = 'Especialista', Email = 'test@gmail.com', AccountId = cuenta.Id);
        contactInsertList.add(especialista);
        Contact cliente = new Contact(FirstName = 'Pepe', LastName = 'Cliente', Email = 'cliente@gmail.com');
        contactInsertList.add(cliente);
        insert contactInsertList;

        Test.startTest();

        Map<String,String> data = generateDataRecieved(cuenta.id,especialista.id);

        String idAppointmentCreado = dateSchedulingController.createAppointment(data.get('center'),data.get('specialist'),data.get('dateAppoint'),data.get('timeAppoint'),data.get('firstName'),data.get('lastName'),data.get('email'),data.get('phone'),data.get('observations'));
        Assert.areNotEqual(0, idAppointmentCreado.length(), 'No se ha creado Cita');

        Appointment__c appoint = [Select id,Client__c from Appointment__c LIMIT 1];
        Assert.areNotEqual(null, appoint.Client__c, 'No se encontro cliente asociado a la Cita');

        Test.stopTest();
    }

    @isTest
    static void testCrearCitaEncontrandoLead() {
        Account cuenta = initializeAccount();

        Contact especialista = new Contact(FirstName = 'Juan', LastName = 'Especialista', Email = 'test@gmail.com', AccountId = cuenta.Id);
        insert especialista;
        Lead clientePotencial = new Lead(FirstName = 'Pepe', LastName = 'Cliente', Email = 'cliente@gmail.com', Company = 'Appointment');
        insert clientePotencial;

        Map<String,String> data = generateDataRecieved(cuenta.id,especialista.id);
        
        Test.startTest();

        String idAppointmentCreado = dateSchedulingController.createAppointment(data.get('center'),data.get('specialist'),data.get('dateAppoint'),data.get('timeAppoint'),data.get('firstName'),data.get('lastName'),data.get('email'),data.get('phone'),data.get('observations'));
        Assert.areNotEqual(0, idAppointmentCreado.length(), 'No se ha creado Cita');

        Appointment__c appoint = [Select id,Potential_Client__c from Appointment__c LIMIT 1];
        Assert.areNotEqual(null, appoint.Potential_Client__c, 'No se encontro cliente asociado a la Cita');

        Test.stopTest();
    }
    
    @isTest
    static void testCrearCitaNoClienteCrearLead() {
        Account cuenta = initializeAccount();

        List<Contact> contactInsertList = new List<Contact>();
        Contact especialista = new Contact(FirstName = 'Juan', LastName = 'Especialista', Email = 'test@gmail.com', AccountId = cuenta.Id);
        contactInsertList.add(especialista);
        insert contactInsertList;

        Map<String,String> data = generateDataRecieved(cuenta.id,especialista.id);
 
        Test.startTest();

        String idAppointmentCreado = dateSchedulingController.createAppointment(data.get('center'),data.get('specialist'),data.get('dateAppoint'),data.get('timeAppoint'),data.get('firstName'),data.get('lastName'),data.get('email'),data.get('phone'),data.get('observations'));
        Assert.areNotEqual(0, idAppointmentCreado.length(), 'No se ha creado Cita');

        Appointment__c appoint = [Select id,Potential_Client__c from Appointment__c LIMIT 1];
        Assert.areNotEqual(null, appoint.Potential_Client__c, 'No se encontro cliente asociado a la Cita');

        Test.stopTest();
    }    

    @isTest
    static void testCrearCitaNoClienteErrorCrearLead() {
        Account cuenta = initializeAccount();

        List<Contact> contactInsertList = new List<Contact>();
        Contact especialista = new Contact(FirstName = 'Juan', LastName = 'Especialista', Email = 'test@gmail.com', AccountId = cuenta.Id);
        contactInsertList.add(especialista);
        insert contactInsertList;

        String email = 'cliente.gmail.com'; //Email erroneo

        Map<String,String> data = generateDataRecieved(cuenta.id,especialista.id);

        Test.startTest();

        String idAppointmentCreado = dateSchedulingController.createAppointment(data.get('center'),data.get('specialist'),data.get('dateAppoint'),data.get('timeAppoint'),data.get('firstName'),data.get('lastName'),email,data.get('phone'),data.get('observations'));
        Assert.areNotEqual(false, idAppointmentCreado.contains('Error al crear'), 'No ha ocurrido un error');

        List<Appointment__c> appointList = [Select id,Potential_Client__c from Appointment__c LIMIT 1];
        Assert.areNotEqual(null, appointList, 'Se encontro cliente asociado a la Cita');

        Test.stopTest();
    }

    @isTest
    static void testObtenerHorasCitasPrevias() {
        Account cuenta = initializeAccount();

        List<Contact> contactInsertList = new List<Contact>();
        Contact especialista = new Contact(FirstName = 'Juan', LastName = 'Especialista', Email = 'test@gmail.com', AccountId = cuenta.Id);
        contactInsertList.add(especialista);
        insert contactInsertList;

        Map<String,String> data = generateDataRecieved(cuenta.id,especialista.id);

        Test.startTest();

        String idAppointmentCreado = dateSchedulingController.createAppointment(data.get('center'),data.get('specialist'),data.get('dateAppoint'),data.get('timeAppoint'),data.get('firstName'),data.get('lastName'),data.get('email'),data.get('phone'),data.get('observations'));
        Assert.areNotEqual(0, idAppointmentCreado.length(), 'No se ha creado Cita');

        String horasObtenidas = dateSchedulingController.getCenterHours(data.get('center'),data.get('specialist'),data.get('dateAppoint'));
        Assert.areNotEqual('', horasObtenidas, 'No hemos recibido la hora de la cita creada');

        Test.stopTest();
    }

    @isTest
    static void testErrorObtenerHorasCitasPrevias() {
        Account cuenta = initializeAccount();

        List<Contact> contactInsertList = new List<Contact>();
        Contact especialista = new Contact(FirstName = 'Juan', LastName = 'Especialista', Email = 'test@gmail.com', AccountId = cuenta.Id);
        contactInsertList.add(especialista);
        insert contactInsertList;

        Map<String,String> data = generateDataRecieved(cuenta.id,especialista.id);

        Test.startTest();

        String idAppointmentCreado = dateSchedulingController.createAppointment(data.get('center'),data.get('specialist'),data.get('dateAppoint'),data.get('timeAppoint'),data.get('firstName'),data.get('lastName'),data.get('email'),data.get('phone'),data.get('observations'));
        Assert.areNotEqual(0, idAppointmentCreado.length(), 'No se ha creado Cita');

        String horasObtenidas = dateSchedulingController.getCenterHours(data.get('center'),data.get('specialist'),data.get('firstName'));// forzamos el error mandando fecha erronea
        Assert.areNotEqual(false, horasObtenidas.contains('Error al obtener el horario'), 'No ha ocurrido un error');

        Test.stopTest();
    }

}