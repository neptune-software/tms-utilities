function z_init_neptune.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     VALUE(ET_LIST_STRING_ASCII) TYPE  STRING_TABLE
*"----------------------------------------------------------------------

" create the neptune mime folder
  call function 'Z_INIT_NEPTUNE_MIME'.

" activate the neptune icf nodes
  call function 'Z_INIT_NEPTUNE_ICF'.

" run the neptune installation check report
  call function 'Z_INIT_NEPTUNE_INSTALL_CHECK'
    importing
      et_list_string_ascii = et_list_string_ascii.

endfunction.
