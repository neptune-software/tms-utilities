function z_download_transport.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_REQUEST) TYPE  TRKORR
*"     VALUE(IV_AS_ZIP) TYPE  XSDBOOLEAN OPTIONAL
*"  EXPORTING
*"     VALUE(EV_COFILE) TYPE  XSTRING
*"     VALUE(EV_DATAFILE) TYPE  XSTRING
*"     VALUE(EV_ZIP) TYPE  XSTRING
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
        lo_zip              type ref to cl_abap_zip.

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
                                    changing ev_cofile
                                             l_no_authority
                                             l_file_access_error.
  if l_no_authority = abap_true.
    raise no_authority.
  endif.

  if l_file_access_error = abap_true.
    raise file_access_error.
  endif.

  if iv_as_zip = abap_true.
    create object lo_zip.
    l_file_string = l_file.
    lo_zip->add(
      name    = l_file_string
      content = ev_cofile ).
    clear: ev_cofile. "memory release.
  endif.


  concatenate 'R' iv_request+4 '.' iv_request(3)
                    into l_file.

  concatenate l_dir_trans l_delim 'data' l_delim l_file     "#EC NOTEXT
              into l_filepath.

  perform read_file_from_applserver using    l_filepath
                                    changing ev_datafile
                                             l_no_authority
                                             l_file_access_error.

  if iv_as_zip = abap_true.
    l_file_string = l_file.
    lo_zip->add(
      name    = l_file_string
      content = ev_datafile ).
    clear: ev_datafile. " memory release...

    ev_zip = lo_zip->save( ).
  endif.

endfunction.
