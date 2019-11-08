const {
    isNotNullOrEmpty, 
    validateRelationBetweenAdditionalProcurementCategoriesAndMainProcurementCategory,
    validateRelationBetweenProcurementMethodDetailsAndProcurementMethod,
    validateProcurementMethodDetails,
    validateTypeOfDocument,
    validateUniqueId,
    getSpanishMainProcurementCategory} = require('../utilities/validation-rules');

const {getValueStatus, TypesOfStatus} = require('../utilities/status');

/**
 * Validación de un proceso
 *
 * @param {Number} cpid ID del contractingprocess
 * @param {IDBDatabase} db Instancia de la base de datos
 */
function ValidateProcess(cpid, db) {
    const _cpid = cpid;
    const _db = db;
    let errs = 0, warns = 0;
    
    /**
     *  Validar todo el proceso
     */
    this.validate = async function(){
        let log = await _db.oneOrNone('select release_json json from logs where contractingprocess_id = $1 order by id desc limit 1', [_cpid]);
        if(!log || !log.json) throw Error('Es necesario generar la entrega(release) antes de realizar la validación');
        let json = log.json;
        // mesajes para validacion de datos
        let data = {},
        // mensajes para validacion de captura
            capture = {};
        let codeList = await _db.manyOrNone('select classificationid from item');

        addError(data,'Identificador OCID', !/.{18}/.test(json.ocid), 'El identificador OCID no cuenta con la longitud esperada. Considerar que el Identificador OCID se construye con el prefijo (ocds-g4facg), guion (-) y el número de registro (PC0001). Por ejemplo: ocds-g4facg-PC0001. Para mayor información, consulte: http://bit.ly/OrientacionEDCA.', json.ocid)

        // validacion de actores       
        if(json.parties){
            data['Actores'] = [];
            capture['Actores'] = [];
            json.parties.map((party, index) => {
                let message = {id: party.id || index};
                addError(message,'Identificador del actor', party.id && !validateUniqueId(party.id, json.parties), 'Existen varios actores con el mismo identificador', party.id);
                addError(message,'Identificador del actor', party.id &&  party.identifier && party.id !== `${party.identifier.scheme}-${party.identifier.id}`, 'La entrada de datos no corresponde con la estructura solicitada. Utilizar los atributos "Esquema" e "Identificador" del apartado "Identificador principal"', party.id);
                addError(message,'Esquema', party.identifier && isNotNullOrEmpty(party.identifier.scheme) && !/^RFC|CUA$/.test(party.identifier.scheme.toUpperCase()) , 'La entrada de datos no tiene la longitud esperada según el esquema de identificación definido. Esto puede deberse a que faltan caracteres en el RFC o la CUA.', party.identifier ? party.identifier.scheme : '');
                addError(message,'Esquema', !party.identifier|| !isNotNullOrEmpty(party.identifier.scheme), 'Obligatorio');
                addError(message,'Identificador', party.identifier && party.identifier.id && (party.identifier.scheme && party.identifier.scheme.toUpperCase() === 'RFC' && party.identifier.id ? !(party.identifier.id.length >= 11 && party.identifier.id.length < 14) : party.identifier.id.length !== 3), 'La entrada de datos no tiene la longitud esperada según el esquema de identificación definido. Esto puede deberse a que faltan caracteres en el RFC o la CUA.', party.identifier ? party.identifier.id: '');
                addError(message,'Código postal', party.address && party.address.postalCode && !/\d{5}/.test(party.address.postalCode), 'La entrada de datos no tiene la longitud esperada para ser un código postal. En México, los códigos postales son de cinco dígitos.', party.address ? party.address.postalCode: '');     
                if(Object.keys(message).length > 1) data['Actores'].push(clean(message));
                
                message = {id: party.id || index};
                addWarning(message,'Nombre común', !isNotNullOrEmpty(party.name), 'Obligatorio');
                addWarning(message,'Identificador del actor', !isNotNullOrEmpty(party.id), 'Obligatorio');
                addWarning(message,'Identificador', !party.identifier || !isNotNullOrEmpty(party.identifier.id), 'Obligatorio');
                addWarning(message,'Nombre o razón social', !party.identifier || !isNotNullOrEmpty(party.identifier.legalName), 'Obligatorio');
                addWarning(message,'Calle y número', !party.address || !isNotNullOrEmpty(party.address.streetAddress), 'Obligatorios');            
                addWarning(message,'Delegación o municipio', !party.address || !isNotNullOrEmpty(party.address.locality), 'Obligatorio');
                addWarning(message,'Entidad federativa', !party.address || !isNotNullOrEmpty(party.address.region), 'Obligatoria');
                addWarning(message,'País', !party.address || !isNotNullOrEmpty(party.address.countryName), 'Obligatorio');
                addWarning(message,'Código postal', !party.address || !party.address.postalCode, 'Obligatorio');
                addWarning(message,'Nombre del punto de contacto', !party.contactPoint || !isNotNullOrEmpty(party.contactPoint.name), 'Obligatorio');
                addWarning(message,'Correo electrónico', !party.contactPoint || !isNotNullOrEmpty(party.contactPoint.email), 'Obligatorio');
                addWarning(message,'Teléfono', !party.contactPoint || !isNotNullOrEmpty(party.contactPoint.telephone), 'Obligatorio');
                addWarning(message,'Roles', !party.roles, 'Debe tener por lo menos un rol');
                if(Object.keys(message).length > 1) capture['Actores'].push(clean(message));
            });
        } else{
            data['Actores'] = 'No se ha registrado ningún actor';
            errs++;
        }
        
        
        // validacion de planeacion
        let planningData = data['Planeación'] = {},
            planningCapture = capture['Planeación'] = {};

        addError(planningData, 'Justificación', json.planning && json.planning.rationale && json.planning.rationale.length > 900, 'La justificación de la contratación no debe extenderse más allá de 900 caracteres.', json.planning ? json.planning.rationale : '');
        
        addWarning(planningCapture, 'Identificador', !json.planning || !json.planning.budget || !isNotNullOrEmpty(json.planning.budget.id), 'Obligatorio');
        addWarning(planningCapture, 'Denominación de los componentes de la clave presupuestaria', !json.planning || !json.planning.budget || !isNotNullOrEmpty(json.planning.budget.description), 'Obligatoria');
        addWarning(planningCapture, 'Monto', !json.planning || !json.planning.budget || !json.planning.budget.amount ||  !json.planning.budget.amount.amount, 'Obligatorio');
        addWarning(planningCapture, 'Moneda', !json.planning || !json.planning.budget || !json.planning.budget.amount ||  !json.planning.budget.amount.currency, 'Obligatoria');
        addWarning(planningCapture, 'Justificación', !json.planning || !isNotNullOrEmpty(json.planning.rationale), 'Obligatoria');
        
        addDocuments(planningData, planningCapture, json.planning ? json.planning.documents : [], 'planning');

        // validacion de licitacion
        let dataTender = data['Licitación'] = {},
            captureTender = capture['Licitación'] = {};
            
        addError(dataTender, 'Detalles del método de contratación', json.tender && !validateRelationBetweenProcurementMethodDetailsAndProcurementMethod(json.tender.procurementMethodDetails, json.tender.procurementMethod), 'La selección del método de contratación no coincide con el tipo de procedimiento elegido en "Detalles del método de contratación". Para más información, consultar la tabla de equivalencias en la presentación: http://bit.ly/OrientacionEDCA.', json.tender ? json.tender.procurementMethodDetails : '');
        addError(dataTender, 'Categoría principal de la contratación', json.tender && json.tender.additionalProcurementCategories && !validateRelationBetweenAdditionalProcurementCategoriesAndMainProcurementCategory(json.tender.additionalProcurementCategories[0],json.tender.mainProcurementCategory), 'La categoría principal de la contratación especificada no coincide con la categoría adicional especificada.' ,json.tender ? json.tender.additionalProcurementCategories : []);
        addError(dataTender, 'Número de licitantes', json.tender && json.parties && (json.tender.numberOfTenderers !== json.parties.filter(p =>  p.roles && p.roles.indexOf('tenderer') !== - 1).length), 'La cantidad de licitantes especificada no coincide con los registros en la sección "Actores involucrados". Considerar que en adjudicación directa los licitantes serán aquellos que presentaron una oferta.', json.tender ? json.tender.numberOfTenderers : 0);   

        addWarning(captureTender, 'Identificador de la licitación', !json.tender || !isNotNullOrEmpty(json.tender.id), 'Obligatorio');
        addWarning(captureTender, 'Denominación de la licitación', !json.tender || !isNotNullOrEmpty(json.tender.title), 'Obligatoria');
        addWarning(captureTender, 'Objeto de la licitación', !json.tender || !isNotNullOrEmpty(json.tender.id), 'Obligatorio');
        addWarning(captureTender, 'Estatus de la licitación', !json.tender || !isNotNullOrEmpty(json.tender.status), 'Obligatorio');
        addWarning(captureTender, 'Monto de Valor', !json.tender || !json.tender.value || !json.tender.value.amount, 'Obligatorio');
        addWarning(captureTender, 'Moneda', !json.tender || !json.tender.value || !isNotNullOrEmpty(json.tender.value.currency), 'Obligatoria');
        addWarning(captureTender, 'Método de contratación', !json.tender || !isNotNullOrEmpty(json.tender.procurementMethod), 'Obligatorio');
        addWarning(captureTender, 'Detalles del método de contratación', !json.tender || !isNotNullOrEmpty(json.tender.procurementMethodDetails), 'Obligatorios');
        addWarning(captureTender, 'Justificación del método de contratación', !json.tender || !isNotNullOrEmpty(json.tender.procurementMethodRationale), 'Obligatoria');
        addWarning(captureTender, 'Categoría principal de la contratación', !json.tender || !isNotNullOrEmpty(json.tender.mainProcurementCategory), 'Obligatoria');
        addWarning(captureTender, 'Categorías adicionales de contratación', !json.tender || !json.tender.additionalProcurementCategories, 'Obligatorias');
        addWarning(captureTender, 'Criterio de evaluación de proposiciones', !json.tender || !isNotNullOrEmpty(json.tender.awardCriteria), 'Obligatorio');
        addWarning(captureTender, 'Detalles sobre el criterio de evaluación de proposiciones', !json.tender || !isNotNullOrEmpty(json.tender.awardCriteriaDetails), 'Obligatorios');
        addWarning(captureTender, 'Medios para la recepción de las proposiciones', !json.tender || !json.tender.submissionMethod, 'Obligatorios');
        addWarning(captureTender, 'Descripción de los medios para la recepción de las proposiciones', !json.tender || !isNotNullOrEmpty(json.tender.submissionMethodDetails), 'Obligatoria');
        addWarning(captureTender, 'Fecha de inicio de Período de entrega de proposiciones', !json.tender || !json.tender.tenderPeriod || !json.tender.tenderPeriod.startDate, 'Obligatoria');
        addWarning(captureTender, 'Fecha de fin de Período de entrega de proposiciones', !json.tender || !json.tender.tenderPeriod || !json.tender.tenderPeriod.endDate, 'Obligatoria');
        addWarning(captureTender, 'Fecha de inicio de Período para presentar solicitudes de aclaración', !json.tender || !json.tender.enquiryPeriod || !json.tender.enquiryPeriod.startDate, 'Obligatoria');
        addWarning(captureTender, 'Fecha de fin de Período para presentar solicitudes de aclaración', !json.tender || !json.tender.enquiryPeriod || !json.tender.enquiryPeriod.endDate, 'Obligatoria');
        addWarning(captureTender, '¿Hubo solicitudes de aclaración?', !json.tender || json.tender.hasEnquiries === undefined, 'Obligatorio');
        addWarning(captureTender, 'Criterios de elegibilidad', !json.tender || !isNotNullOrEmpty(json.tender.eligibilityCriteria), 'Obligatoria');
        addWarning(captureTender, 'Fecha de inicio de Período de evaluación y adjudicación', !json.tender || !json.tender.awardPeriod || !json.tender.awardPeriod.startDate, 'Obligatoria');
        addWarning(captureTender, 'Fecha de fin de Período de evaluación y adjudicación', !json.tender || !json.tender.awardPeriod || !json.tender.awardPeriod.endDate, 'Obligatoria');
        addWarning(captureTender, 'Número de licitantes', !json.tender || !json.tender.numberOfTenderers, 'Obligatorio');
        
        addAmendment(dataTender, captureTender, json.tender ? json.tender.amendments : []);
        addDocuments(dataTender, captureTender, json.tender ? json.tender.documents: [], 'tender');
        addItems(dataTender, captureTender, json.tender ? json.tender.items: [], codeList);

        // validacion de adjudicacion
        if(json.awards){
            let dataAwards = data['Adjudicaciones'] = [];
            let captureAwards = capture['Adjudicaciones'] = [];
            json.awards.map((award, index) => {
                let messageData = {id: award.id || index};
                let messageCapture = {id: award.id || index};

                // ignorar si todo esta vacio
                if(Object.keys(award).length === 0){
                    return;
                }

                addError(messageData,'Identificador del la adjudicación', award.id && !validateUniqueId(award.id, json.awards), 'Existen varias adjudicaciones con el mismo identificador', award.id);
                addError(messageData, 'Monto sin impuestos', !award.value || award.value.netAmount <= 0 , 'El monto especificado no puede ser cero.', award.value ? award.value.netAmount : '');
                
                addWarning(messageCapture, 'Identificador de la adjudicación', !isNotNullOrEmpty(award.id), 'Obligatorio');
                addWarning(messageCapture, 'Título', !isNotNullOrEmpty(award.title), 'Obligatorio');
                addWarning(messageCapture, 'Descripción',!isNotNullOrEmpty(award.description), 'Obligatorio');
                addWarning(messageCapture, 'Estatus de adjudicación', !isNotNullOrEmpty(award.status), 'Obligatorio');
                addWarning(messageCapture, 'Fecha de la adjudicación', !award.date, 'Obligatoria');
                addWarning(messageCapture, 'Monto', !award.value || !award.value.amount , 'Obligatorio');
                addWarning(messageCapture, 'Moneda', !award.value || !isNotNullOrEmpty(award.value.currency) , 'Obligatoria');
                addWarning(messageCapture, 'Proveedores', !award.suppliers, 'No ha seleccionado ningún proveedor');
                addWarning(messageCapture, 'Fecha de inicio', !award.contractPeriod || !award.contractPeriod.startDate, 'Obligatoria');
                addWarning(messageCapture, 'Fecha de fin', !award.contractPeriod || !award.contractPeriod.endDate, 'Obligatoria');

                addAmendment(messageData,messageCapture, award.amendments);
                addDocuments(messageData,messageCapture, award.documents, 'award');
                addItems(messageData,messageCapture, award.items, codeList);

                if(Object.keys(messageData).length > 1) dataAwards.push(messageData);
                if(Object.keys(messageCapture).length > 1) captureAwards.push(messageCapture);
            });
        } else{
            data['Adjudicaciones'] = 'No se ha registrado ningúna adjudicación';
            errs++;
        }

        // validacion de contratos
        if(json.contracts) {
            let dataContracts = data['Contratos'] = [],
                captureContracts = capture['Contratos'] = [];
            json.contracts.map((contract, index) => {
                let messageData = {id: contract.id || index};
                let messageCapture = {id: contract.id || index};


                 // ignorar si todo esta vacio
                 if(Object.keys(contract).length === 0){
                     return;
                 }

                addError(messageData,'Identificador del contrato', contract.id && !validateUniqueId(contract.id, json.contracts), 'Existen varios contratos con el mismo identificador', contract.id);
                addError(messageData, 'Monto sin impuestos', contract.value && contract.value.netAmount <= 0, 'El monto especificado no puede ser cero.', contract.value ? contract.value.netAmount : '');
                
                addWarning(messageCapture, 'Identificador del contrato', !isNotNullOrEmpty(contract.id), 'Obligatorio');
                addWarning(messageCapture, 'Identificador de la adjudicación', !isNotNullOrEmpty(contract.awardID), 'Obligatorio');
                addWarning(messageCapture, 'Título del contrato', !isNotNullOrEmpty(contract.title), 'Obligatorio');
                addWarning(messageCapture, 'Objeto del contrato', !isNotNullOrEmpty(contract.description), 'Obligatorio');
                addWarning(messageCapture, 'Estatus del contrato', !isNotNullOrEmpty(contract.status), 'Obligatorio');
                addWarning(messageCapture, 'Fecha de inicio', !contract.period || !contract.period.startDate, 'Obligatoria');
                addWarning(messageCapture, 'Fecha de fin', !contract.period || !contract.period.endDate, 'Obligatoria');
                addWarning(messageCapture, 'Monto sin impuestos', !contract.value || !contract.value.netAmount, 'Obligatorio');
                addWarning(messageCapture, 'Monto total', !contract.value || !contract.value.amount, 'Obligatorio');
                addWarning(messageCapture, 'Moneda', !contract.value || !isNotNullOrEmpty(contract.value.currency), 'Obligatoria');
                addWarning(messageCapture, 'Fecha de firma del contrato', !contract.dateSigned, 'Obligatoria');
                addAmendment(messageData, messageCapture, contract.amendments);
                addDocuments(messageData, messageCapture, contract.documents, 'contract');
                addItems(messageData, messageCapture, contract.items, codeList);

                // validacion de implementacion
                if(contract.implementation) {
                    let dataImplementation = messageData['Implementación'] = {};
                    let captureImplementation = messageCapture['Implementación'] = {};
                    addWarning(captureImplementation, 'Estatus de la implementación', !contract.implementation.status, 'Obligatorio');
                    addDocuments(dataImplementation,captureImplementation , contract.implementation.documents, 'implementation');
                    addTransactions(dataImplementation, captureImplementation, contract.implementation.transactions);
                } else {
                    messageData['Implementación'] = 'No se ha especificado la implementación' 
                    errs++;
                }
                messageData = clean(messageData);
                messageCapture = clean(messageCapture);
                if(Object.keys(messageData).length > 1) dataContracts.push(messageData);
                if(Object.keys(messageCapture).length > 1) captureContracts.push(messageCapture);
            });
        } else {
            data['Contratos'] = 'No se ha especificado ningún contrato';
            errs++;
        }
        
        
        
        data = clean(data);
        capture = clean(capture);

        return clean({
            valid: errs === 0,
            data: data,
            capture: capture,
            resume: generateResume(cpid, json)
        });
    }

    

    let addWarning = (obj, propety, error, message) => {
        if(error) {
            obj[propety] = message;
            warns++;
        } 
    }

    let addError = (obj, propety, error, message, value) => {
        if(error) {
            obj[propety] = {
                mensaje: message,
                valor: value
            };
            errs++;
        } 
    }

    let addAmendment = (obj, amendments) => {
        if(Array.isArray(amendments) && amendments){
            let mods = [];
            amendments.map((am, index) => {
                let message = {id: am.id || index};
                addWarning(message, 'Fecha de la modificación', !am.date, 'Obligatoria');
                addWarning(message, 'Descripción', !isNotNullOrEmpty(am.description), 'Obligatoria');
                addWarning(message, 'Justificación', !isNotNullOrEmpty(am.rationale), 'Obligatoria');
                if(Object.keys(message).length > 1) mods.push(message);
            });
            if(mods.length > 0) obj['Modificaciones'] = mods;
        }
    }

    let addDocuments = (data, capture, documents, stage) => {
        if(Array.isArray(documents) && documents){
            let docsData = [], docCapture = [];
            documents.map((doc, index) => {
                let message = {id: doc.id || index};
                addError(message,'Identificador', doc.id && !validateUniqueId(doc.id, documents), 'Existen varios documentos con el mismo identificador');
                addError(message, 'Tipo de documento', doc.documentType && validateTypeOfDocument(doc.documentType, stage), 'Obligatorio', doc.documentType);
                addError(message, 'Formato', doc.format && !/PDF|XLSX|DOCX|DOC|PNG|JPEG|JPG|XLS|CSV/.test(doc.format.toUpperCase()), 'La entrada de datos no coincide con un formato reconocido. En el caso de documentos ".pdf" especificar PDF.', doc.format);
                if(Object.keys(message).length > 1) docsData.push(message);
                message = {id: doc.id || index};

                addWarning(message, 'Identificador', !isNotNullOrEmpty(doc.id), 'Obligatorio');
                addWarning(message, 'Tipo de documento', !isNotNullOrEmpty(doc.documentType), 'Obligatorio');
                addWarning(message, 'Título', !isNotNullOrEmpty(doc.title), 'Obligatorio');
                addWarning(message, 'URL', !isNotNullOrEmpty(doc.url), 'Obligatorio');
                addWarning(message, 'Fecha de publicación', !doc.datePublished, 'Obligatorio');
                addWarning(message, 'Formato', !isNotNullOrEmpty(doc.format), 'Obligatorio');
                addWarning(message, 'Idioma', !isNotNullOrEmpty(doc.language), 'Obligatorio');
                if(Object.keys(message).length > 1) docCapture.push(message);
            });
            if(docsData.length > 0) data['Documentos'] = docsData;
            if(docCapture.length > 0) capture['Documentos'] = docCapture;
        }
    }

    let addTransactions = (data, capture, transactions) => {
        if(transactions && Array.isArray(transactions)) {
            let dataTrans = [], captureTrans = [];
            transactions.map((t, index) => {
                let message = {id: t.id || index};
                addError(message, 'Monto total', t.value && t.value.netAmount && parseFloat(t.value.netAmount) > t.value.amount, 'Monto total debe ser mayor o igual a monto sin impuestos',t.value ? t.value.amount : '');
                if(Object.keys(message).length > 1) dataTrans.push(message);

                message = {id: t.id || index};
                addWarning(message, 'Monto sin impuestos', !t.value || !t.value.netAmount, 'Obligatorio');
                addWarning(message, 'Monto total', !t.value || !t.value.amount, 'Obligatorio');
                addWarning(message, 'Moneda', !t.value || !isNotNullOrEmpty(t.value.currency), 'Obligatoria');
                addWarning(message, 'Método de pago', !t.paymentMethod, 'Obligatorio');
                addWarning(message, 'Emisor', !t.payer, 'No se ha seleccionado el Emisor');
                addWarning(message, 'Receptor', !t.payee, 'No se ha seleccionado el Receptor');
                if(Object.keys(message).length > 1) captureTrans.push(message);
            });
            if(dataTrans.length > 0) data['Transacciones'] = dataTrans;
            if(captureTrans.length > 0) capture['Transacciones'] = captureTrans;
        }
    }

    let addItems = (data, capture, items, codeList) => {
        if(items && Array.isArray(items)){
            let dataItems = [], captureItems = [];
            items.map((i, index) => {
                let message = {id: i.id || index};
                addError(message,'Identificador', i.id && !validateUniqueId(i.id, items), 'Existen varios items con el mismo identificador', i.id);
                addError(message, 'Nombre de la unidad de medida', i.unit && i.unit.name && codeList.filter(x => x.classificationid === i.unit.name) === -1, 'El nombre de la unidad de medida no coincide con la clave CUCOP introducida. Para mayor información, utilizar la herramienta de apoyo para obtener los valores de la clave CUCOP en http://bit.ly/ApoyoEDCA.', i.unit ? i.unit.name : '');
                addError(message, 'Identificador de Clasificación', i.classification && i.classification.id && i.classification.id.length !== 8, 'La entrada de datos no tiene la longitud esperada según el esquema de identificación CUCOP. La clave CUCOP consta de ocho caracteres.',  i.classification ? i.classification.id : '');
                addError(message, 'Esquema', i.classification && i.classification.scheme !== 'CUCOP', 'El esquema de identificación seleccionado no es el correcto. Utilizar la opción "CUCOP".', i.classification ? i.classification.scheme : '');  
                if(Object.keys(message).length > 1) dataItems.push(message);

                message = {id: i.id || index};
                addWarning(message, 'Identificador', !isNotNullOrEmpty(i.id), 'Obligatorio');
                addWarning(message, 'Descripción del ítem', !isNotNullOrEmpty(i.description), 'Obligatorio');
                addWarning(message, 'Esquema',!i.classification || !isNotNullOrEmpty(i.classification.scheme), 'Obligatorio');
                addWarning(message, 'Identificador de Clasificación', !i.classification || !isNotNullOrEmpty(i.classification.id), 'Obligatorio');
                addWarning(message, 'Descripción del identificador', !i.classification || !isNotNullOrEmpty(i.classification.description), 'Obligatoria');
                addWarning(message, 'Cantidad por tipo de bien, servicio u obra pública', !i.quantity, 'Obligatoria');
                addWarning(message, 'Nombre de la unidad de medida', !i.unit || !isNotNullOrEmpty(i.unit.name), 'Obligatorio');
                addWarning(message, 'Monto sin impuestos', !i.unit || !i.unit.netAmount, 'Obligatorio');
                addWarning(message, 'Monto total', !i.unit || !i.unit.amount, 'Obligatorio');
                addWarning(message, 'Moneda', !i.unit || !isNotNullOrEmpty(i.unit.currency), 'Obligatoria');
                if(Object.keys(message).length > 1) captureItems.push(message);
            });
            if(dataItems.length > 0)  data['Items'] = dataItems;
            if(captureItems.length > 0)  capture['Items'] = captureItems;
        }
    }

    let generateResume = function(cpid, json){
        let buyer =  json.parties ? json.parties.filter(p => p.roles && p.roles.indexOf('buyer') !== -1)[0]: undefined;
        let empty = 'Sin dato';
        let amount = 0;

        if(json.contracts){
            // calculo del saldo
            json.contracts.map(x => amount += x.value ? x.value.amount || 0 : 0);
            json.contracts.map(x =>  x.implementation && x.implementation.transactions ? x.implementation.transactions.map(t => {
                amount -= t.value ? t.value.amount || 0 : 0;
            }) : 0);
        }

        let resume = {
            registry: cpid,
            unitAdministrative: buyer ? buyer.name || empty : empty,
            identifier: buyer ? buyer.id || empty : empty,
            date: json.date,
            name: json.tender ? json.tender.title || empty : empty,
            type: json.tender ? json.tender.procurementMethodDetails || empty : empty,
            element: json.tender ? getSpanishMainProcurementCategory(json.tender.mainProcurementCategory) || empty : empty,
            missing: warns,
            errors: errs,
            total: countLength(json),
            status: getEtapaCaptura(json),
            stagesStatus:{
                tender: getValueStatus(TypesOfStatus.licitacion, json.tender.status),
                award:  json.awards ? json.awards.map(x => getValueStatus(TypesOfStatus.adjudicacion, x.status)).join(', '): empty,
                contract: json.contracts ? json.contracts.map(x => getValueStatus(TypesOfStatus.contratacion, x.status)).join(', ') : empty,
                implementation: json.contracts ? json.contracts.map(x => {
                    let value = getValueStatus(TypesOfStatus.ejecucion, x.implementation ? x.implementation.status : empty);
                    if(value) return value;
                }).join(', ') || empty : empty,
            },
            documents: {
                // Justificación de la contratación
                needsAssessment: getDocMessage('needsAssessment', json.planning && json.planning.documents ? json.planning.documents.findIndex(x => x.documentType === 'needsAssessment') !== -1 : false, json.tender.procurementMethodDetails),
                // Anexo técnico
                technicalSpecifications: getDocMessage('technicalSpecifications', json.tender && json.tender.documents ? json.tender.documents.findIndex(x => x.documentType === 'technicalSpecifications') !== -1 : false, json.tender.procurementMethodDetails),
                // Convocatoria
                tenderNotice: getDocMessage('tenderNotice', json.tender && json.tender.documents ? json.tender.documents.findIndex(x => x.documentType === 'tenderNotice') !== -1 : false, json.tender.procurementMethodDetails),
                // juntas de aclaraciones
                clarifications: getDocMessage('clarifications', json.tender && json.tender.documents ? json.tender.documents.findIndex(x => x.documentType === 'clarifications') !== -1 : false, json.tender.procurementMethodDetails),
                // estudio de mercado
                marketStudies: getDocMessage('marketStudies', json.planning && json.planning.documents ? json.planning.documents.findIndex(x => x.documentType === 'marketStudies') !== -1 : false, json.tender.procurementMethodDetails),
                // Plan de proyecto
                projectPlan:  getDocMessage('projectPlan', json.planning  && json.planning.documents? json.planning.documents.findIndex(x => x.documentType === 'projectPlan') !== -1 : false, json.tender.procurementMethodDetails),
                // Fallo o notificación
                awardNotice:  getDocMessage('awardNotice', json.awards ? json.awards.findIndex(y => y.documents ? y.documents.find(x => x.documentType === 'awardNotice') : false) !== -1 : false, json.tender.procurementMethodDetails) ,
                // Contrato firmado
                contractSigned: getDocMessage('contractSigned', json.contracts ? json.contracts.findIndex(y => y.documents ? y.documents.find(x => x.documentType === 'contractSigned') : false) !== -1 : false, json.tender.procurementMethodDetails) ,
                // Documento en el que conste la conclusión de la contratación
                completionCertificate: getDocMessage('completionCertificate', json.contracts ? json.contracts.findIndex(y => y.implementation && y.implementation.documents ? y.implementation.documents.find(x => x.documentType === 'completionCertificate') : false) !== -1 : false, json.tender.procurementMethodDetails),
            },
            parties: {
                buyer: buyer !== undefined ? 'Registrado' : 'No registrado',
                procuringEntity: json.parties && json.parties.filter(p => p.roles && p.roles.indexOf('procuringEntity') !== -1).length > 0 ? 'Registrado' : 'No registrado',
                supplier: json.parties && json.parties.filter(p => p.roles &&  p.roles.indexOf('supplier') !== -1).length > 0 ? 'Registrado' : 'No registrado',
                payer: json.parties && json.parties.filter(p => p.roles &&  p.roles.indexOf('payer') !== -1).length > 0 ? 'Registrado' : 'No registrado',
                payee: json.parties && json.parties.filter(p => p.roles &&  p.roles.indexOf('payee') !== -1).length > 0 ? 'Registrado' : 'No registrado',
                tenderer: json.parties && json.parties.filter(p => p.roles &&  p.roles.indexOf('tenderer') !== -1).length > 0 ? 'Registrado' : 'No registrado'
            },
            items: {
                tender: (json.tender && json.tender.items ?  json.tender.items.length > 0 : false)  ? 'Registrado' : 'No registrado',
                contracts: json.contracts ? json.contracts.map(x => x.items && x.items.length > 0 ? 'Registrado' : 'No registrado') : ['No registrado'] ,
            },
            transactions: json.contracts ? json.contracts.map(x => (x.implementation && x.implementation.transactions ? x.implementation.transactions.length > 0 : false) ? 'Registrado' : 'No registrado' ) : ['No registrado'],
            amount: amount
           
        };
        return resume;
    }

    let getDocMessage = (type, valid, method) => {
        let msPublished = 'El documento se encuentra público.',
            msNotPublished = 'El documento aún no se ha publicado.',
            msNotApply = 'No es necesaria la publicación de este documento';

        switch(type){
            case 'technicalSpecifications':
                switch(method){
                    case 'Adjudicación directa art.42':
                    case 'Adjudicación directa art.41':
                        return valid ? msPublished : msNotPublished;
                    case 'Licitación pública':
                    case 'Excepciones al reglamento':
                    case 'Invitación a cuando menos tres personas':
                    case 'Convenio de colaboración':
                        return msNotApply;;
                }
                break;
            case 'clarifications':
            case 'tenderNotice':
                    switch(method){
                        case 'Licitación pública':
                        case 'Invitación a cuando menos tres personas':
                            return valid ? msPublished : msNotPublished;
                        default:
                            return msNotApply;;
                    }
            case 'marketStudies':
            case 'projectPlan':
            case 'awardNotice':
            case 'needsAssessment':
                switch(method){
                    case 'Licitación pública':
                    case 'Adjudicación directa art.42':
                    case 'Adjudicación directa art.41':
                    case 'Invitación a cuando menos tres personas':
                        return valid ? msPublished : msNotPublished;
                    default:
                        return msNotApply;
                }
            case 'contractSigned':
            case 'completionCertificate':
                switch(method){
                    case 'Licitación pública':
                    case 'Adjudicación directa art.42':
                    case 'Adjudicación directa art.41':
                    case 'Excepciones al reglamento':
                    case 'Invitación a cuando menos tres personas':
                    case 'Convenio de colaboración':
                        return valid ? msPublished : msNotPublished;
                }
        }
        return  msNotPublished;
    }

    let getEtapaCaptura = json => {
        if(json.contracts.find(x => x.implementation && x.implementation.status)) {
            return 'Implementación'
        } else if(json.contracts.find(x => x.status)) {
            return 'Contrato'
        } else if(json.awards.find(x => x.status)){
            return 'Adjudicación'
        } else if(json.tender.status) {
            return 'Licitación'
        } else{
            return 'Planeación'
        }
    }

    let countLength = json => {
        let total = 0;
        if(json === undefined || json === null) return total;
        if(Array.isArray(json)){
            json.map(x => total += countLength(x));
        } else if(typeof json === 'object'){
            Object.keys(json).map(key => total += countLength(json[key]));
        } else {
            return 1;
        }
        
        return total;
    }


    /**
     * Limpiar propiedades vacias
     * @param {Object} obj Objeto a limpiar de propiedades vacias
     */
    let clean = obj => {
        if(!obj || obj === null) return {};
        Object.keys(obj).map(key => {
            if(obj[key] === undefined ||
                obj[key] === null ||
                (Array.isArray(obj[key]) && obj[key].length === 0) || 
                (typeof obj[key] === 'object' && !(obj[key] instanceof Date) && Object.keys(obj[key]).length === 0) ||
                (typeof obj[key] === 'string' && obj[key].trim() === '') ||
                (typeof obj[key] === 'number' && isNaN(obj[key]))){
                 delete obj[key];
             }
        });
        return obj;
    }
}

module.exports = ValidateProcess;