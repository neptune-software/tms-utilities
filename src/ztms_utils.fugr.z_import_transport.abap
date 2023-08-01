function z_import_transport.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_SYSTEM) TYPE  TMSSYSNAM DEFAULT SY-SYSID
*"     VALUE(IV_REQUEST) TYPE  TRKORR
*"     VALUE(IV_CLIENT) TYPE  SYMANDT DEFAULT SY-MANDT
*"     VALUE(IV_OVERTAKE) TYPE  XSDBOOLEAN DEFAULT ABAP_TRUE
*"     VALUE(IV_IMPORT_AGAIN) TYPE  XSDBOOLEAN DEFAULT ABAP_TRUE
*"     VALUE(IV_IGNORE_ORIGINALITY) TYPE  XSDBOOLEAN DEFAULT ABAP_TRUE
*"     VALUE(IV_IGNORE_REPAIRS) TYPE  XSDBOOLEAN DEFAULT ABAP_TRUE
*"     VALUE(IV_IGNORE_TRANSTYPE) TYPE  XSDBOOLEAN DEFAULT ABAP_TRUE
*"     VALUE(IV_IGNORE_TABLETYPE) TYPE  XSDBOOLEAN DEFAULT ABAP_TRUE
*"     VALUE(IV_IGNORE_PREDEC) TYPE  XSDBOOLEAN DEFAULT ABAP_TRUE
*"     VALUE(IV_IGNORE_CVERS) TYPE  XSDBOOLEAN DEFAULT ABAP_TRUE
*"     VALUE(IV_TEST_IMPORT) TYPE  XSDBOOLEAN OPTIONAL
*"     VALUE(IV_OFFLINE) TYPE  XSDBOOLEAN OPTIONAL
*"  EXPORTING
*"     VALUE(ET_LOGPTR) TYPE  TTOCS_TP_LOGPTR
*"     VALUE(ET_STDOUT) TYPE  TTOCS_TP_STDOUT
*"     VALUE(EV_TP_RETCODE) TYPE  STPA-RETCODE
*"----------------------------------------------------------------------

  call function 'TMS_MGR_IMPORT_TR_REQUEST'
    exporting
      iv_system                  = iv_system
*     IV_DOMAIN                  =
      iv_request                 = iv_request
      iv_client                  = iv_client
*     IV_CTC_ACTIVE              =
      iv_overtake                = iv_overtake
      iv_import_again            = iv_import_again
      iv_ignore_originality      = iv_ignore_originality
      iv_ignore_repairs          = iv_ignore_repairs
      iv_ignore_transtype        = iv_ignore_transtype
      iv_ignore_tabletype        = iv_ignore_tabletype
      iv_ignore_predec           = iv_ignore_predec
      iv_ignore_cvers            = iv_ignore_cvers
      iv_test_import             = iv_test_import
*     IV_CMD_IMPORT              =
*     IV_NO_DELIVERY             =
*     IV_SUBSET                  =
      iv_offline                 = iv_offline
*     IV_FEEDBACK                =
*     IV_MONITOR                 = 'X'
*     IV_FORCE                   =
*     IV_VERBOSE                 =
*     IS_BATCH                   =
*     IT_REQUESTS                =
*     IT_CLIENTS                 =
    importing
      ev_tp_ret_code             = ev_tp_retcode
*     EV_TP_ALOG                 =
*     EV_TP_SLOG                 =
*     EV_TP_PID                  =
*     EV_TPSTAT_KEY              =
*     ES_EXCEPTION               =
*     ET_TP_IMPORTS              =
    tables
      tt_logptr                  = et_logptr
      tt_stdout                  = et_stdout
    exceptions
      read_config_failed         = 1
      table_of_requests_is_empty = 2
      others                     = 3.
  if sy-subrc <> 0.
* Implement suitable error handling here
  endif.

endfunction.
