*&---------------------------------------------------------------------*
*& Report ZSALES_CONTRACT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsales_contract.

TYPES : BEGIN OF gty_sc,
  sr_no   TYPE int8,       " Serial number of the sales contract
  auart   TYPE auart,      " Sales document type
  vkorg   TYPE vkorg,      " Sales organization
  vtweg   TYPE vtweg,      " Distribution channel
  spart   TYPE spart,      " Division
  vkbur   TYPE vkbur,      " Sales office
  vkgrp   TYPE vkgrp,      " Sales group
  guebg   TYPE guebg,      " Start of validity period
  gueen   TYPE gueen,      " End of validity period
  waers   TYPE waers,      " Currency
  ebeln   TYPE ebeln,      " Purchase order number
  aedat   TYPE aedat,      " Document date
  vbeln   TYPE vbeln,      " Sales document number
  inco1   TYPE inco1,      " Incoterms (Part 1)
  inco2_l TYPE inco2_l,    " Incoterms (Part 2)
  zterm   TYPE dzterm,     " Payment terms
  parvw   TYPE parvw,      " Partner function
  kunnr   TYPE kunnr,      " Customer number
  posnr   TYPE posnr,      " Item number
  matnr   TYPE matnr,      " Material number
  kwmeng  TYPE kwmeng,     " Target quantity
  werks   TYPE werks_d,    " Plant
  kschl   TYPE kschl,      " Condition type
  kwert   TYPE vfprc_element_value, " Condition value
  Remarks TYPE string,
  ShipFromDate TYPE datum,
  ShipToDate TYPE datum,
  VesselName TYPE string,
  DutyCondition TYPE string,
  DeliveryFromDate TYPE datum,
  DeliveryToDate TYPE datum,
  Origin TYPE string,
END OF gty_sc,

BEGIN OF gty_log,
  vbeln TYPE char20,    " Sales document number for logging
  msgs  TYPE string,    " Log messages
END OF gty_log.

" Define internal tables and work structures for processing
DATA: gt_sc             TYPE TABLE OF gty_sc,      " Table to store sales contract data
      gt_log            TYPE TABLE OF gty_log,     " Table to store logs
      gs_con_header_in  TYPE bapisdhd1,            " BAPI structure for contract header input
      gs_con_header_inx TYPE bapisdhd1x,           " BAPI structure for contract header input (change indicators)
      gt_con_items_in   TYPE TABLE OF bapisditm,   " BAPI table for contract items
      gt_con_items_inx  TYPE TABLE OF bapisditmx,  " BAPI table for contract items (change indicators)
      gt_con_partners   TYPE TABLE OF bapiparnr,   " BAPI table for contract partners
      gt_con_conds_in   TYPE TABLE OF bapicond,    " BAPI table for contract conditions
      gt_con_conds_inx  TYPE TABLE OF bapicondx,   " BAPI table for contract conditions (change indicators)
      gt_con_data_in    TYPE TABLE OF bapictr,     " BAPI table for contract data
      gt_con_data_inx   TYPE TABLE OF bapictrx,    " BAPI table for contract data (change indicators)
      gt_con_text       TYPE TABLE OF bapisdtext,
      gt_return         TYPE TABLE OF bapiret2,    " BAPI return messages
      gs_return         TYPE bapiret2,             " Single BAPI return message
      gv_vbeln          TYPE vbeln_va.             " Sales document number returned by BAPI

DATA:   BDCDATA LIKE BDCDATA    OCCURS 0 WITH HEADER LINE.
DATA:   MESSTAB LIKE BDCMSGCOLL OCCURS 0 WITH HEADER LINE.

IMPORT gt_sc TO gt_sc FROM MEMORY ID 'SALESCONTRACT'.  " Import Sales Contract data from memory

" Filter out records with empty material numbers and remove duplicates
DATA(lt_mat) = gt_sc.
DELETE lt_mat WHERE matnr IS INITIAL.
SORT lt_mat BY matnr.
DELETE ADJACENT DUPLICATES FROM lt_mat COMPARING matnr.

" Convert material numbers to internal format if necessary
IF lt_mat IS NOT INITIAL.
  LOOP AT lt_mat ASSIGNING FIELD-SYMBOL(<lf_mat>).
    IF <lf_mat> IS ASSIGNED.
      <lf_mat>-matnr = CONV matnr18( |{ <lf_mat>-matnr ALPHA = IN }| ).
    ENDIF.
  ENDLOOP.
  UNASSIGN: <lf_mat>.

  " Retrieve additional material data from the database
  SELECT mvke~matnr,
  mvke~vkorg,
  mvke~vtweg,
  mvke~vrkme,
  mara~meins
  FROM mara
  LEFT OUTER JOIN mvke ON mvke~matnr = mara~matnr
  FOR ALL ENTRIES IN @lt_mat
  WHERE mara~matnr = @lt_mat-matnr
  INTO TABLE @DATA(lt_mat_unit).

  " Clear the result table if no data was found
  IF sy-subrc NE 0.
    CLEAR: lt_mat_unit.
  ENDIF.
ENDIF.

" Sort sales contract data for processing
SORT gt_sc BY sr_no posnr.

" Loop through each sales contract record
LOOP AT gt_sc ASSIGNING FIELD-SYMBOL(<ls_sc>).
  DATA(ls_sc_tmp) = <ls_sc>.

  " Find the corresponding material unit
  DATA(ls_mat_unit) = VALUE #( lt_mat_unit[ matnr = CONV matnr18( |{ <ls_sc>-matnr ALPHA = IN }| ) ] OPTIONAL ).

  " Convert material number to internal format
  IF ls_sc_tmp-matnr IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_MATN5_INPUT'
    EXPORTING
      INPUT  = ls_sc_tmp-matnr
    IMPORTING
      OUTPUT = ls_sc_tmp-matnr.
  ENDIF.

  " Convert partner function to internal format
  IF ls_sc_tmp-parvw IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_PARVW_INPUT'
    EXPORTING
      INPUT  = ls_sc_tmp-parvw
    IMPORTING
      OUTPUT = ls_sc_tmp-parvw.
  ENDIF.

  " Convert customer number to internal format
  IF ls_sc_tmp-kunnr IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      INPUT  = ls_sc_tmp-kunnr
    IMPORTING
      OUTPUT = ls_sc_tmp-kunnr.
  ENDIF.

  IF ls_sc_tmp-auart IS NOT INITIAL AND gs_con_header_in IS INITIAL.
    gs_con_header_in = VALUE #(
    doc_type    = ls_sc_tmp-auart
    sales_org   = ls_sc_tmp-vkorg
    distr_chan  = ls_sc_tmp-vtweg
    division    = ls_sc_tmp-spart
    incoterms1  = ls_sc_tmp-inco1
    pmnttrms    = ls_sc_tmp-zterm
    ct_valid_f  = ls_sc_tmp-guebg
    ct_valid_t  = ls_sc_tmp-gueen
    incoterms2l = ls_sc_tmp-inco2_l
    CURRENCY    = ls_sc_tmp-waers
    purch_no_c  = ls_sc_tmp-ebeln
    purch_no_s  = ls_sc_tmp-vbeln
    purch_date  = ls_sc_tmp-aedat
    ord_reason  = 'Z06'
    ).

    gs_con_header_inx = VALUE #(
    updateflag  = 'I'
    sales_org   = abap_true
    distr_chan  = abap_true
    division    = abap_true
    incoterms1  = abap_true
    pmnttrms    = abap_true
    ct_valid_f  = abap_true
    ct_valid_t  = abap_true
    incoterms2l = abap_true
    purch_no_c  = abap_true
    purch_no_s  = abap_true
    purch_date  = abap_true
    ord_reason  = abap_true
    ).

    IF gt_con_data_in IS INITIAL.
      APPEND VALUE #( con_st_dat = ls_sc_tmp-guebg
      con_si_dat = ls_sc_tmp-gueen
      con_en_dat = ls_sc_tmp-gueen ) TO gt_con_data_in.

      APPEND VALUE #( updateflag  = 'I'
      con_st_dat  = CONV bapiupdate( abap_true )
      con_si_dat  = CONV bapiupdate( abap_true )
      con_en_dat  = CONV bapiupdate( abap_true ) ) TO gt_con_data_inx.
    ENDIF.
  ENDIF.

  IF ls_sc_tmp-parvw IS NOT INITIAL.
    gt_con_partners = VALUE #(
    BASE gt_con_partners
    ( partn_role = ls_sc_tmp-parvw
    partn_numb = CONV kunnr( ls_sc_tmp-kunnr ) )
    ).
  ENDIF.

  IF ls_sc_tmp-posnr IS NOT INITIAL.
    IF line_exists( gt_con_items_in[ itm_number = ls_sc_tmp-posnr ] ).
      APPEND VALUE #( itm_number  = CONV posnr_va( ls_sc_tmp-posnr )
      cond_type   = CONV kscha( ls_sc_tmp-kschl )
      cond_value  = CONV bapikbetr1( ls_sc_tmp-kwert )
      CURRENCY    = gs_con_header_in-CURRENCY
      cond_unit   = CONV kmein(
      COND #( WHEN ls_mat_unit-vrkme IS NOT INITIAL
      THEN ls_mat_unit-vrkme
      ELSE ls_mat_unit-meins ) )
      cond_p_unt  = '1' ) TO gt_con_conds_in.

      APPEND VALUE #( itm_number  = CONV posnr_va( ls_sc_tmp-posnr )
      cond_type   = CONV kscha( ls_sc_tmp-kschl )
      updateflag  = CONV updkz_d( 'I' )
      cond_value  = CONV bapiupdate( abap_true ) ) TO gt_con_conds_inx.

    ELSE.
      APPEND VALUE #( itm_number  = CONV posnr_va( ls_sc_tmp-posnr )
      material    = CONV matnr18( ls_sc_tmp-matnr )
      plant       = CONV werks_d( ls_sc_tmp-werks )
      target_qty  = CONV dzmeng( ls_sc_tmp-kwmeng ) ) TO gt_con_items_in.

      APPEND VALUE #( itm_number  = CONV bapicondx( ls_sc_tmp-posnr )
      material    = CONV bapiupdate( abap_true )
      plant       = CONV bapiupdate( abap_true ) ) TO gt_con_items_inx.

      APPEND VALUE #( itm_number  = CONV posnr_va( ls_sc_tmp-posnr )
      cond_type   = CONV kscha( ls_sc_tmp-kschl )
      cond_value  = CONV bapikbetr1( ls_sc_tmp-kwert )
      CURRENCY    = gs_con_header_in-CURRENCY
      cond_unit   = CONV kmein(
      COND #( WHEN ls_mat_unit-vrkme IS NOT INITIAL
      THEN ls_mat_unit-vrkme
      ELSE ls_mat_unit-meins ) )
      cond_p_unt  = '1' ) TO gt_con_conds_in.

      APPEND VALUE #( itm_number  = CONV posnr_va( ls_sc_tmp-posnr )
      cond_type   = CONV kscha( ls_sc_tmp-kschl )
      updateflag  = CONV updkz_d( 'I' )
      cond_value  = CONV bapiupdate( abap_true ) ) TO gt_con_conds_inx.
    ENDIF.
  ENDIF.

  gt_con_text = VALUE #( ( text_id = 'ZD08'
                           langu = 'EN'
                           text_line = ls_sc_tmp-remarks ) ).


  AT END OF sr_no.
    CALL FUNCTION 'BAPI_CONTRACT_CREATEFROMDATA'
    EXPORTING
      contract_header_in      = gs_con_header_in
      contract_header_inx     = gs_con_header_inx
    IMPORTING
      salesdocument           = gv_vbeln
    TABLES
      RETURN                  = gt_return
      contract_items_in       = gt_con_items_in
      contract_items_inx      = gt_con_items_inx
      contract_partners       = gt_con_partners
      contract_conditions_in  = gt_con_conds_in
      contract_conditions_inx = gt_con_conds_inx
      contract_data_in        = gt_con_data_in
      contract_data_inx       = gt_con_data_inx
      contract_text           = gt_con_text.

    IF line_exists( gt_return[ TYPE = 'E' ] ).
      gt_log = VALUE #( BASE gt_log
      FOR ls IN gt_return WHERE ( TYPE = 'E' )
      ( vbeln = gs_con_header_in-purch_no_s
      msgs  = ls-MESSAGE ) ).

    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      IMPORTING
        RETURN = gs_return.

      IF gs_return-TYPE = 'E'.
        APPEND VALUE #( vbeln = gs_con_header_in-purch_no_s
        msgs  = gs_return-MESSAGE  ) TO gt_log.
      ELSE.
        APPEND VALUE #( vbeln = gv_vbeln
        msgs  = gv_vbeln && ' ' && TEXT-001 ) TO gt_log.

        DATA(shipfromdatec) = |{ ls_sc_tmp-shipfromdate DATE = USER }|.
        DATA(shiptodatec) = |{ ls_sc_tmp-shiptodate DATE = USER }|.
        DATA(deliveryfromdate) = |{ ls_sc_tmp-deliveryfromdate DATE = USER }|.
        DATA(deliverytodate) = |{ ls_sc_tmp-deliverytodate DATE = USER }|.

        PERFORM bdc_dynpro      USING 'SAPMV45A' '0102'.
        PERFORM bdc_field       USING 'VBAK-VBELN'
              gv_vbeln.
        PERFORM bdc_field       USING 'BDC_OKCODE'
              '=ENT2'.
        PERFORM bdc_dynpro      USING 'SAPMV45A' '4001'.
        PERFORM bdc_field       USING 'BDC_OKCODE'
              '=HEAD'.
        PERFORM bdc_dynpro      USING 'SAPMV45A' '4002'.
        PERFORM bdc_field       USING 'BDC_OKCODE'
              '=T\13'.
        PERFORM bdc_dynpro      USING 'SAPMV45A' '4002'.
        PERFORM bdc_field       USING 'VBAK-ZZSHIP_FROM_DATE'
              shipfromdatec.
        PERFORM bdc_field       USING 'VBAK-ZZSHIP_TO_DATE'
              shiptodatec.
        PERFORM bdc_field       USING 'VBAK-ZZVESSEL_NAME'
              ls_sc_tmp-vesselname.
        PERFORM bdc_field       USING 'VBAK-ZZDUTY_COND'
              ls_sc_tmp-dutycondition.
        PERFORM bdc_field       USING 'VBAK-ZZDEL_FROM_DATE'
              deliveryfromdate.
        PERFORM bdc_field       USING 'VBAK-ZZDEL_TO_DATE'
              deliverytodate.
        PERFORM bdc_field       USING 'VBAK-ZZORIGIN'
              ls_sc_tmp-origin.
        PERFORM bdc_field       USING 'BDC_OKCODE'
              '=SICH'.

        WAIT UP TO 2 SECONDS.

        CALL TRANSACTION 'VA42' WITHOUT AUTHORITY-CHECK USING bdcdata MODE 'N' UPDATE 'S' MESSAGES INTO messtab.

        IF sy-subrc <> 0.

          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          APPEND VALUE #( vbeln = gs_con_header_in-purch_no_s
          msgs  = |BDC ERROR { messtab-msgv1 } { messtab-msgv2 } { messtab-msgv3 } { messtab-msgv4 } | ) TO gt_log.

        ENDIF.

      ENDIF.
    ENDIF.

    CLEAR: gs_con_header_in, gs_con_header_inx, gv_vbeln, gs_return,
    gt_return, gt_con_items_in, gt_con_items_inx, gt_con_partners,
    gt_con_conds_in, gt_con_conds_inx, gt_con_data_in, gt_con_data_inx,gt_con_text,
    deliveryfromdate,deliverytodate,shipfromdatec,shiptodatec.
  ENDAT.
  CLEAR: ls_mat_unit.
ENDLOOP.
UNASSIGN <ls_sc>.

" Export final message to memory for display or further processing
  EXPORT gt_log = gt_log TO MEMORY ID 'SALESCONTRACTMSG'.

FORM BDC_DYNPRO USING PROGRAM DYNPRO.
  CLEAR BDCDATA.
  BDCDATA-PROGRAM  = PROGRAM.
  BDCDATA-DYNPRO   = DYNPRO.
  BDCDATA-DYNBEGIN = 'X'.
  APPEND BDCDATA.
ENDFORM.

FORM BDC_FIELD USING FNAM FVAL.
  CLEAR BDCDATA.
  BDCDATA-FNAM = FNAM.
  BDCDATA-FVAL = FVAL.
  APPEND BDCDATA.
ENDFORM.
