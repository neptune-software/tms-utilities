function z_init_neptune_install_check.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     VALUE(ET_LIST_STRING_ASCII) TYPE  STRING_TABLE
*"----------------------------------------------------------------------
  data: lt_list type table of abaplist.

  submit /neptune/installation_check exporting list to memory and return.

  call function 'LIST_FROM_MEMORY'
    tables
      listobject = lt_list
    exceptions
      others     = 1.

  call function 'LIST_TO_ASCI'
    importing
      list_string_ascii  = et_list_string_ascii
    tables
      listobject         = lt_list
    exceptions
      empty_list         = 1
      list_index_invalid = 2
      others             = 3.
  if sy-subrc <> 0.
* Implement suitable error handling here
  endif.


endfunction.
