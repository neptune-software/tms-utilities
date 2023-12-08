function z_release_tr_in_bg_mode.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_TRKORR) TYPE  TRKORR OPTIONAL
*"----------------------------------------------------------------------

  check iv_trkorr is not initial.

  try.

      perform release_in_bg_mode in program saplscts_release
                                 using iv_trkorr
                                 abap_true
                                 abap_true.

    catch cx_root.

  endtry.

endfunction.
