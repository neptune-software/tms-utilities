function z_upload_transport.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_COFILE) TYPE  XSTRING
*"     VALUE(IV_DATAFILE) TYPE  XSTRING
*"     VALUE(IV_REQUEST) TYPE  TRKORR
*"     VALUE(IV_OVERRIDE) TYPE  XSDBOOLEAN OPTIONAL
*"  EXCEPTIONS
*"      NO_AUTHORITY
*"      FILE_ALREADY_EXISTS
*"      ERROR_ON_WRITE
*"----------------------------------------------------------------------

  data: l_apath               type c length 200,
        l_dir_trans           type c length 200,
        l_delim               type c length 1,
        l_file                type c length 20,
        l_file_already_exists type xsdboolean,
        l_no_authority        type xsdboolean,
        l_error_on_write      type xsdboolean.

  call 'C_SAPGPARAM' id 'NAME'  field 'DIR_TRANS'
                    id 'VALUE'  field l_dir_trans.

  if l_dir_trans cs '/'.
    l_delim = '/'.
  else.
    l_delim = '\'.
  endif.

  concatenate 'R' iv_request+4 '.' iv_request(3)
                   into l_file.
  concatenate l_dir_trans l_delim 'data' l_delim l_file     "#EC NOTEXT
              into l_apath.

  perform save_xstring_to_appl(saplztms_utils)
    using    iv_override l_apath iv_datafile
    changing l_file_already_exists l_no_authority l_error_on_write.

  if l_file_already_exists = abap_true.
    raise file_already_exists.
  endif.
  if l_no_authority = abap_true.
    raise no_authority.
  endif.
  if l_error_on_write = abap_true.
    raise error_on_write.
  endif.

  concatenate iv_request+3 '.' iv_request(3)
                   into l_file.
  concatenate l_dir_trans l_delim 'cofiles' l_delim l_file  "#EC NOTEXT
              into l_apath.

  perform save_xstring_to_appl(saplztms_utils)
    using    iv_override l_apath iv_cofile
    changing l_file_already_exists l_no_authority l_error_on_write.

  if l_file_already_exists = abap_true.
    raise file_already_exists.
  endif.
  if l_no_authority = abap_true.
    raise no_authority.
  endif.
  if l_error_on_write = abap_true.
    raise error_on_write.
  endif.

endfunction.
