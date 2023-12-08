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

  data: ls_artifacts          type ty_artifacts,
        ls_tadir_dummy        type tadir,
        lt_tadir_dummy        type standard table of tadir.

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

  field-symbols: <ls_artifacts> like line of ls_artifacts-artifacts,
                 <ls_file>      like line of lo_zip->files,
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


  clear: lv_xstring, lo_zip.

  perform create_transpot using iv_transport_description
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
