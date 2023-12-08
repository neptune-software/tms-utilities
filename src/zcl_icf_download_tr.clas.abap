class ZCL_ICF_DOWNLOAD_TR definition
  public
  create public .

public section.

  interfaces IF_HTTP_EXTENSION .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ICF_DOWNLOAD_TR IMPLEMENTATION.


method if_http_extension~handle_request.

  data: lv_trkorr       type trkorr,
        lv_xstring      type xstring,
        lv_header_value type string.

  lv_trkorr = server->request->get_form_field(  name = 'trkorr' ).

  call function 'Z_DOWNLOAD_TRANSPORT'
    exporting
      iv_request        = lv_trkorr
      iv_as_zip         = abap_true
    importing
      ev_zip            = lv_xstring
    exceptions
      no_authority      = 1
      file_access_error = 2
      others            = 3.

  check sy-subrc = 0.
  concatenate 'attachment; filename="' 'dummy.zip' '"' into lv_header_value.

  server->response->set_header_field( name = 'content-disposition' value = lv_header_value ).

  server->response->set_header_field( name = 'Content-Type' value = 'application/x-zip' ).
  server->response->set_data( exporting data               = lv_xstring ).

endmethod.
ENDCLASS.
