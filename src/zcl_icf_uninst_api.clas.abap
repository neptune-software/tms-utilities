class zcl_icf_uninst_api definition
  public
  create public .

  public section.

    interfaces if_http_extension .
  protected section.
  private section.

    " Fixed on the server so a caller cannot redirect a pull or a transport.
    constants c_tms_utils_package type devclass value '$TMS_UTILITIES'. "#EC NOTEXT
    constants c_target type tr_target value 'ZNP'.          "#EC NOTEXT
    constants c_artifacts_url_pattern type string
      value 'https://api.github.com/repos/neptune-software/*/actions/runs/*/artifacts'. "#EC NOTEXT
    constants c_default_artifact type string value 'trkorr-object-list'. "#EC NOTEXT

    data mo_server type ref to if_http_server .

    methods handle_ping .
    methods handle_pull .
    methods handle_transport .
    methods handle_status .
    methods require_method
      importing
        !iv_method   type string
      returning
        value(rv_ok) type abap_bool .
    methods field
      importing
        !iv_name        type string
      returning
        value(rv_value) type string .
    methods respond
      importing
        !iv_code type i
        !iv_json type string .
    methods respond_error
      importing
        !iv_code    type i
        !iv_message type string .
    class-methods json_string
      importing
        !iv_value      type csequence
      returning
        value(rv_json) type string .
    class-methods json_bool
      importing
        !iv_value      type abap_bool
      returning
        value(rv_json) type string .
ENDCLASS.



CLASS ZCL_ICF_UNINST_API IMPLEMENTATION.


  method field.

    " Reads the query string and a form-encoded POST body alike.
    rv_value = mo_server->request->get_form_field( iv_name ).

  endmethod.


  method handle_ping.

    data: lv_sysid type string,
          lv_json  type string.

    if require_method( 'GET' ) = abap_false.
      return.
    endif.

    lv_sysid = sy-sysid.
    lv_sysid = json_string( lv_sysid ).
    concatenate '{"status":"ok","sysid":' lv_sysid '}' into lv_json.
    respond( iv_code = 200 iv_json = lv_json ).

  endmethod.


  method handle_pull.

    data: lt_return   type standard table of bapiret2 with default key,
          ls_return   type bapiret2,
          lv_user     type string,
          lv_password type string,
          lv_line     type string,
          lv_messages type string,
          lv_failed   type abap_bool,
          lv_json     type string.

    if require_method( 'POST' ) = abap_false.
      return.
    endif.

    lv_user     = field( 'git_user' ).
    lv_password = field( 'git_password' ).
    if lv_user is initial or lv_password is initial.
      respond_error( iv_code = 400 iv_message = 'git_user and git_password are required' ).
      return.
    endif.

    " The repository was linked once by hand; the wrapper finds it by package.
    call function 'ZABAPGIT_API_RFC_PULL'
      exporting
        abap_package  = c_tms_utils_package
        git_user      = lv_user
        git_password  = lv_password
      tables
        return        = lt_return
      exceptions
        error_message = 1
        others        = 2.
    if sy-subrc <> 0.
      lv_failed = abap_true.
    endif.

    loop at lt_return into ls_return.
      if ls_return-type = 'E' or ls_return-type = 'A'.
        lv_failed = abap_true.
      endif.
      concatenate ls_return-type ls_return-message into lv_line separated by ': '.
      lv_line = json_string( lv_line ).
      if lv_messages is not initial.
        concatenate lv_messages ',' into lv_messages.
      endif.
      concatenate lv_messages lv_line into lv_messages.
    endloop.

    if lv_failed = abap_true.
      concatenate '{"ok":false,"messages":[' lv_messages ']}' into lv_json.
      respond( iv_code = 500 iv_json = lv_json ).
    else.
      concatenate '{"ok":true,"messages":[' lv_messages ']}' into lv_json.
      respond( iv_code = 200 iv_json = lv_json ).
    endif.

  endmethod.


  method handle_status.

    data: lv_request type trkorr,
          lv_status  type string,
          lv_json    type string.

    if require_method( 'GET' ) = abap_false.
      return.
    endif.

    lv_request = field( 'trkorr' ).
    translate lv_request to upper case.
    if lv_request is initial.
      respond_error( iv_code = 400 iv_message = 'trkorr is required' ).
      return.
    endif.

    call function 'Z_CHECK_EXPORT_STATUS_TPSTAT'
      exporting
        iv_request = lv_request
      importing
        ev_status  = lv_status.

    lv_status = json_string( lv_status ).
    concatenate '{"status":' lv_status '}' into lv_json.
    respond( iv_code = 200 iv_json = lv_json ).

  endmethod.


  method handle_transport.

    data: lv_url         type string,
          lv_token       type string,
          lv_artifact    type string,
          lv_type        type string,
          lv_version     type string,
          lv_description type trordertxt,
          lv_request     type trkorr,
          lv_task        type trkorr,
          lv_ok          type xsdboolean,
          lv_retcode     type stpa-retcode,
          lv_message     type string,
          lv_request_s   type string,
          lv_task_s      type string,
          lv_retcode_s   type string,
          lv_ok_s        type string,
          lv_json        type string.

    if require_method( 'POST' ) = abap_false.
      return.
    endif.

    lv_url         = field( 'artifacts_url' ).
    lv_token       = field( 'token' ).
    lv_artifact    = field( 'artifact_name' ).
    lv_type        = field( 'transport_type' ).
    lv_version     = field( 'transport_version' ).
    lv_description = field( 'description' ).
    translate lv_type to upper case.

    if lv_url np c_artifacts_url_pattern.
      respond_error( iv_code = 400
                     iv_message = 'artifacts_url must be a neptune-software run artifacts URL on api.github.com' ).
      return.
    endif.
    if lv_token is initial.
      respond_error( iv_code = 400 iv_message = 'token is required' ).
      return.
    endif.
    if lv_type <> 'DXP' and lv_type <> 'UI5' and lv_type <> 'ABG'.
      respond_error( iv_code = 400 iv_message = 'transport_type must be DXP, UI5 or ABG' ).
      return.
    endif.
    if lv_artifact is initial.
      lv_artifact = c_default_artifact.
    endif.

    call function 'Z_CREATE_UNINST_TRANSPORT'
      exporting
        iv_url                   = lv_url
        iv_token                 = lv_token
        iv_name_trkorrlist_zip   = lv_artifact
        iv_transport_description = lv_description
        iv_release_transport     = abap_true
        iv_target                = c_target
        iv_transport_type        = lv_type
        iv_transport_version     = lv_version
      importing
        ev_tp_retcode            = lv_retcode
        ev_request               = lv_request
        ev_task                  = lv_task
        ev_ok                    = lv_ok
      exceptions
        error_message            = 1
        others                   = 2.
    if sy-subrc <> 0.
      message id sy-msgid type 'S' number sy-msgno
        with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 into lv_message.
      respond_error( iv_code = 500 iv_message = lv_message ).
      return.
    endif.

    " The function module has no error output: it stops at the first failed step and leaves
    " EV_OK initial. The history document's diagnostics section explains how to find which step.
    lv_request_s = lv_request.
    lv_task_s    = lv_task.
    lv_retcode_s = lv_retcode.
    lv_ok_s      = json_bool( lv_ok ).
    lv_request_s = json_string( lv_request_s ).
    lv_task_s    = json_string( lv_task_s ).
    lv_retcode_s = json_string( lv_retcode_s ).
    concatenate '{"ok":' lv_ok_s
                ',"request":' lv_request_s
                ',"task":' lv_task_s
                ',"tpRetcode":' lv_retcode_s '}'
      into lv_json.

    if lv_ok = abap_true.
      respond( iv_code = 200 iv_json = lv_json ).
    else.
      respond( iv_code = 500 iv_json = lv_json ).
    endif.

  endmethod.


  method if_http_extension~handle_request.

    data lv_path type string.

    mo_server = server.

    " The part of the URL after the node: /zz_uninst_api/ping -> /ping
    lv_path = server->request->get_header_field( '~path_info' ).
    translate lv_path to lower case.

    case lv_path.
      when '/ping'.
        handle_ping( ).
      when '/pull'.
        handle_pull( ).
      when '/transport'.
        handle_transport( ).
      when '/status'.
        handle_status( ).
      when others.
        respond_error( iv_code = 404 iv_message = 'Unknown endpoint' ).
    endcase.

  endmethod.


  method json_bool.

    if iv_value = abap_true.
      rv_json = 'true'.
    else.
      rv_json = 'false'.
    endif.

  endmethod.


  method json_string.

    data: lv_value type string,
          lv_cr    type c length 1.

    lv_value = iv_value.
    lv_cr = cl_abap_char_utilities=>cr_lf.

    replace all occurrences of '\' in lv_value with '\\'.
    replace all occurrences of '"' in lv_value with '\"'.
    replace all occurrences of cl_abap_char_utilities=>newline in lv_value with '\n'.
    replace all occurrences of lv_cr in lv_value with '\r'.
    replace all occurrences of cl_abap_char_utilities=>horizontal_tab in lv_value with '\t'.

    concatenate '"' lv_value '"' into rv_json.

  endmethod.


  method require_method.

    data: lv_method  type string,
          lv_message type string.

    lv_method = mo_server->request->get_header_field( '~request_method' ).
    if lv_method = iv_method.
      rv_ok = abap_true.
    else.
      concatenate 'Use' iv_method into lv_message separated by space.
      respond_error( iv_code = 405 iv_message = lv_message ).
    endif.

  endmethod.


  method respond.

    data lv_reason type string.

    case iv_code.
      when 200. lv_reason = 'OK'.
      when 400. lv_reason = 'Bad Request'.
      when 404. lv_reason = 'Not Found'.
      when 405. lv_reason = 'Method Not Allowed'.
      when others. lv_reason = 'Internal Server Error'.
    endcase.

    mo_server->response->set_status( code = iv_code reason = lv_reason ).
    mo_server->response->set_header_field( name = 'Content-Type' value = 'application/json' ).
    mo_server->response->set_header_field( name = 'Cache-Control' value = 'no-store' ).
    mo_server->response->set_cdata( iv_json ).

  endmethod.


  method respond_error.

    data: lv_message type string,
          lv_json    type string.

    lv_message = json_string( iv_message ).
    concatenate '{"ok":false,"error":' lv_message '}' into lv_json.
    respond( iv_code = iv_code iv_json = lv_json ).

  endmethod.
ENDCLASS.
