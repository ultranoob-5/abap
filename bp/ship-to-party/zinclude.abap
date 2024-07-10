*&---------------------------------------------------------------------*
*& Include          ZDOC_UPLOAD
*&---------------------------------------------------------------------*
    DATA : lv_xstring   TYPE xstring,
           lv_descr     TYPE c LENGTH 60,
           lv_bp        TYPE saeobjid.

    lv_bp = lv_partner.
    lv_descr = lv_partner.

LOOP AT gt_stp INTO gs_stp.
  IF gs_stp-pan IS NOT INITIAL.

    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
      EXPORTING
        input  = gs_stp-pan
      IMPORTING
        output = lv_xstring.

    CALL FUNCTION 'ARCHIV_CREATE_TABLE'
      EXPORTING
        ar_object                = gs_stp-lv_pan_ftype
        object_id                = lv_bp
        sap_object               = 'BUS1006'
        document                 = lv_xstring
        filename                 = gs_stp-lv_pan_fname
        descr                    = lv_descr
      EXCEPTIONS
        error_archiv             = 1
        error_communicationtable = 2
        error_connectiontable    = 3
        error_kernel             = 4
        error_parameter          = 5
        error_user_exit          = 6
        error_mandant            = 7
        blocked_by_policy        = 8
        OTHERS                   = 9.
  ENDIF.

  IF gs_stp-aadhar IS NOT INITIAL.

    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
      EXPORTING
        input  = gs_stp-aadhar
      IMPORTING
        output = lv_xstring.

    CALL FUNCTION 'ARCHIV_CREATE_TABLE'
      EXPORTING
        ar_object                = gs_stp-lv_aadhar_ftype
        object_id                = lv_bp
        sap_object               = 'BUS1006'
        document                 = lv_xstring
        filename                 = gs_stp-lv_aadhar_fname
        descr                    = lv_descr
      EXCEPTIONS
        error_archiv             = 1
        error_communicationtable = 2
        error_connectiontable    = 3
        error_kernel             = 4
        error_parameter          = 5
        error_user_exit          = 6
        error_mandant            = 7
        blocked_by_policy        = 8
        OTHERS                   = 9.
  ENDIF.


  IF gs_stp-gst IS NOT INITIAL.

    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
      EXPORTING
        input  = gs_stp-gst
      IMPORTING
        output = lv_xstring.

    CALL FUNCTION 'ARCHIV_CREATE_TABLE'
      EXPORTING
        ar_object                = gs_stp-lv_gst_ftype
        object_id                = lv_bp
        sap_object               = 'BUS1006'
        document                 = lv_xstring
        filename                 = gs_stp-lv_gst_fname
        descr                    = lv_descr
      EXCEPTIONS
        error_archiv             = 1
        error_communicationtable = 2
        error_connectiontable    = 3
        error_kernel             = 4
        error_parameter          = 5
        error_user_exit          = 6
        error_mandant            = 7
        blocked_by_policy        = 8
        OTHERS                   = 9.
  ENDIF.

ENDLOOP.
