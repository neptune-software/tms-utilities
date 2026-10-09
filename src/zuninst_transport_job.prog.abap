report zuninst_transport_job.

" Must match ZCL_ICF_UNINST_API component for component: IMPORT matches the cluster by component
" name and type.
types: begin of ty_input,
         url         type string,
         token       type string,
         artifact    type string,
         type        type string,
         version     type string,
         description type trordertxt,
       end of ty_input,
       begin of ty_result,
         ok      type xsdboolean,
         request type trkorr,
         task    type trkorr,
         retcode type stpa-retcode,
         message type string,
       end of ty_result.

" Fixed on the server so a caller cannot redirect a transport.
constants c_target type tr_target value 'ZNP'.                "#EC NOTEXT

parameters p_jobcnt type btcjobcnt obligatory.

data: gs_input  type ty_input,
      gs_result type ty_result.

start-of-selection.

  import input = gs_input from database indx(zu) id p_jobcnt.
  if sy-subrc <> 0.
    gs_result-message = 'Job input not found'.
    export result = gs_result to database indx(zr) id p_jobcnt.
    commit work.
    return.
  endif.
  " The input holds the GitHub token: remove it before doing anything else.
  delete from database indx(zu) id p_jobcnt.
  commit work.

  call function 'Z_CREATE_UNINST_TRANSPORT'
    exporting
      iv_url                   = gs_input-url
      iv_token                 = gs_input-token
      iv_name_trkorrlist_zip   = gs_input-artifact
      iv_transport_description = gs_input-description
      iv_release_transport     = abap_true
      iv_target                = c_target
      iv_transport_type        = gs_input-type
      iv_transport_version     = gs_input-version
    importing
      ev_tp_retcode            = gs_result-retcode
      ev_request               = gs_result-request
      ev_task                  = gs_result-task
      ev_ok                    = gs_result-ok
    exceptions
      error_message            = 1
      others                   = 2.
  if sy-subrc <> 0.
    message id sy-msgid type 'S' number sy-msgno
      with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 into gs_result-message.
  endif.

  " Written before the job ends, so a finished job without a result really has none.
  export result = gs_result to database indx(zr) id p_jobcnt.
  commit work.
