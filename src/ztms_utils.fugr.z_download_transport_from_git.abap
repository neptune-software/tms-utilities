function z_download_transport_from_git.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_URL) TYPE  STRING
*"     VALUE(IV_TOKEN) TYPE  STRING
*"     VALUE(IV_NAME_TRANSPORT_ZIP) TYPE  STRING DEFAULT
*"       'transport-zip'
*"     VALUE(IV_OVERRIDE) TYPE  XSDBOOLEAN OPTIONAL
*"     VALUE(IV_ADD_TO_IMPORT_QUEUE) TYPE  XSDBOOLEAN OPTIONAL
*"     VALUE(IV_IMPORT) TYPE  XSDBOOLEAN OPTIONAL
*"     VALUE(IV_IMPORT_ASYNC) TYPE  XSDBOOLEAN OPTIONAL
*"  EXPORTING
*"     VALUE(ET_LOGPTR) TYPE  TTOCS_TP_LOGPTR
*"     VALUE(ET_STDOUT) TYPE  TTOCS_TP_STDOUT
*"     VALUE(EV_TP_RETCODE) TYPE  STPA-RETCODE
*"----------------------------------------------------------------------

  data: ls_artifacts type ty_artifacts.

  data: lo_http_client       type ref to if_http_client,
        lv_auth_value        type string,
        lv_artifact_response type string,
        lv_xstring           type xstring,
        lx_json              type ref to cx_root,
        lv_cofile            type xstring,
        lv_prefix            type string,
        lv_datafile          type xstring,
        lv_request           type trkorr,
        lv_actual_zip        type xstring,
        lo_zip               type ref to cl_abap_zip.

  field-symbols: <ls_artifacts> like line of ls_artifacts-artifacts,
                 <ls_file>      like line of lo_zip->files.

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


  read table ls_artifacts-artifacts with key name = iv_name_transport_zip assigning <ls_artifacts>.

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



  loop at lo_zip->files assigning <ls_file> where name cp '*.zip'.
    lo_zip->get( exporting name    = <ls_file>-name
                 importing content = lv_actual_zip ).
  endloop.

  clear: lv_xstring, lo_zip.

  create object lo_zip.
  lo_zip->load(
    exporting
      zip             = lv_actual_zip
    exceptions
      zip_parse_error = 1
      others          = 2 ).

  loop at lo_zip->files assigning <ls_file> .
    if <ls_file>-name(1) = 'K'.
      split <ls_file>-name at '.' into lv_prefix lv_request.
      concatenate lv_request lv_prefix into lv_request.

      lo_zip->get( exporting name = <ls_file>-name
                   importing content = lv_cofile ).
    elseif <ls_file>-name(1) = 'R'.
      lo_zip->get( exporting name = <ls_file>-name
                   importing content = lv_datafile ).
    endif.
  endloop.

  clear: lv_xstring, lo_zip.

  call function 'Z_UPLOAD_TRANSPORT'
    exporting
      iv_cofile              = lv_cofile
      iv_datafile            = lv_datafile
      iv_request             = lv_request
      iv_override            = iv_override
      iv_add_to_import_queue = iv_add_to_import_queue
      iv_import              = iv_import
      iv_import_async        = iv_import_async
    importing
      et_logptr              = et_logptr
      et_stdout              = et_stdout
      ev_tp_retcode          = ev_tp_retcode
    exceptions
      no_authority           = 1
      file_already_exists    = 2
      error_on_write         = 3
      others                 = 4.
  case sy-subrc.
    when 1.
      raise no_authority.
    when 2.
      raise file_already_exists.
    when 3.
      raise error_on_write.
  endcase.

endfunction.
