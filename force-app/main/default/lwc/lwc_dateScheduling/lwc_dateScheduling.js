import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

const FIELDS = ['Id','Name','Contacts'];

//Labels
import labelBackButton from '@salesforce/label/c.backButton';
import labelNextButton from '@salesforce/label/c.nextButton';
import labelScheduleRequestButton from '@salesforce/label/c.scheduleRequestButton';

//Apex
import searchAccounts from '@salesforce/apex/dateSchedulingController.searchAccounts';
import getCenterHours from '@salesforce/apex/dateSchedulingController.getCenterHours';
import createAppointment from '@salesforce/apex/dateSchedulingController.createAppointment';


export default class Lwc_dateScheduling extends LightningElement {
    label = {
        labelBackButton,
        labelNextButton,
        labelScheduleRequestButton
    };
    @track selectedDate;
    @track selectedHour;
    @track selectedAccountId;
    @track selectedAccountLabel;
    @track selectedContactId;
    @track selectedContactLabel;

    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track phone = '';
    @track observations = '';

    @track validateDateError;
    @track validateEmptyFields;
    @track validateEmptyHour;

    @track currentPage = 1;
    @track showPage1 = true;
    @track showPage2 = false;
    @track showPage3 = false;
    @track showPage4 = false;

    @track showButtonNext = true;
    @track showButtonBack = false;
    @track showButtonEnd = false;

    @track termToSearch = '';
    @track searchTerm = '';
    @track accounts;
    @track accountOptions = [];
    @track contactOptions = [];

    @track hours = [];
    @track hourOptions = [];

    connectedCallback() {
        this.generateHours();
        this.generateHourOptions();
    }

    get formattedSelectedDate() {
        if (this.selectedDate) {
            const date = new Date(this.selectedDate);
            return date.toLocaleDateString('es-ES', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
        }
        return '';
    }

    get filteredContactOptions() {
        return this.contactOptions.filter(contact => contact.accountId === this.selectedAccountId);
    }

    @wire(searchAccounts, { searchQuery: '$searchTerm', objectApiName: ACCOUNT_OBJECT, fields: FIELDS })
    wiredAccounts({ error, data }) {
        if (data) {
            this.accounts = data.map(account => ({
                ...account,
                isSelected: account.Id === this.selectedAccountId
            }));

            this.accountOptions = this.accounts.map(account => ({
                label: account.Name,
                value: account.Id
            }));

            // Construir opciones para el combobox de contactos
            this.contactOptions = this.accounts.reduce((acc, account) => acc.concat(account.Contacts.map(contact => ({
                label: contact.Name,
                value: contact.Id,
                accountId: account.Id // Añadir la ID de la cuenta para filtrar
            }))), []);
        } else if (error) {
            console.error('Error al cargar cuentas:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error al cargar cuentas. Consulta la consola para más detalles.',
                    variant: 'error',
                })
            );
        }
    }

    isSelectedAccount(accountId) {
        return accountId === this.selectedAccountId;
    }

    //PAGINACION
    goNext() {
        if(this.currentPage == 1){
            const today = new Date();
            const selectedDateFormated = new Date(this.selectedDate);

            //Validamos que tengamos los campos necesarios
            if(selectedDateFormated < today){
                this.validateDateError = 'La fecha no puede ser menor de mañana';
            }else{
                this.validateDateError = '';
            }
            if(!this.selectedDate|| !this.selectedAccountId || !this.selectedContactId){
                this.validateEmptyFields = 'Los campos no pueden estar vacíos';
            }else{
                this.validateEmptyFields = '';
                this.generateHourOptions(); //Refrescamos las horas antes de filtrar
                this.getCenterHoursUpdate();
                
            }

            if(!this.validateEmptyFields && !this.validateDateError){
                this.currentPage++;
                this.paginateUpdate();
            }
        }else if(this.currentPage == 2){
            //Validamos que tengamos los campos necesarios
            console.log(this.selectedHour);
            if(!this.selectedHour){
                this.validateEmptyHour = 'El campo no puede estar vacío';
            }else{
                this.validateEmptyHour = '';
            }
            if(!this.validateEmptyHour){
                this.currentPage++;
                this.paginateUpdate();
            }
        }else if(this.currentPage == 3){
            if(!this.firstName || !this.lastName || !this.email || !this.phone || !this.observations){
                this.validateEmptyFields = 'Los campos no pueden estar vacíos';
            }else if(!this.email.includes('@')){
                this.validateEmptyFields = 'Debe ser un email válido';
            }else{
                this.validateDateError = '';
                this.currentPage++;
                this.paginateUpdate();
            }
        }
    }
    goBack() {        
        this.currentPage--;
        this.paginateUpdate();
    }

    goEnd() {
        // Llama al método de Apex para crear el registro
        createAppointment({ center: this.selectedAccountId, specialist: this.selectedContactId, dateAppoint: this.selectedDate , timeAppoint: this.selectedHour,
                                                                    firstName: this.firstName,lastName: this.lastName,email: this.email,phone: this.phone,observations: this.observations})
            .then(result => {
                // Maneja la respuesta del servidor
                if (result.startsWith('Error')) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Hubo un problema al realizar la operación.' + result,
                            variant: 'error',
                        })
                    );
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Éxito',
                            message: 'Cita creada con éxito. ID: ' + result,
                            variant: 'success',
                        })
                    );
                    //limpiamos los valores y devolvemos a la primera página
                    this.cleanValues();
                }
            })
            .catch(error => {
                console.log('createAppointment')
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error inesperado: ' + error.body.message,
                        variant: 'error',
                    })
                );
            });
    }

    generateHours() {
        const startHour = 8;
        const endHour = 20;
        const interval = 30;
        for (let hour = startHour; hour <= endHour; hour++) {
            for (let minute = 0; minute < 60; minute += interval) {
                const formattedHour = this.formatTime(hour, minute);
                this.hours.push(formattedHour);
            }
        }
    }

    generateHourOptions() {
        this.hourOptions = this.hours.map(hour => ({
            label: hour,
            value: hour
        }));
    }

    formatTime(hour, minute) {
        const formattedHour = hour < 10 ? '0' + hour : '' + hour;
        const formattedMinute = minute === 0 ? '00' : '' + minute;
        return `${formattedHour}:${formattedMinute}`;
    }

    handlePicklistChange(event) {
        this.selectedHour = event.detail.value;
    }

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
    }    
    
    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    handlePhoneChange(event) {
        this.phone = event.target.value;
    }

    handleObservationsChange(event) {
        this.observations = event.target.value;
    }

    handleAccountSelection(event) {
        this.selectedAccountId = event.detail.value;
        this.selectedAccountLabel = event.target.options.find(option => option.value === event.detail.value).label;

        this.selectedContactId = null; // Inicializar las variables de Especialista tras el cambio de Centro
        this.selectedContactLabel = null;
    }

    handleContactSelection(event) {
        this.selectedContactId = event.detail.value;
        this.selectedContactLabel = event.target.options.find(option => option.value === event.detail.value).label;
    }

    handleDateChange(event) {
        this.selectedDate = event.target.value;
    }

    handleSearchTermChange(event) {
        this.termToSearch = event.target.value;
    }

    handleSearch() {
        this.searchTerm = this.termToSearch
    }

    cleanValues() {
        this.selectedDate = null;
        this.selectedHour = null;
        this.selectedAccountId = null;
        this.selectedAccountLabel = null;
        this.selectedContactId = null;
        this.selectedContactLabel = null;
    
        this.firstname = null;
        this.lastname = null;
        this.email = null;
        this.phone = null;
        this.observations = null;
    
        this.currentPage = 1;
        this.paginateUpdate();
    }

    getCenterHoursUpdate(){
        getCenterHours({ centerId: this.selectedAccountId, specialistId: this.selectedContactId, dateAppoint: this.selectedDate })
                .then(result => {
                    // Maneja la respuesta del servidor
                    if (result.includes('Error')) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Ha ocurrido un error' + this.errorMessage,
                                variant: 'error',
                            })
                        );
                    } else {
                        if(result != ''){
                            this.hourOptions = this.hours.map(hour => {
                                if (!result.includes(hour)) {
                                    return {
                                        label: hour,
                                        value: hour
                                    };
                                }
                                return null; // Retorna null para indicar que el elemento debe ser excluido
                            }).filter(option => option !== null); // Filtra los elementos nulos para obtener el resultado final
                        }
                    }
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error inesperado: ' + error.body.message,
                            variant: 'error',
                        })
                    );
                });

                
    }

    paginateUpdate(){
        if(this.currentPage == 1){
            this.showButtonNext = true;
            this.showButtonEnd = false;
            this.showButtonBack = false;
            this.showPage1 = true;
            this.showPage2 = false;
            this.showPage3 = false;
            this.showPage4 = false;
        }else if(this.currentPage == 2){
            this.showButtonBack = true;
            this.showPage1 = false;
            this.showPage2 = true;
            this.showPage3 = false;
        }else if(this.currentPage == 3){
            this.showButtonNext = true;
            this.showButtonEnd = false;
            this.showPage2 = false;
            this.showPage3 = true;
            this.showPage4 = false;
        }else if(this.currentPage == 4){
            this.showButtonNext = false;
            this.showButtonEnd = true;
            this.showPage3 = false;
            this.showPage4 = true;
        }
    }
}