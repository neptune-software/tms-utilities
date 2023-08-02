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
*&---------------------------------------------------------------------*
*& Form read_file_From_applserver
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
form read_file_from_applserver using    pu_file              type clike
                               changing pc_file              type xstring
                                        pc_no_authority      type xsdboolean
                                        pc_file_access_error type xsdboolean.

  data: l_orln           type n length 12.
  data: l_len like sy-tabix.


  data: l_filepath      type c length 200,
        lx_access_error type ref to cx_sy_file_access_error,
        l_auth_filename type authb-filename.

  data: lt_raw_data type table of raw255,
        lv_raw_line type raw255,
        lv_len      type i.

  clear: pc_file, pc_no_authority, pc_file_access_error.

  check pu_file is not initial.

  l_auth_filename = pu_file.

  call function 'AUTHORITY_CHECK_DATASET'
    exporting
*     PROGRAM          =
      activity         = 'READ' "sabc_act_read
      filename         = l_auth_filename
    exceptions
      no_authority     = 1
      activity_unknown = 2
      others           = 3.
  if not sy-subrc is initial.
    pc_no_authority = abap_true.
    return. ">>>>>>>>>>>
  endif.

  l_filepath = pu_file.

  try.

      open dataset l_filepath for input in binary mode.
      if sy-subrc <> 0.
        pc_file_access_error = abap_true.
        return. ">>>>>>>>
      endif.

      do.
        clear l_len.
        clear lv_raw_line.

        read dataset l_filepath into lv_raw_line length l_len.

        if sy-subrc <> 0.
          if l_len > 0.
            l_orln = l_orln + l_len.
            append lv_raw_line to lt_raw_data.
          endif.
          exit.
        endif.
        l_orln = l_orln + l_len.
        append lv_raw_line to lt_raw_data.

      enddo.

      close dataset l_filepath.

      lv_len = l_orln.

      call function 'SCMS_BINARY_TO_XSTRING'
        exporting
          input_length = lv_len
        importing
          buffer       = pc_file
        tables
          binary_tab   = lt_raw_data
        exceptions
          failed       = 1
          others       = 2.

    catch cx_sy_file_access_error into lx_access_error.
      pc_file_access_error = abap_true.
      return. ">>>>>>>>
  endtry.


endform.
