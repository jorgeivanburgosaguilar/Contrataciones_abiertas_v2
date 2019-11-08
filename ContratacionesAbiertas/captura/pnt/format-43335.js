
// FORMATO A
const FORMAT = 43335;
const FormatFunctions = require('./format-functions');

/**
 * Armar estructura del formato "Resultados adjudicaciones, invitaciones y licitaciones_Procedimientos de adjudicación directa"
 * @param {Object} release Json del release
 * @param {Array} recordsPnt Registros en PNT
 * @param {Number} position Numero de registro
 * @param {Object} extras Datos que no se pueden obtener del release
 */
let build = (release, recordsPnt, position, extras) => {

    // iniciar proceso para obtener todos los datos del formato

    // crear instancia para obtener funciones 
    const fn = new FormatFunctions(release, recordsPnt, position);

    release.contracts.map(contract => {

        fn.addField(334233, 'ejercicio', extras, undefined, true, 'Ejercicio');
        let date = new Date(fn.findValue(`awards[?(@.id==="${contract.awardID}")].date`));
        const quarter = Math.floor(date.getMonth() / 3);
        const start = new Date(date.getFullYear(),quarter*3,1);
        const end = new Date(date.getFullYear(),(quarter*3)+2,1);
        end.setMonth(end.getMonth() + 1);
        end.setDate(end.getDate() - 1);

        fn.add(334258, start.toISOString(), date => fn.dateFormat(date), true, 'Fecha de inicio del periodo que se informa');
        fn.add(334259, end.toISOString(), date => fn.dateFormat(date), true, 'Fecha de término del periodo que se informa');

        fn.addField(334269, 'tender.additionalProcurementCategories[0]', undefined, value => {
            switch (value) {
                // este no esta en el catalogo de pnt
                case 'memberships':
                    value = 0;
                    break;
                case 'goodsAcquisition':
                    value = 2;
                    break;
                case 'goodsLease':
                    value = 3;
                    break;
                case 'services':
                    value = 4;
                    break;
                case 'worksRelatedServices':
                    value = 1;
                    break;
                case 'works':
                    value = 0;
                    break;
            }
            return value;
        });
        fn.addField(334230, 'awardID', contract);

        let values = fn.findValue('tender.procurementMethodDetails');

        switch (values) {
            case 'Excepciones al reglamento':
            case 'Convenio de colaboración':
            case 'Adhesiones y membresías':
                fn.add(334238, 'Excepción al reglamento con fundamento en el artículo 1° del Reglamento de Adquisiciones, Arrendamientos y Servicios del Instituto Federal de Acceso a la Información y Protección de Datos.');
                fn.addFields(334250, `planning.documents[?(@.documentType==="needsAssessment")].url`);
       
                break;
            case 'Adjudicación directa art.41':
                fn.add(334238, 'Adjudicación directa con fundamento en los artículos 26 fracción III y 41 del Reglamento de Adquisiciones, Arrendamientos y Servicios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales.');
                fn.addFields(334250, `planning.documents[?(@.documentType==="exceptionAuthorization")].url`);
       
                break;
            case 'Adjudicación directa art.42':
                fn.add(334238, 'Adjudicación directa con fundamento en los artículos 26 fracción III y 42 del Reglamento de Adquisiciones, Arrendamientos y Servicios del Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales.');
                fn.addFields(334250, `awards[?(@.id==="${contract.awardID}")].documents[?(@.documentType==="technicalEvaluationReport")].url`);
       
                break;
        }

        fn.addField(334270, 'tender.procurementMethodDetails', undefined, value => {
            switch (value) {
                case 'Adjudicación directa art.41':
                case 'Adjudicación directa art.42':
                    value = 0;
                    break;
                default:
                    value = 1;
                    break;
            }
            return value;
        });

        fn.addFields(334239, 'description', contract);


        fn.addTable(334271, 'planning.requestsForQuotes[*].quotes[*]', (quotes, results) => {
            let issueSuppliers = fn.findValues('issuingSupplier', quotes);
            if (issueSuppliers) {
                issueSuppliers.map(supplier => {
                    fn.addInternalField(43311, `parties[?(@.id==="${supplier.id}")].identifier.givenName`, release, results);
                    fn.addInternalField(43312, `parties[?(@.id==="${supplier.id}")].identifier.patronymicName`, release, results);
                    fn.addInternalField(43313, `parties[?(@.id==="${supplier.id}")].identifier.matronymicName`, release, results);
                    fn.addInternalField(43314, `parties[?(@.id==="${supplier.id}")].identifier.legalName`, release, results);
                    fn.addInternalField(43315, `parties[?(@.id==="${supplier.id}")].id`, release, results);
                });
            }
            // solo el primero, aqui no hay netAmount??
            fn.addInternalField(43316, 'value.amount', quotes, results);
        });


        let awardSupplier = fn.findValues(`awards[?(@.id==="${contract.awardID}")].suppliers[0]`);
        if (awardSupplier) {
            awardSupplier.map(x => {
                fn.addField(334264, `parties[?(@.id==="${x.id}")].identifier.givenName`);
                fn.addField(334260, `parties[?(@.id==="${x.id}")].identifier.patronymicName`);
                fn.addField(334265, `parties[?(@.id==="${x.id}")].identifier.matronymicName`);
                fn.addField(334266, `parties[?(@.id==="${x.id}")].identifier.legalName`);
                fn.addField(334267, `parties[?(@.id==="${x.id}")].id`);
            });

        }

        fn.add(334235, extras.usuario);
        fn.add(334236, extras.usuario);

        fn.addField(334231, `id`, contract);
        fn.addField(334243, `dateSigned`, contract, date => fn.dateFormat(date));
        fn.addField(334244, `value.netAmount`, contract);
        fn.addField(334245, `value.amount`, contract);
        
        fn.addField(334247, `tender.minValue.amount`);
        fn.addField(334248, `tender.value.amount`);
        
        fn.addField(334228, `value.currency`, contract);
        // no se envia (no se guarda en release)
        fn.addFields(334229, `value.exchangeRates[*].rate`, contract);
        fn.addField(334232, `implementation.transactions[0].paymentMethod`, contract, paymentMethod => {
            switch(paymentMethod) {
                case 'letterOfCredit':  return 'Carta de crédito';
                case 'check':  return 'Cheque';
                case 'cash':  return 'Efectivo';
                case 'corporateCard':  return 'Tarjeta corporativa';
                case 'wireTransfer':  return 'Transferencia bancaria';
            }
        });
        fn.addField(334240, `description`, contract);
        fn.addField(334246, `guarantees[*].value.amount`, contract, (amounts) => {
            let total = 0;
            if(Array.isArray(amounts)){
                amounts.map(x => total += x);
            } else {
                total = amounts;
            }
            
            return total;
        });
        fn.addField(334241, `period.startDate`, contract, date => fn.dateFormat(date));
        fn.addField(334261, `period.endDate`, contract, date => fn.dateFormat(date));

        values = fn.findValues(`documents[?(@.documentType==="contractSigned")].url`, contract);
        values = values.concat(fn.findValues(`documents[?(@.documentType==="contractAnnexe")].url`, contract));
        fn.add(334254, values.join(','));
        fn.addField(334253, `documents[?(@.documentType==="suspensionStatement")].url`, contract);


        fn.add(334234, 0);
        fn.add(334272, 'Recursos fiscales');


        fn.addTable(334255, 'id', (id, results) => {
            let address = fn.findValue('items[?(@.deliveryAddress)].deliveryAddress', contract);
            if(address){
                values = [];
                values.push(address.streetAddress);
                values.push(address.locality);
                values.push(address.region);
                values.push(address.postalCode);
                values.push(address.countryName);
                fn.addInternal(43303, values.filter(x => x !== undefined && x !== null).join(', '), results);
            }
 
            fn.addInternalField(43304, 'planning.documents[?(@.documentType==="environmentalImpact")].url', undefined, results);
            //fn.addInternalField(43305, 'tender.milestones[?(@.type=="publicNotices")].description', undefined, results);
            fn.addInternalField(43306, 'implementation.status', contract, results, status => {
                switch (status) {
                    case 'planning': status = 0; break;
                    case 'ongoing': status = 1; break;
                    // esta no existe en pnt
                    case 'concluded': status = 2; break;
                    case 'terminated': status = 2; break;
                }
                return status;
            });
        }, contract);

        value = fn.findValue('amendments[?(@.date)].date', contract);
        fn.add(334273, value ? 0 : 1);
      

         fn.addTable(334268, 'amendments', (amendment, results) => {
            fn.addInternalField(43307, 'id', amendment, results);
            fn.addInternalField(43308, 'description', amendment, results);
            fn.addInternalField(43309, 'date', amendment, results, date => fn.dateFormat(date));
            fn.addInternalFields(43310, 'documents[?(@.documentType=="contractAmendment")].url', contract, results);
        }, contract);
        fn.addField(334237, 'surveillanceMechanisms', contract, value => {
            return value.map(x => {
                switch(x) {
                    case 'socialWitness': return 'Testigo social';
                    case 'citizenComptroller': return 'Contraloría social';
                    case 'internalControlUnit': return 'Órgano Interno de control';
                    case 'externalAuditor': return 'Auditor externo';
                }
            }).join(', ');
        });

        fn.addFields(334274, 'implementation.documents[?(@.documentType=="physicalProcessReport")].url', contract);
        fn.addFields(334251, 'implementation.documents[?(@.documentType=="financialProgressReport")].url', contract);
        fn.addFields(334252, 'implementation.documents[?(@.documentType=="physicalReception")].url', contract);
        fn.addFields(334249, 'implementation.documents[?(@.documentType=="finalPayment")].url', contract);
        
        fn.add(334262, extras.usuario);
        fn.addField(334242, 'fechaValidacion', extras, date => fn.dateFormat(date), true, 'Fecha de validación');
        fn.addField(334257, 'fechaActualizacion', extras, date => fn.dateFormat(date), true,'Fecha de actualización');
        
        // notas
        let notes =''
        let desierto = release.tender.status === 'cancelled';
        if (!desierto) {


            // obra publica
            if (release.tender.additionalProcurementCategories.find(x => x === 'worksRelatedServices' ||
                x === 'works')) {
                notes += 'Al no ser una contratación de obras públicas o servicios relacionados con las mismas no se generó información respecto de lugar donde se realizará la obra, descripción de la obra pública, observaciones dirigidas a la población relativas a la realización de las obras públicas, etapa de la obra pública, avances físicos y financieros así como el de recepcion fisica y finiquito ni estudio de impacto ambiental. ';
            }
            // convenios modificatorios
            if (contract.amendments && contract.amendments.lenght > 0) {
                notes += 'La presente contratación no cuenta a la fecha de actualización con convenios modificatorios por lo cual no se cubrieron los campos relacionados con estos. ';
            }

            // comunicacion de suspencion
            values = fn.findValue('documents[?(@.documentType=="suspensionStatement")].url', contract);
            if (!values) {
                notes += 'En esta contratación no hay a la fecha comunicado de suspensión, rescisión o terminación anticipada. ';
            }

            // instrumento cerrado
            if (!release.tender.minValue || release.tender.minValue.amount === 0) {
                notes += 'Esta contratación se formalizó a través de un instrumento de carácter cerrado, por lo cual no se cuenta con montos mínimos y máximos. ';
            } else {
                // instrumento abierto
                notes += 'Respecto del monto sin impuestos y el monto total con impuestos del instrumento, se informa que en virtud de estar formalizado a través de un instrumento de carácter abierto, en estos rubros se reporta el monto máximo contratado. ';
            }
        } else {
            // cuando se es desierto
            // texto general
            notes = 'El presente procedimiento de contratación no cuenta con información de un pedido o contrato formalizado, por tanto no se generó información relativa a los criterios del nombre del ganador, contrato y sus anexos, convenio modificatorio, convenio de terminación, Descripción breve de las razones que justifican la elección del/los proveedor/es, Número que identifique al contrato, Fecha del contrato, Monto del contrato sin impuestos incluidos, Monto total del contrato con impuestos incluidos, Monto mínimo con impuestos incluidos, Monto máximo con impuestos incluidos, tipo de moneda, Objeto del contrato, tipo y forma de pago, fecha de inicio y término, toda vez que el procedimiento en cuestión se declaró desierto y no fue adjudicado a licitante alguno, en tal virtud los datos concernientes a información de contratos o pedidos tales como: nombre y/o razón social del contratista, RFC, descripción de  las razones que justifican su elección, número de contrato, fecha de contrato, montos del contrato, tipo de moneda, tipo de cambio, forma de pago, fecha de inicio y término, plazo de entrega y ejecución de los servicios, hipervínculo al contrato, mecanismos de vigilancia y supervisión no fueron establecidos al no adjudicarse a licitante alguno. La presente contratación no cuenta a la fecha de actualización con convenios modificatorios por lo cual no se cubrieron los campos relacionados con estos. En esta contratación al declararse desierta por ende no hay a la fecha comunicado de suspensión, rescisión o terminación anticipada. ';

            // tipo de contratacion
            if (release.tender.additionalProcurementCategories.find(x => x !== 'worksRelatedServices' ||
                x !== 'works')) {
                notes += 'De igual manera al  no adjudicarse y no ser una contratación de obra pública no se generó información respecto de Lugar donde se realizará la obra, descripción de la obra pública, observaciones dirigidas a la población relativas a la realización de las obras públicas, Etapa de la obra pública, avances  físicos y financieros así como el de recepción física y finiquito ni estudio de impacto ambiental. ';
            } else {
                notes += 'De igual manera al  no adjudicarse no se generó información respecto de Lugar donde se realizará la obra, descripción de la obra pública, observaciones dirigidas a la población relativas a la realización de las obras públicas, Etapa de la obra pública, avances  físicos y financieros así como el de recepción física y finiquito ni estudio de impacto ambiental. ';
            }
        }
        fn.add(334263, notes);
        fn.nextContract();
    });


    return fn.getFormat();
}

module.exports.build = build;