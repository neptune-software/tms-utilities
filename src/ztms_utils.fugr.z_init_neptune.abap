function z_init_neptune.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     VALUE(ET_LIST_STRING_ASCII) TYPE  STRING_TABLE
*"----------------------------------------------------------------------
  data: lv_skwf like skwf_root,
        lt_list type table of abaplist.

* Check for SKWF_ROOT content
* Important setting for root node MIME folder
  select single *                                       "#EC CI_GENBUFF
         from skwf_root
         into lv_skwf
         where objid eq 'E0D3F8ECC07D3AF19AFC005056B20018'. "#EC WARNOK

  if sy-subrc ne 0.

    clear lv_skwf.
    lv_skwf-appl    = 'MIME'.
    lv_skwf-objtype = 'F'.
    lv_skwf-class   = 'M_FOLDER'.
    lv_skwf-objid   = 'E0D3F8ECC07D3AF19AFC005056B20018'.

    modify skwf_root from lv_skwf.
    commit work and wait.
  endif.

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
