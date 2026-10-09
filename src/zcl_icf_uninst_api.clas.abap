class zcl_icf_uninst_api definition
  public
  create public .

public section.

  interfaces if_http_extension .
protected section.
private section.

  " Must match ZUNINST_TRANSPORT_JOB component for component: IMPORT matches the cluster by
  " component name and type.
  types:
    begin of ty_input,
      url         type string,
      token       type string,
      artifact    type string,
      type        type string,
      version     type string,
      description type trordertxt,
    end of ty_input .
  types:
    begin of ty_result,
      ok      type xsdboolean,
      request type trkorr,
      task    type trkorr,
      retcode type stpa-retcode,
      message type string,
    end of ty_result .

  " Fixed on the server so a caller cannot redirect a pull or a transport. The transport target
  " is fixed in ZUNINST_TRANSPORT_JOB.
  constants c_tms_utils_package type devclass value '$TMS_UTILITIES'. "#EC NOTEXT
  constants c_artifacts_url_pattern type string
    value 'https://api.github.com/repos/neptune-software/*/actions/runs/*/artifacts'. "#EC NOTEXT
  constants c_default_artifact type string value 'trkorr-object-list'. "#EC NOTEXT
  constants c_jobname type btcjob value 'ZUNINST_TRANSPORT'. "#EC NOTEXT

  data mo_server type ref to if_http_server .

  methods handle_ping .
  methods handle_pull .
  methods handle_transport .
  methods handle_transport_result .
  methods handle_status .
  methods require_method
    importing
      !iv_method type string
    returning
      value(rv_ok) type abap_bool .
  methods field
    importing
      !iv_name type string
    returning
      value(rv_value) type string .
  methods respond
    importing
      !iv_code type i
      !iv_json type string .
  methods respond_error
    importing
      !iv_code type i
      !iv_message type string .
  class-methods json_string
    importing
      !iv_value type csequence
    returning
      value(rv_json) type string .
  class-methods json_bool
    importing
      !iv_value type abap_bool
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

  data: ls_input    type ty_input,
        lv_jobcount type btcjobcnt,
        lv_released type btcchar1,
        lv_jobcnt_s type string,
        lv_json     type string.

  if require_method( 'POST' ) = abap_false.
    return.
  endif.

  ls_input-url         = field( 'artifacts_url' ).
  ls_input-token       = field( 'token' ).
  ls_input-artifact    = field( 'artifact_name' ).
  ls_input-type        = field( 'transport_type' ).
  ls_input-version     = field( 'transport_version' ).
  ls_input-description = field( 'description' ).
  translate ls_input-type to upper case.

  if ls_input-url np c_artifacts_url_pattern.
    respond_error( iv_code = 400
                   iv_message = 'artifacts_url must be a neptune-software run artifacts URL on api.github.com' ).
    return.
  endif.
  if ls_input-token is initial.
    respond_error( iv_code = 400 iv_message = 'token is required' ).
    return.
  endif.
  if ls_input-type <> 'DXP' and ls_input-type <> 'UI5' and ls_input-type <> 'ABG'.
    respond_error( iv_code = 400 iv_message = 'transport_type must be DXP, UI5 or ABG' ).
    return.
  endif.
  if ls_input-artifact is initial.
    ls_input-artifact = c_default_artifact.
  endif.

  " The job number is unique for the fixed job name, so it keys the job's input and result.
  call function 'JOB_OPEN'
    exporting
      jobname          = c_jobname
    importing
      jobcount         = lv_jobcount
    exceptions
      others           = 1.
  if sy-subrc <> 0.
    respond_error( iv_code = 500 iv_message = 'JOB_OPEN failed' ).
    return.
  endif.

  " Committed before the job is released, so the job finds its input.
  export input = ls_input to database indx(zu) id lv_jobcount.
  commit work.

  submit zuninst_transport_job with p_jobcnt = lv_jobcount
    via job c_jobname number lv_jobcount
    and return.

  call function 'JOB_CLOSE'
    exporting
      jobname          = c_jobname
      jobcount         = lv_jobcount
      strtimmed        = abap_true
    importing
      job_was_released = lv_released
    exceptions
      others           = 1.
  if sy-subrc <> 0 or lv_released <> abap_true.
    delete from database indx(zu) id lv_jobcount.
    commit work.
    respond_error( iv_code = 500
                   iv_message = 'Job not released: the user needs S_BTCH_JOB with JOBACTION RELE' ).
    return.
  endif.

  lv_jobcnt_s = lv_jobcount.
  lv_jobcnt_s = json_string( lv_jobcnt_s ).
  concatenate '{"jobcount":' lv_jobcnt_s '}' into lv_json.
  respond( iv_code = 202 iv_json = lv_json ).

endmethod.


method handle_transport_result.

  data: ls_result   type ty_result,
        lv_jobcount type btcjobcnt,
        lv_status   type btcstatus,
        lv_request  type string,
        lv_task     type string,
        lv_retcode  type string,
        lv_ok_s     type string,
        lv_json     type string.

  if require_method( 'GET' ) = abap_false.
    return.
  endif.

  lv_jobcount = field( 'jobcount' ).
  if lv_jobcount is initial.
    respond_error( iv_code = 400 iv_message = 'jobcount is required' ).
    return.
  endif.

  " The status is read before the result. The job writes its result before it ends, so this
  " order cannot report "finished without a result" for a job that finished in between.
  select single status from tbtco into lv_status
    where jobname = c_jobname and jobcount = lv_jobcount.
  if sy-subrc <> 0.
    respond_error( iv_code = 404 iv_message = 'Unknown job' ).
    return.
  endif.

  import result = ls_result from database indx(zr) id lv_jobcount.
  if sy-subrc <> 0.
    if lv_status = 'A'.
      respond_error( iv_code = 500 iv_message = 'The job was cancelled; see SM37' ).
    elseif lv_status = 'F'.
      respond_error( iv_code = 500 iv_message = 'The job finished without a result; see SM37' ).
    else.
      respond( iv_code = 202 iv_json = '{"state":"running"}' ).
    endif.
    return.
  endif.

  if ls_result-message is not initial and ls_result-ok <> abap_true.
    respond_error( iv_code = 500 iv_message = ls_result-message ).
    return.
  endif.

  " The function module has no error output: it stops at the first failed step and leaves
  " EV_OK initial. The history document's diagnostics section explains how to find which step.
  lv_request = ls_result-request.
  lv_task    = ls_result-task.
  lv_retcode = ls_result-retcode.
  lv_ok_s    = json_bool( ls_result-ok ).
  lv_request = json_string( lv_request ).
  lv_task    = json_string( lv_task ).
  lv_retcode = json_string( lv_retcode ).
  concatenate '{"ok":' lv_ok_s
              ',"request":' lv_request
              ',"task":' lv_task
              ',"tpRetcode":' lv_retcode '}'
    into lv_json.

  if ls_result-ok = abap_true.
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
    when '/transport-result'.
      handle_transport_result( ).
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
    when 202. lv_reason = 'Accepted'.
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
