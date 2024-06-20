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
endform.                    "save_xstring_to_appl
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


endform.                    "read_file_from_applserver
*&---------------------------------------------------------------------*
*&      Form  CREATE_TRANSPORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IV_TRANSPORT_DESCRIPTION  text
*      <--P_EV_REQUEST  text
*      <--P_EV_TASK  text
*----------------------------------------------------------------------*
form create_transport  using    pu_transport_description type clike
                               pu_target                type tr_target
                      changing pc_request type trkorr
                               pc_task type trkorr.

  data lt_users type scts_users.
  data ls_new_request type  trwbo_request_header.
  data lt_new_tasks type  trwbo_request_headers.
  data lv_transport_description type trordertxt.

  field-symbols <user> like line of lt_users.

  append initial line to lt_users assigning <user>.
  <user>-user = sy-uname.
  <user>-type = 'S'.

  if pu_transport_description  is initial.
    lv_transport_description = 'Uninstallation Transport'.
  else.
    lv_transport_description = pu_transport_description .
  endif.

  " Create new Workbench Transport Request
  call function 'TR_INSERT_REQUEST_WITH_TASKS'
    exporting
      iv_type           = 'K'
      iv_text           = lv_transport_description
      iv_owner          = sy-uname
      iv_target         = pu_target
      it_users          = lt_users
    importing
      es_request_header = ls_new_request
      et_task_headers   = lt_new_tasks
    exceptions
      insert_failed     = 1
      enqueue_failed    = 2
      others            = 3.
  check sy-subrc = 0.

  pc_request = ls_new_request-trkorr.
  read table lt_new_tasks into ls_new_request index 1.
  pc_task = ls_new_request-trkorr.

endform.                    " CREATE_TRANSPORT
*&---------------------------------------------------------------------*
*&      Form  INSERT_TRKORR_INTO_TRANSPORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form insert_trkorr_into_transport using put_transport_objects type ty_t_transport_objects
                                        pu_transport          type trkorr.
  data: lt_e071   type standard table of e071,
        ls_e071   type e071,
        lv_tabix  type sytabix.

  field-symbols: <ls_transport_object> like line of put_transport_objects.


  check put_transport_objects is not initial.
  check pu_transport  is not initial.

  lv_tabix = 0.

  loop at put_transport_objects assigning <ls_transport_object>.
    lv_tabix = lv_tabix + 1.

*   Entry into transport
    clear ls_e071.
    ls_e071-pgmid = <ls_transport_object>-pgmid.
    ls_e071-object = <ls_transport_object>-object.
    ls_e071-obj_name = <ls_transport_object>-obj_name.
    ls_e071-objfunc = 'D'.
    ls_e071-trkorr = pu_transport.
    ls_e071-as4pos = lv_tabix.

    modify e071 from ls_e071.   " Directly to the table

  endloop.



endform.                    " INSERT_TRKORR_INTO_TRANSPORT
*&---------------------------------------------------------------------*
*&      Form  RELEASE_TRANSPORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_EV_TASK  text
*      -->P_ABAP_FALSE  text
*----------------------------------------------------------------------*
form release_transport  using    pu_trkorr type trkorr
                                 pu_in_background type abap_bool
                        changing pc_ok type abap_bool.

  data: lv_trfunction             type e070-trfunction,
         lv_subrc                  type sysubrc.


  select single trfunction from e070 into lv_trfunction
                           where trkorr = pu_trkorr.

  call function 'TR_AUTHORITY_CHECK_TRFUNCTION'
    exporting
      iv_trfunction = lv_trfunction
      iv_activity   = 'RELE'
    exceptions
      others        = 1.
  check sy-subrc = 0.

  call function 'CTS_LOCK_TRKORR'        " eclipse compatible locking...
       exporting
            iv_trkorr   = pu_trkorr
       exceptions
            others = 1.
  check sy-subrc = 0.

  call function 'TRINT_RELEASE_REQUEST'
      exporting
        iv_trkorr                   = pu_trkorr
        iv_dialog                   = space
        iv_as_background_job        = pu_in_background
        iv_success_message          = space
        iv_without_objects_check    = abap_true
        iv_without_locking          = abap_true
        iv_display_export_log       = space
        iv_ignore_warnings          = abap_true
*        iv_simulation               = space
*      IMPORTING
*        es_request                  = es_request
*        et_deleted_tasks            = et_deleted_tasks
*        et_messages                 = lt_messages
      exceptions
        cts_initialization_failure  = 1
        enqueue_failed              = 2
        no_authorization            = 3
        invalid_request             = 4
        request_already_released    = 5
        repeat_too_early            = 6
        object_lock_error           = 7
        object_check_error          = 8
        docu_missing                = 9
        db_access_error             = 10
        action_aborted_by_user      = 11
        export_failed               = 12
        execute_objects_check       = 13
        release_in_bg_mode          = 14
        release_in_bg_mode_w_objchk = 15
        error_in_export_methods     = 16
        object_lang_error           = 17.
  lv_subrc = sy-subrc.

*---dequeue request-----------------------------------------------------
  call function 'CTS_UNLOCK_TRKORR'
    exporting
      iv_trkorr = pu_trkorr
    exceptions
      others    = 0.

  case lv_subrc .
    when 14 or 15.
      call function 'Z_RELEASE_TR_IN_BG_MODE'
        exporting
          iv_trkorr     = pu_trkorr
        exceptions
          error_message = 1
          others        = 2.

    when 0 or 11.
      " all good
    when others.
      return. ">>>>>>
  endcase.

  pc_ok = abap_true.

endform.                    " RELEASE_TRANSPORT
*&---------------------------------------------------------------------*
*&      Form  UPDATE_TRANSPORT_NUMBER_RANGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IV_TRANSPORT_TYPE  text
*      -->P_IV_TRANSPORT_VERSION  text
*----------------------------------------------------------------------*
form update_transport_number_range  using    pu_transport_type
                                             pu_transport_version.

  data lv_major type string.
  data lv_minor type string.
  data lv_patch type string.
  data lv_patch_3_digits type n length 3.
  data lv_ui5_v_numrange type n length 2. " Use dedicated number ranges for UI5 LTS versions.
  data lv_number_range type n length 5. " Our number range, the five last digits of the transport
  data lv_dummy type string.
  data lv_lastnum type e070l-lastnum.

  split pu_transport_version at '.' into lv_major lv_minor lv_patch.

  if pu_transport_type = 'DXP'.

    lv_patch = lv_patch+1. " skip first leading 0
    split lv_patch at '-' into lv_patch lv_dummy. " In case of Release candidate or Beta release

    if lv_minor = '10'.
      " LTS Release
      concatenate lv_major lv_patch into lv_number_range. " i.e it will be transport NPLK923006 for 23.10.0006
    else.
      " Innovation release - should only be relevant for current year, so major version is skipped
      concatenate lv_minor lv_patch into lv_number_range. " number range 0 for Innovation releases. i.e NPLK906002 for 24.06.0002
    endif.

  else.
    " Start our internal number range at 5 for UI5, i.e. NPLK95****
    case lv_major.
      when '1'.

        case lv_minor.
          when '38'.
            lv_ui5_v_numrange = '50'.
          when '71'.
            lv_ui5_v_numrange = '51'.
          when '84'.
            lv_ui5_v_numrange = '52'.
          when '96'.
            lv_ui5_v_numrange = '53'.
          when '108'.
            lv_ui5_v_numrange = '54'.
          when '120'.
            lv_ui5_v_numrange = '55'.
          when '132'.
            lv_ui5_v_numrange = '56'.
          when '144'.
            lv_ui5_v_numrange = '57'.
          when '156'.
            lv_ui5_v_numrange = '58'.
          when '168'.
            lv_ui5_v_numrange = '59'.
          when '180'.
            lv_ui5_v_numrange = '60'.
          when '192'.
            lv_ui5_v_numrange = '61'.
          when '204'.
            lv_ui5_v_numrange = '62'.
          when others.
            lv_ui5_v_numrange = '70'.
        endcase.

      when '2'.
        " Preparation for UI5 2.x
        case lv_minor.
          when '0'.
            lv_ui5_v_numrange = '80'.
          when '12'.
            lv_ui5_v_numrange = '81'.
          when '24'.
            lv_ui5_v_numrange = '82'.
          when '36'.
            lv_ui5_v_numrange = '82'.
          when others.
            lv_ui5_v_numrange = '80'.
        endcase.
      when others.
    endcase.

    lv_patch_3_digits = lv_patch. " always use 3 digit format with leading zeroes for UI5 patch numbers
    concatenate lv_ui5_v_numrange lv_patch_3_digits into lv_number_range.

  endif.

  " Must subtract 1 from the transport number we actually want to use
  lv_number_range = lv_number_range - 1. " this is set as last used

  concatenate sy-sysid 'K' '9' lv_number_range into lv_lastnum. " must start with 9

  update e070l set trkorr = lv_lastnum where lastnum = 'TRKORR'.
  commit work and wait.

endform.                    " UPDATE_TRANSPORT_NUMBER_RANGE
