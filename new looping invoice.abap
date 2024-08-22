  METHOD if_rest_resource~get.
*CALL METHOD SUPER->IF_REST_RESOURCE~GET
*    .

  TYPES: BEGIN OF ts_final,
    SAPDocNumber     TYPE vbelv,       " Billing Document Number
    SalesOrderNumber TYPE aubel,       " Sales Order Number
    InvoiceNumber    TYPE vbeln,       " Invoice or Sales Document Number
    SAPRefDoc        TYPE vgbel,       " Reference Document Number
    InvoiceDate      TYPE fkdat,       " Invoice Date
    InvoiceAmount    TYPE netwr,       " Invoice Amount (Net Value)
    ItemNo           TYPE posnr,       " Item Number
    MaterialNo       TYPE matnr,       " Material Number
    MaterialDesc     TYPE arktx,       " Material Description
    BillQty          TYPE fklmg,       " Billing Quantity
  END OF ts_final.

  TYPES: ts_vbeln TYPE RANGE OF vbrk-vbeln.

  DATA: r_vbeln TYPE ts_vbeln,
        lt_final TYPE TABLE OF ts_final,
        wa_final TYPE ts_final.

* Step 1: Select from vbrk
  SELECT vbeln, fkdat
  INTO TABLE @DATA(lt_vbrk)
        FROM vbrk.
  SORT lt_vbrk BY vbeln.

* Step 2: Populate range table for vbeln
  r_vbeln = VALUE ts_vbeln(
  FOR vbeln IN lt_vbrk[]
  LET s = 'I'
  o = 'EQ'
  IN sign = s option = o ( low = vbeln-vbeln )
  ).

* Step 3: Select summed values from vbrk
  SELECT vbeln, SUM( netwr + mwsbk ) AS total_sum
  INTO TABLE @DATA(lt_amount)
        FROM vbrk
        WHERE vbeln IN @r_vbeln[]
        GROUP BY vbeln.
  SORT lt_amount BY vbeln.

* Step 4: Select detailed data from vbrp
  SELECT vbeln, aubel, vgbel, posnr, matnr, arktx, fklmg
  INTO TABLE @DATA(lt_vbrp)
        FROM vbrp
        FOR ALL ENTRIES IN @lt_vbrk
        WHERE vbeln = @lt_vbrk-vbeln.
  SORT lt_vbrp BY vbeln.

* Step 5: Select distinct vbelv from vbfa
  SELECT DISTINCT vbeln, vbelv
  INTO TABLE @DATA(lt_vbfa)
        FROM vbfa
        FOR ALL ENTRIES IN @lt_vbrk
        WHERE vbeln = @lt_vbrk-vbeln
        AND vbtyp_v = 'G'.
  SORT lt_vbfa BY vbeln.

  lt_final = VALUE #( FOR wa_vbrp IN lt_vbrp[]
                      ( invoiceamount = VALUE #( lt_amount[ vbeln = wa_vbrp-vbeln ]-total_sum OPTIONAL )
                        SalesOrderNumber = wa_vbrp-aubel
                        saprefdoc = wa_vbrp-vgbel
                        itemno = wa_vbrp-posnr
                        materialno = wa_vbrp-matnr
                        materialdesc = wa_vbrp-arktx
                        billqty = wa_vbrp-fklmg
                        sapdocnumber = VALUE #( lt_vbfa[ vbeln = wa_vbrp-vbeln ]-vbelv OPTIONAL )
                        InvoiceDate = VALUE #( lt_vbrk[ vbeln = wa_vbrp-vbeln ]-fkdat OPTIONAL )
                        invoicenumber = VALUE #( lt_vbrk[ vbeln = wa_vbrp-vbeln ]-vbeln OPTIONAL ) ) ).

*  SORT lt_final[] BY invoicenumber ASCENDING.
**  DELETE ADJACENT DUPLICATES FROM lt_final[] COMPARING invoicenumber.

*** Step 6: Combine data into ts_final
*  LOOP AT lt_vbrp INTO DATA(wa_vbrp).
*    CLEAR wa_final.
*    READ TABLE lt_amount INTO DATA(wa_amount) WITH KEY vbeln = wa_vbrp-vbeln.
*    IF sy-subrc = 0.
*      wa_final-InvoiceAmount = wa_amount-total_sum.
*    ENDIF.
*
*    READ TABLE lt_vbfa INTO DATA(wa_vbfa) WITH KEY vbeln = wa_vbrp-vbeln.
*    IF sy-subrc = 0.
*      wa_final-SAPDocNumber = wa_vbfa-vbelv.
*    ENDIF.
*
*    READ TABLE lt_vbrk INTO DATA(wa_vbrk) WITH KEY vbeln = wa_vbrp-vbeln.
*    IF sy-subrc = 0.
*      wa_final-InvoiceDate = wa_vbrk-fkdat.
*      wa_final-InvoiceNumber = wa_vbrk-vbeln.
*    ENDIF.
*
*    wa_final-SalesOrderNumber = wa_vbrp-aubel.
*    wa_final-SAPRefDoc = wa_vbrp-vgbel.
*    wa_final-ItemNo = wa_vbrp-posnr.
*    wa_final-MaterialNo = wa_vbrp-matnr.
*    wa_final-MaterialDesc = wa_vbrp-arktx.
*    wa_final-BillQty = wa_vbrp-fklmg.
*
*    APPEND wa_final TO lt_final.
*    CLEAR: wa_vbrk,wa_vbrp,wa_vbfa,wa_final.
*  ENDLOOP.
*
  SORT lt_final BY InvoiceNumber.

* Step 7: Convert lt_final to JSON and create entity
  IF lt_final[] IS NOT INITIAL.
    /ui2/cl_json=>serialize(
    EXPORTING
    data             =  lt_final                " Data to serialize
          RECEIVING
    r_json           =  DATA(json)                " JSON string
          ).

    mo_response->create_entity( )->set_string_data( iv_data = json ).
  ENDIF.
ENDMETHOD.
