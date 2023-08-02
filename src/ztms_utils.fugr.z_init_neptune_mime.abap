function z_init_neptune_mime.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_COMMIT_WORK) TYPE  XSDBOOLEAN DEFAULT ABAP_TRUE
*"----------------------------------------------------------------------

  data: lc_neptune_objid type skwf_root-objid value 'E0D3F8ECC07D3AF19AFC005056B20018'.

  data: lv_skwf like skwf_root.

* Check for SKWF_ROOT content
* Important setting for root node MIME folder
  select single *                                       "#EC CI_GENBUFF
         from skwf_root
         into lv_skwf
         where objid eq lc_neptune_objid .                  "#EC WARNOK

  if sy-subrc ne 0.

    clear lv_skwf.
    lv_skwf-appl    = 'MIME'.
    lv_skwf-objtype = 'F'.
    lv_skwf-class   = 'M_FOLDER'.
    lv_skwf-objid   = lc_neptune_objid .

    modify skwf_root from lv_skwf.
    if iv_commit_work = abap_true.
      commit work and wait.
    endif.
  endif.


endfunction.
