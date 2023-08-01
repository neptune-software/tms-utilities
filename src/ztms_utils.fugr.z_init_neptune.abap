function z_init_neptune.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"----------------------------------------------------------------------
  data: lv_skwf like skwf_root.


  submit /neptune/installation_check and return.


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

  endif.


endfunction.
