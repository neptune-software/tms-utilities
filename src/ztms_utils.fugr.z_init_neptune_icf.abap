function z_init_neptune_icf.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     VALUE(EV_ERROR) TYPE  XSDBOOLEAN
*"----------------------------------------------------------------------

  data:  ls_icfservice type icfservice.

  select single * from icfservice
                  into ls_icfservice
                  where icf_name = 'NEPTUNE'
                  and   icfparguid = '0000000000000000000000000'.

  check sy-subrc = 0.

  perform enable_icftree_db in program rsicftree
                            changing ls_icfservice ev_error.

endfunction.
