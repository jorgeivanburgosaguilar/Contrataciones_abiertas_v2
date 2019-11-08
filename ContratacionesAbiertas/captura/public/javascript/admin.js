//admin
let processing = false;

$("#adminModal").on('show.bs.modal', function (event) {
    var button = $(event.relatedTarget);
    var modal = $(this);

    switch (button.data('action')){
        case 'new_user':
            modal.find('.modal-title').text('Registrar usuario');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load("/admin/new-user.html", function () {
                $(this).find('form').submit(function (e) {
                    $.post('/user', $(this).serialize()).done(function (data) {
                        alert(data.message);
                        if (data.status === 'Ok'){
                            modal.modal('hide');
                        }
                    });
                    e.preventDefault();
                })
            });
            break;

        case 'users':
            modal.find('.modal-title').text('Usuarios');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/admin/users.html',function () {
                modal.on('click', '[data-toggle="modal"]', function () {
                    modal.modal('hide');
                });
            });
            break;
        case 'manage_process':
            modal.find('.modal-title').text('Contrataciones');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/admin/contrataciones.html',function () {
                modal.off('click','#list-contracting .list-group-item');
                modal.on('click','#list-contracting .list-group-item', function () {
                   //alert( $(this).data('contractingprocess_id'));
                    modal.find('#modal_content').html('');
                    modal.find('#modal_content').load('/admin/cp_options.html', {contractingprocess_id : $(this).data('contractingprocess_id')}, function (){
                        $('#update-permissions').submit(function (e) {
                            $.post('/admin/update-permissions/', $(this).serialize()).done(function (data) {
                                alert(data.message);
                                if (data.status === 'Ok'){
                                    modal.modal('hide');
                                }
                            });

                            e.preventDefault();
                        })
                    });
                });

            });
            modal.find('#modal_content').on('submit', '#frmBusquedaContratacion', (e) => {
                e.preventDefault();
                modal.find('#modal_content').load('/admin/contrataciones.html?' + $('#frmBusquedaContratacion').serialize());
            });
            break;
        case 'manage_metadata':
            modal.find('.modal-title').text('Licencia y Pólitica de Publicación');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/admin/metadata.html', () => {
                $('#frmMetadata').submit((e) => {
                    e.preventDefault();
                    $.post('/admin/update-metadata', $('#frmMetadata').serializeArray(), (res) => {
                        alert(res.message);
                        if (res.status === 'Ok'){
                            modal.modal('hide');
                        }
                    }).fail(res =>  alert(res.message));
                });
            });
            break;
        case 'manage_catalog':
            modal.find('.modal-title').text(button.data('title'));
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/admin/catalog/' + button.data('type')); // funcionalidad en admin_codes.js
            break;
        case 'manage_ocid':
            modal.find('.modal-title').text('Prefijo OCID');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/admin/ocid', () => {
                modal.find('form').submit(function(e) {
                    e.preventDefault();
                    $.post('/admin/ocid', $(this).serializeArray(), (res) => {
                        alert(res.message);
                        modal.modal('hide');
                    }).fail(res =>  alert(res.responseJSON.message));
                });
            });
            break;
        case 'validate_proccess':
            modal.find('.modal-dialog').css('width', '80%');
            modal.find('.modal-title').text('Validación de Procesos');
            modal.find('#modal_content').html("");
            modal.find('#modal_content').load('/validate-process/');
        break;

        case 'gdmx_dictionary': 
            modal.find('.modal-title').text('Diccionario de Datos');
            modal.find('#modal_content').html(`<form id="frmGDMX">
                                                <div class="input-group form-group">
                                                    <input type="file" accept=".xlsx" class="form-control" required />
                                                    <div class="input-group-btn">
                                                        <button class="btn btn-default">Importar</button>
                                                    </div>
                                                </div>
                                                <a href="/templates/templateDictionary.xlsx" class="pull-right">Descargar plantilla</a>
                                                <br>
                                            </form>
                                            <h4 id="spinner" class="hide text-center">Importando <span class="fa fa-refresh fa-spin"></span></h4>
                                            <code id="errors"></code>`);
            
            importGDMX(modal, 'dictionary');
        break;
        case 'gdmx_document': 
            modal.find('.modal-title').text('Tipos de Documentos');
            modal.find('#modal_content').html(`<form id="frmGDMX">
                                                <div class="input-group form-group">
                                                    <input type="file" accept=".xlsx" class="form-control" required />
                                                    <div class="input-group-btn">
                                                        <button class="btn btn-default">Importar</button>
                                                    </div>
                                                </div>
                                                <a href="/templates/templateDocuments.xlsx" class="pull-right">Descargar plantilla</a>
                                                <br>
                                            </form>
                                            <h4 id="spinner" class="hide text-center">Importando <span class="fa fa-refresh fa-spin"></span></h4>
                                            <code id="errors"></code>`);
            importGDMX(modal, 'document');
        break;
    }
});

let loadingGDMX = () => {
    if (processing) {
        $('#frmGDMX').addClass('hide');
        $('#spinner').removeClass('hide');
    } else {
        $('#frmGDMX').removeClass('hide');
        $('#spinner').addClass('hide');
    }
}

let importGDMX = (modal, type) => {
    loadingGDMX();
    modal.off('submit', '#frmGDMX');
    modal.on('submit', '#frmGDMX', function (e) {
        e.preventDefault();
        $('#errors').empty();
        if (!processing) {
            const formData = new FormData();
            formData.append('datafile', $(this).find('input:file').get(0).files[0]);
            processing = true;
            loadingGDMX();
            $.ajax({
                url: `/gdmx/${type}`,
                type: 'post',
                data: formData,
                cache: false,
                contentType: false,
                processData: false,
                success: res => {
                    processing = false;
                    alert(res.message);
                    if (res.errors.length > 0) {
                        $('#errors').html(res.errors.join('<br/>'));
                    } else {
                        modal.modal('hide');
                    }
                    loadingGDMX();
                },
                error: function (err) {
                    processing = false;
                    loadingGDMX();
                    alert(err.responseText || ' No se ha podido realizar la importación');
                }
            });
        }

    });
}