function z_upload_transport_to_azure.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_REQUEST) TYPE  TRKORR
*"     VALUE(IV_AZURE_ACCOUNT_KEY) TYPE  STRING
*"  EXCEPTIONS
*"      NO_AUTHORITY
*"      FILE_ACCESS_ERROR
*"----------------------------------------------------------------------

  data: l_dir_trans         type c length 200,
        l_delim             type c length 1,
        l_file              type c length 20,
        l_file_string       type string,
        l_filepath          type c length 200,
        l_no_authority      type xsdboolean,
        l_file_access_error type xsdboolean,
        lv_datafile         type xstring,
        lv_cofile           type xstring,
        lo_zip              type ref to cl_abap_zip,
        lv_zip              type xstring.

  check iv_request is not initial.

  call 'C_SAPGPARAM' id 'NAME'  field 'DIR_TRANS'
                     id 'VALUE' field l_dir_trans.

  if l_dir_trans cs '/'.
    l_delim = '/'.
  else.
    l_delim = '\'.
  endif.

  concatenate iv_request+3 '.' iv_request(3)
                  into l_file.
  concatenate l_dir_trans l_delim 'cofiles' l_delim l_file  "#EC NOTEXT
              into l_filepath.

  perform read_file_from_applserver using    l_filepath
                                    changing lv_cofile
                                             l_no_authority
                                             l_file_access_error.
  if l_no_authority = abap_true.
    raise no_authority.
  endif.

  if l_file_access_error = abap_true.
    raise file_access_error.
  endif.

  create object lo_zip.
  l_file_string = l_file.
  lo_zip->add(
    name    = l_file_string
    content = lv_cofile ).
  clear: lv_cofile. "memory release.



  concatenate 'R' iv_request+4 '.' iv_request(3)
                    into l_file.

  concatenate l_dir_trans l_delim 'data' l_delim l_file     "#EC NOTEXT
              into l_filepath.

  perform read_file_from_applserver using    l_filepath
                                    changing lv_datafile
                                             l_no_authority
                                             l_file_access_error.


  l_file_string = l_file.
  lo_zip->add(
    name    = l_file_string
    content = lv_datafile ).
  clear: lv_datafile. " memory release...

  lv_zip = lo_zip->save( ).


  data: lv_url type string,
        lv_utc_tmstmp type timestamp,
        lv_date type string,
        lv_version type string,
        lv_auth_header type string,
        lv_response TYPE string,
        lv_response_stat_code TYPE i,
        lv_response_stat_reason TYPE string,
        lv_content_length type string,
        lo_http_client  TYPE REF TO if_http_client,
        lv_blob_name type string.

  " Generate the Blob Name
  lv_blob_name = iv_request && '.zip'.

  " Construct the URL
  lv_url = |https://stneptuneportal.blob.core.windows.net/test/subfolder/{ lv_blob_name }|.

  " Set x-ms-date and x-ms-version
  cl_abap_tstmp=>systemtstmp_syst2utc( exporting
                                           syst_date = sy-datum
                                           syst_time = sy-uzeit
                                         importing
                                           utc_tstmp = lv_utc_tmstmp ).
  lv_date = lv_utc_tmstmp.

  lv_version = '2020-10-02'.

  " Calculate the Content-Length
  lv_content_length = xstrlen( lv_zip ).

  " Generate the Authorization Header
  lv_auth_header = iv_azure_account_key.

  " Create the HTTP client
  cl_http_client=>create_by_url(
    exporting
      url            = lv_url
    importing
      client         = lo_http_client
    exceptions
      argument_not_found = 1
      plugin_not_active  = 2
      internal_error     = 3
      others             = 4 ).

  if sy-subrc = 0.
    " Set request method
    lo_http_client->request->set_method( 'PUT' ).

    " Add necessary headers
    lo_http_client->request->set_header_field( name  = 'Authorization'
                                               value = lv_auth_header ).
    lo_http_client->request->set_header_field( name  = 'x-ms-blob-type'
                                               value = 'BlockBlob' ).
    lo_http_client->request->set_header_field( name  = 'x-ms-date'
                                               value = lv_date ).
    lo_http_client->request->set_header_field( name  = 'x-ms-version'
                                               value = lv_version ).
    lo_http_client->request->set_header_field( name  = 'Content-Length'
                                               value = lv_content_length ).

    " Add the file content
    lo_http_client->request->set_data( lv_zip ).

    " Send the request
    lo_http_client->send( ).

    " Receive the response
    lo_http_client->receive( ).

    lv_response = lo_http_client->response->get_cdata( ).
lo_http_client->response->get_status(
  importing
    code   = lv_response_stat_code
    reason = lv_response_stat_reason
).
    " Check response for success or handle errors
*    data lv_status type i.
*    lv_status = lo_http_client->response->get_status( ).
*    if lv_status <> 201.
*      raise exception type cx_root
*        exporting
*          text = |Error uploading to Azure Blob Storage: { lv_status }|.
*    endif.

  endif.
endfunction.
