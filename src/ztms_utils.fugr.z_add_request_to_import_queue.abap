function z_add_request_to_import_queue.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_REQUEST) TYPE  TRKORR
*"     VALUE(IV_DOMNAM) TYPE  TMSDOMNAM OPTIONAL
*"     VALUE(IV_SYSTEM) TYPE  TMSSYSNAM DEFAULT SY-SYSID
*"----------------------------------------------------------------------
  call function 'TMS_MGR_FORWARD_TR_REQUEST'
    exporting
      iv_request                 = iv_request
      iv_target                  = iv_system
      iv_import_again            = abap_true
      iv_monitor                 = space
*                                   importing
*     EV_DIFFERENT_GROUPS        =
*     EV_TP_RET_CODE             =
*     EV_TP_ALOG                 =
*     EV_TP_SLOG                 =
*     EV_TP_PID                  =
*     ES_EXCEPTION               =
*     ET_TP_FORWARDS             =
* TABLES
*     TT_STDOUT                  =
    exceptions
      read_config_failed         = 1
      table_of_requests_is_empty = 2
      others                     = 3.
  if sy-subrc <> 0.
* Implement suitable error handling here
  endif.


endfunction.
