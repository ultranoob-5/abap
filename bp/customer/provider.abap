  METHOD if_rest_resource~post.
*CALL METHOD SUPER->IF_REST_RESOURCE~POST
*  EXPORTING
*    IO_ENTITY =
*    .
  TYPES : BEGIN OF ts_cust,
    org_name          TYPE C LENGTH 40,
    street1           TYPE C LENGTH 60,
    street2           TYPE C LENGTH 60,
    street3           TYPE C LENGTH 40,
    street4           TYPE C LENGTH 40,
    street5           TYPE C LENGTH 40,
    city              TYPE C LENGTH 40,
    district          TYPE C LENGTH 40,
    state             TYPE n LENGTH 2,
    postalcode        TYPE C LENGTH 40,
    COUNTRY           TYPE C LENGTH 2,
    gstn              TYPE C LENGTH 15,
    phone             TYPE n LENGTH 10,
    email             TYPE C LENGTH 60,
    lang              TYPE C LENGTH 2,
    search1           TYPE C LENGTH 20,
    search2           TYPE C LENGTH 20,
    contactp          TYPE C LENGTH 40,
    bifsc             TYPE C LENGTH 11,
    baccno            TYPE C LENGTH 40,
    taxtype           TYPE C LENGTH 5,
    taxnum            TYPE C LENGTH 40,
    idtype            TYPE C LENGTH 5,
    idno              TYPE C LENGTH 40,
    salesorg          TYPE C LENGTH 10,
    dischannel        TYPE C LENGTH 10,
    division          TYPE C LENGTH 10,
    salesdis          TYPE C LENGTH 10,
    cusgrp            TYPE C LENGTH 10,
    salesoffice       TYPE C LENGTH 10,
    salesgrp          TYPE C LENGTH 10,
    ordprobability    TYPE C LENGTH 10,
    CURRENCY          TYPE C LENGTH 10,
    priprocedure      TYPE C LENGTH 10,
    shipcondition     TYPE C LENGTH 10,
    incoterm1         TYPE C LENGTH 10,
    incotermloc1      TYPE C LENGTH 10,
    salespaymentterm  TYPE C LENGTH 10,
    cuspricegrp       TYPE C LENGTH 10,
    partnerfun        TYPE C LENGTH 20,
    partnerfunno      TYPE C LENGTH 10,
    companycode       TYPE C LENGTH 10,
    Reconciliationacc TYPE C LENGTH 10,
    comppaymentterm   TYPE C LENGTH 10,
    panno             TYPE C LENGTH 15,
    panname           TYPE C LENGTH 40,
    credit_sgmnt      TYPE C LENGTH 10,
    risk_class        TYPE C LENGTH 10,
    check_rule        TYPE C LENGTH 10,
    credit_group      TYPE C LENGTH 10,
    limit_rule        TYPE C LENGTH 10,
    credit_limit      TYPE C LENGTH 10,
    pan               TYPE string,
    aadhar            TYPE string,
    gst               TYPE string,
    fssai             TYPE string,
    tds               TYPE string,
    cheque            TYPE string,
    TAN               TYPE string,
    lv_pan_ftype      TYPE saeobjart,
    lv_aadhar_ftype   TYPE saeobjart,
    lv_gst_ftype      TYPE saeobjart,
    lv_fssai_ftype    TYPE saeobjart,
    lv_tds_ftype      TYPE saeobjart,
    lv_cheque_ftype   TYPE saeobjart,
    lv_tan_ftype      TYPE saeobjart,
    lv_pan_fname      TYPE C LENGTH 255,
    lv_aadhar_fname   TYPE C LENGTH 255,
    lv_gst_fname      TYPE C LENGTH 255,
    lv_fssai_fname    TYPE C LENGTH 255,
    lv_tds_fname      TYPE C LENGTH 255,
    lv_cheque_fname   TYPE C LENGTH 255,
    lv_tan_fname      TYPE C LENGTH 255,
  END OF ts_cust.

  DATA : lt_cust      TYPE TABLE OF ts_cust,
           ls_cust      TYPE ts_cust,
           lv_msg       TYPE string.


    DATA(lo_entity) = mo_request->get_entity( ).
    DATA(lt_cust_raw) = lo_entity->get_string_data( ).

    /ui2/cl_json=>deserialize(
      EXPORTING
        json             = lt_cust_raw             " JSON string
      CHANGING
        data             =    lt_cust            " Data to serialize
    ).

  EXPORT lt_cust = lt_cust TO MEMORY ID 'CUSTOMER'.

  SUBMIT ZCUSTOMER EXPORTING LIST TO MEMORY AND RETURN.

  IMPORT lv_msg TO lv_msg FROM MEMORY ID 'CUST_MSG'.

  /ui2/cl_json=>serialize(
  EXPORTING
  DATA             =     lv_msg             " Data to serialize
        RECEIVING
  r_json           =     DATA(lv_json)             " JSON string
  ).

  mo_response->create_entity( )->set_string_data( iv_data = lv_json ).

  ENDMETHOD.
