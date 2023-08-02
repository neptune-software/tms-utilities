function z_check_export_status_tpstat.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_REQUEST) TYPE  TRKORR
*"  EXPORTING
*"     VALUE(EV_STATUS) TYPE  STRING
*"     VALUE(ES_TPSTAT) TYPE  TPSTAT
*"----------------------------------------------------------------------

  call function 'TR_CHECK_EXPORT_STATUS_TPSTAT'
    exporting
      iv_trkorr          = iv_request
    importing
      es_tpstat          = es_tpstat
    exceptions
      export_is_running  = 1
      export_is_finished = 2
      export_is_aborted  = 3
      no_export_found    = 4
      others             = 5.

  case sy-subrc .
    when 1.
      ev_status = 'RUNNING'.
    when 2.
      ev_status = 'FINISHED'.
    when 3.
      ev_status = 'ABORTED'.
    when 4.
      ev_status = 'NOT_FOUND'.
    when 5.
      ev_status = 'UNKOWN'.
  endcase.

endfunction.
