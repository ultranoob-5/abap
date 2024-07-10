*&---------------------------------------------------------------------*
*& Include          ZCUST_DOC_UPLOAD
*&---------------------------------------------------------------------*

DATA : lv_xstring   TYPE xstring,
      lv_descr      TYPE C LENGTH 60,
      lv_bp         TYPE saeobjid.

lv_bp = lv_partner.  " Assigning partner ID to local variable
lv_descr = lv_partner.  " Assigning partner ID as description

LOOP AT gt_cust INTO gs_cust.

  " Check if PAN data is available
  IF gs_cust-pan IS NOT INITIAL.

    "Convert BASE64 to xstring
    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
    EXPORTING
      INPUT  = gs_cust-pan
    IMPORTING
      OUTPUT = lv_xstring.

    " Archive object type
    CALL FUNCTION 'ARCHIV_CREATE_TABLE'
    EXPORTING
      ar_object                = gs_cust-lv_pan_ftype  " File type
      object_id                = lv_bp                 " Business partner ID
      sap_object               = 'BUS1006'             " SAP object type (Business Partner)
      document                 = lv_xstring            " Decoded PAN document
      filename                 = gs_cust-lv_pan_fname  " Filename for PAN document
      descr                    = lv_descr.              " Description for PAN document

  ENDIF.

  " Check if AADHAR data is available
  IF gs_cust-aadhar IS NOT INITIAL.

    "Convert BASE64 to xstring
    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
    EXPORTING
      INPUT  = gs_cust-aadhar
    IMPORTING
      OUTPUT = lv_xstring.

    " Archive object type
    CALL FUNCTION 'ARCHIV_CREATE_TABLE'
    EXPORTING
      ar_object                = gs_cust-lv_aadhar_ftype  " File type
      object_id                = lv_bp                    " Business partner ID
      sap_object               = 'BUS1006'                " SAP object type (Business Partner)
      document                 = lv_xstring               " Decoded PAN document
      filename                 = gs_cust-lv_aadhar_fname  " Filename for PAN document
      descr                    = lv_descr.                 " Description for PAN document

  ENDIF.


  " Check if GST COPY data is available
  IF gs_cust-gst IS NOT INITIAL.

    "Convert BASE64 to xstring
    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
    EXPORTING
      INPUT  = gs_cust-gst
    IMPORTING
      OUTPUT = lv_xstring.

    " Archive object type
    CALL FUNCTION 'ARCHIV_CREATE_TABLE'
    EXPORTING
      ar_object                = gs_cust-lv_gst_ftype  " File type
      object_id                = lv_bp                 " Business partner ID
      sap_object               = 'BUS1006'             " SAP object type (Business Partner)
      document                 = lv_xstring            " Decoded PAN document
      filename                 = gs_cust-lv_gst_fname  " Filename for PAN document
      descr                    = lv_descr.              " Description for PAN document

  ENDIF.

  " Check if FSSAI data is available
  IF gs_cust-fssai IS NOT INITIAL.

    "Convert BASE64 to xstring
    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
    EXPORTING
      INPUT  = gs_cust-fssai
    IMPORTING
      OUTPUT = lv_xstring.

    " Archive object type
    CALL FUNCTION 'ARCHIV_CREATE_TABLE'
    EXPORTING
      ar_object                = gs_cust-lv_fssai_ftype  " File type
      object_id                = lv_bp                   " Business partner ID
      sap_object               = 'BUS1006'               " SAP object type (Business Partner)
      document                 = lv_xstring              " Decoded PAN document
      filename                 = gs_cust-lv_fssai_fname  " Filename for PAN document
      descr                    = lv_descr.                " Description for PAN document

  ENDIF.

  " Check if TDS Copy is available
  IF gs_cust-tds IS NOT INITIAL.

    "Convert BASE64 to xstring
    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
    EXPORTING
      INPUT  = gs_cust-tds
    IMPORTING
      OUTPUT = lv_xstring.

    " Archive object type
    CALL FUNCTION 'ARCHIV_CREATE_TABLE'
    EXPORTING
      ar_object                = gs_cust-lv_tds_ftype " File type
      object_id                = lv_bp                " Business partner ID
      sap_object               = 'BUS1006'            " SAP object type (Business Partner)
      document                 = lv_xstring           " Decoded PAN document
      filename                 = gs_cust-lv_tds_fname " Filename for PAN document
      descr                    = lv_descr.             " Description for PAN document

  ENDIF.

  " Check if Cheque Copy is available
  IF gs_cust-cheque IS NOT INITIAL.

    "Convert BASE64 to xstring
    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
    EXPORTING
      INPUT  = gs_cust-cheque
    IMPORTING
      OUTPUT = lv_xstring.

    " Archive object type
    CALL FUNCTION 'ARCHIV_CREATE_TABLE'
    EXPORTING
      ar_object                = gs_cust-lv_cheque_ftype " File type
      object_id                = lv_bp                   " Business partner ID
      sap_object               = 'BUS1006'               " SAP object type (Business Partner)
      document                 = lv_xstring              " Decoded PAN document
      filename                 = gs_cust-lv_cheque_fname " Filename for PAN document
      descr                    = lv_descr.                " Description for PAN document

  ENDIF.

  " Check if TAN data is available
  IF gs_cust-tan IS NOT INITIAL.

    "Convert BASE64 to xstring
    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
    EXPORTING
      INPUT  = gs_cust-tan
    IMPORTING
      OUTPUT = lv_xstring.

    " Archive object type
    CALL FUNCTION 'ARCHIV_CREATE_TABLE'
    EXPORTING
      ar_object                = gs_cust-lv_tan_ftype " File type
      object_id                = lv_bp                " Business partner ID
      sap_object               = 'BUS1006'            " SAP object type (Business Partner)
      document                 = lv_xstring           " Decoded PAN document
      filename                 = gs_cust-lv_tan_fname " Filename for PAN document
      descr                    = lv_descr.             " Description for PAN document

  ENDIF.

ENDLOOP.
