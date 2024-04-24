function z_create_uninst_transport.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_URL) TYPE  STRING
*"     VALUE(IV_TOKEN) TYPE  STRING
*"     VALUE(IV_NAME_TRKORRLIST_ZIP) TYPE  STRING DEFAULT
*"       'trkorr-object-list'
*"     VALUE(IV_TRANSPORT_DESCRIPTION) TYPE  TRORDERTXT OPTIONAL
*"     VALUE(IV_RELEASE_TRANSPORT) TYPE  XSDBOOLEAN OPTIONAL
*"     VALUE(IV_TARGET) TYPE  TR_TARGET DEFAULT 'ZNP'
*"  EXPORTING
*"     VALUE(ET_LOGPTR) TYPE  TTOCS_TP_LOGPTR
*"     VALUE(ET_STDOUT) TYPE  TTOCS_TP_STDOUT
*"     VALUE(EV_TP_RETCODE) TYPE  STPA-RETCODE
*"     VALUE(EV_REQUEST) TYPE  TRKORR
*"     VALUE(EV_TASK) TYPE  TRKORR
*"     VALUE(EV_OK) TYPE  XSDBOOLEAN
*"----------------------------------------------------------------------


  types:
    ty_t_transport_objects type ty_t_transport_objects .

  data: ls_artifacts   type ty_artifacts,
        ls_tadir_dummy type tadir,
        lt_tadir_dummy type standard table of tadir.

  data: lo_http_client        type ref to if_http_client,
        lv_auth_value         type string,
        lv_artifact_response  type string,
        lv_xstring            type xstring,
        lx_json               type ref to cx_root,
        lv_cofile             type xstring,
        lv_prefix             type string,
        lv_datafile           type xstring,
        lv_request            type trkorr,
        lx_actual_trkorr_list type xstring,
        lo_zip                type ref to cl_abap_zip,
        lt_trkorr_obj_list    type ty_t_transport_objects,
        ls_package_data       type scompkdtln,
        l_exists              type c length 1.

  field-symbols: <ls_artifacts>       like line of ls_artifacts-artifacts,
                 <ls_file>            like line of lo_zip->files,
                 <ls_trkorr_obj_list> like line of lt_trkorr_obj_list.

  check sy-sysid <> 'NAD' and
        sy-sysid <> 'N23' and
        sy-sysid <> 'N22' and
        sy-sysid <> 'N21' and
        sy-sysid <> 'N60'.


  cl_http_client=>create_by_url(
    exporting
      url                = iv_url
    importing
      client             = lo_http_client
    exceptions
      argument_not_found = 1
      plugin_not_active  = 2
      internal_error     = 3
      others             = 4  ).

  check sy-subrc = 0.

  concatenate 'token' iv_token into lv_auth_value separated by space.

  lo_http_client->request->set_header_field(
      name  = 'Authorization'
      value = lv_auth_value ).

  lo_http_client->send(
    exceptions
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      http_invalid_timeout       = 4
      others                     = 5 ).

  check sy-subrc = 0.

  lo_http_client->receive(
    exceptions
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      others                     = 4 ).

  check sy-subrc = 0.

  lv_artifact_response = lo_http_client->response->get_cdata( ).

  lo_http_client->close(
    exceptions
      http_invalid_state = 1
      others             = 2
  ).

  check sy-subrc = 0.

  /ui2/cl_json=>deserialize(
    exporting
      json         = lv_artifact_response
      pretty_name  = /ui2/cl_json=>pretty_mode-low_case
    changing
      data         = ls_artifacts ).


  read table ls_artifacts-artifacts with key name = iv_name_trkorrlist_zip assigning <ls_artifacts>.

  check sy-subrc = 0.



  cl_http_client=>create_by_url(
    exporting
      url                = <ls_artifacts>-archive_download_url
    importing
      client             = lo_http_client
    exceptions
      argument_not_found = 1
      plugin_not_active  = 2
      internal_error     = 3
      others             = 4  ).

  check sy-subrc = 0.

  concatenate 'token' iv_token into lv_auth_value separated by space.

  " FIX FOR UPLOAD ARTIFACT V4 https://github.com/actions/upload-artifact?tab=readme-ov-file#v4---whats-new
  " THE DOWNLOAD PERFORMS A 302 REDIRECT TO AZURE
  " something like this:
  " https://productionresultssa16.blob.core.windows.net/actions-results/c18b9569-a50b-4951-b10a-asdasdc72b60/workflow-job-runasdasd/artifacts/0316e1asd94c6ef31.zip
  " ?rscd=attachment%3B+filename%3D%22signatures.zip%22&se=2024-04-24T15%3A46%3A48Z&sig=M22u4JasdqdPYBSWNI%3D&sp=r&spr=https&sr=b&st=2024-04-24T15%3A36%3A43Z&sv=2021-12-02
  " for whatever reason sap is not able to do this correctly. so what solved the issue is to disable the redirect handling of the cl_http_client
  " and manually creat a new request afterwards with the target and final location. that has then worked.
  " before this fix instead of a zip file i always got an error xml response from microsoft with this content:
  " <Error>
  "<Code>AuthenticationFailed</Code>
  "<Message>Server failed to authenticate the request. Make sure the value of Authorization header is formed correctly including the signature. RequestId:xxxx Time:2024-04-24T15:47:50.6653644Z</Message>
  "</Error>
  lo_http_client->propertytype_redirect = if_http_client=>co_disabled.

  lo_http_client->request->set_header_field(
      name  = 'Authorization'
      value = lv_auth_value ).


  lo_http_client->request->set_header_field(
      name  = 'Accept-Encoding'
      value = 'gzip, deflate, br' ).


  lo_http_client->send(
    exceptions
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      http_invalid_timeout       = 4
      others                     = 5 ).

  check sy-subrc = 0.

  lo_http_client->receive(
    exceptions
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      others                     = 4 ).

  check sy-subrc = 0.

  data: lt_header_fields type tihttpnvp,
        ls_header_field  like line of lt_header_fields.

  lo_http_client->response->get_header_fields(
    changing  fields = lt_header_fields  ).

  read table lt_header_fields with key name = 'location' into ls_header_field.
  if sy-subrc = 0 and ls_header_field-value is not initial.

    cl_http_client=>create_by_url(
      exporting
        url                = ls_header_field-value
      importing
        client             = lo_http_client
      exceptions
        argument_not_found = 1
        plugin_not_active  = 2
        internal_error     = 3
        others             = 4  ).

    check sy-subrc = 0.

    lo_http_client->propertytype_redirect = if_http_client=>co_disabled.

    lo_http_client->request->set_header_field(
        name  = 'Accept-Encoding'
        value = 'gzip, deflate, br' ).

    lo_http_client->send(
      exceptions
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        http_invalid_timeout       = 4
        others                     = 5 ).

    check sy-subrc = 0.

    lo_http_client->receive(
      exceptions
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        others                     = 4 ).

    check sy-subrc = 0.
  endif.


  lv_xstring = lo_http_client->response->get_data( ).

  lo_http_client->close(
    exceptions
      http_invalid_state = 1
      others             = 2 ).

  check sy-subrc = 0.

  create object lo_zip.
  lo_zip->load(
    exporting
      zip             = lv_xstring
    exceptions
      zip_parse_error = 1
      others          = 2 ).

  check sy-subrc = 0.

  loop at lo_zip->files assigning <ls_file> where name cp '*.json'.
    lo_zip->get( exporting name    = <ls_file>-name
                 importing content = lx_actual_trkorr_list ).
  endloop.

  check lx_actual_trkorr_list is not initial.

  /ui2/cl_json=>deserialize(
         exporting jsonx         = lx_actual_trkorr_list
         changing  data          = lt_trkorr_obj_list ).

  delete lt_trkorr_obj_list where pgmid = 'R3TR' and object = 'TABU'. " TABU entries bring an error on releasing when the table does not exist

  clear: lv_xstring, lo_zip.

  perform create_transpot using iv_transport_description
                                iv_target
                          changing ev_request
                                   ev_task.
  call function 'CHECK_EXIST_DEVC'
    exporting
      name            = 'Z_UNINSTALL'
*     MTYPE           = ' '
    importing
      exist           = l_exists
    exceptions
      tr_invalid_type = 1
      others          = 2.
  if sy-subrc <> 0 or l_exists is initial.
    " Package does not exist yet, create it
    " This shouldn't really happen, because the folder logic initially creates the packages.
    ls_package_data-devclass = 'Z_UNINSTALL'.
    ls_package_data-as4user = sy-uname.
    ls_package_data-dlvunit = 'HOME'.
    cl_package_factory=>create_new_package(
      changing
        c_package_data             = ls_package_data
      exceptions
        object_already_existing    = 1
        object_just_created        = 2
        not_authorized             = 3
        wrong_name_prefix          = 4
        undefined_name             = 5
        reserved_local_name        = 6
        invalid_package_name       = 7
        short_text_missing         = 8
        software_component_invalid = 9
        layer_invalid              = 10
        author_not_existing        = 11
        component_not_existing     = 12
        component_missing          = 13
        prefix_in_use              = 14
        unexpected_error           = 15
        intern_err                 = 16
        no_access                  = 17
*          invalid_translation_depth  = 18 downport, does not exist in 7.30
*          wrong_mainpack_value       = 19 downport, does not exist in 7.30
*          superpackage_invalid       = 20 downport, does not exist in 7.30
*          error_in_cts_checks        = 21 downport, does not exist in 7.31
        others                     = 22 ).
  endif.


  loop at lt_trkorr_obj_list assigning <ls_trkorr_obj_list>.


*   Dummy entry into TADIR
    clear ls_tadir_dummy.
    ls_tadir_dummy-pgmid    = <ls_trkorr_obj_list>-pgmid.
    ls_tadir_dummy-object   = <ls_trkorr_obj_list>-object.
    ls_tadir_dummy-obj_name = <ls_trkorr_obj_list>-obj_name.
    ls_tadir_dummy-devclass = 'Z_UNINSTALL'.
    insert ls_tadir_dummy into table lt_tadir_dummy.
  endloop.

  modify tadir from table lt_tadir_dummy.

  perform insert_trkorr_into_transport using lt_trkorr_obj_list
                                             ev_request.

  commit work and wait.

  if iv_release_transport = abap_true.

    perform release_transport using ev_task abap_false changing ev_ok.
    check ev_ok = abap_true.
    clear: ev_ok.

    perform release_transport using ev_request abap_true
                              changing ev_ok.
  else.

    ev_ok = abap_true.

  endif.

endfunction.
