*----------------------------------------------------------------------*
***INCLUDE LZTMS_UTILSF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form save_xstring_to_appl
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
form save_xstring_to_appl using    pu_override       type xsdboolean
                                   pu_filepath       type clike
                                   pu_content        type xstring
                          changing pc_file_already_exists type xsdboolean
                                   pc_no_authority   type xsdboolean
                                   pc_error_on_write type xsdboolean.

  data: l_apath    type c length 200,
        l_filename type authb-filename.

  clear: pc_file_already_exists, pc_no_authority, pc_error_on_write .

  l_apath = pu_filepath.

  l_filename =  pu_filepath.

  call function 'AUTHORITY_CHECK_DATASET'
    exporting
      activity         = 'WRITE'
      filename         = l_filename
    exceptions
      no_authority     = 1
      activity_unknown = 2
      others           = 3.
  if not sy-subrc is initial.
    pc_no_authority = abap_true.
    return. ">>>>>>>>>
  endif.

* open the file on the application server for reading to check if the
* file exists on the application server
  open dataset l_apath for input
       in binary mode.
  if sy-subrc <> 0.
*   nothing to do
  elseif pu_override is initial.
    close dataset l_apath.
    pc_file_already_exists = abap_true.
    return.">>>>>>>>>>
  endif.
  close dataset  l_apath.

* file exists on the application server
  open dataset l_apath for output
       in binary mode.
  if sy-subrc <> 0.
    close dataset  l_apath.
    pc_error_on_write = abap_true.
    return. ">>>>>>>>
  endif.

  transfer pu_content to l_apath.

  close dataset  l_apath.
endform.
