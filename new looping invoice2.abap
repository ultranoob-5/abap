  METHOD if_rest_resource~get.

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
  END OF ts_final,

  BEGIN OF ts_date,
    start_date TYPE vbrk-fkdat,
    end_date TYPE vbrk-fkdat,
    END OF ts_date,
    tt_date TYPE STANDARD TABLE OF ts_date WITH DEFAULT KEY.

  DATA : r_vbeln TYPE RANGE OF vbrk-vbeln,
         r_fkdat TYPE RANGE OF vbrk-fkdat,
        lt_final TYPE TABLE OF ts_final.
*        wa_final TYPE ts_final.

*  DATA(lv_invoiceno) = mo_request->get_uri_query_parameter('INVOICENUMBER').
  DATA(lv_sdate) = mo_request->get_uri_query_parameter('START_DATE').
  DATA(lv_edate) = mo_request->get_uri_query_parameter('END_DATE').

IF NOT lv_sdate IS INITIAL AND NOT lv_edate IS INITIAL.
  DATA(gt_date) = VALUE tt_date( ( start_date = lv_sdate end_date = lv_edate ) ).

  r_fkdat = VALUE #(
  FOR fkdat IN gt_date[]
  LET s = 'I'
  o = 'BT'
  IN sign = s option = o ( low = fkdat-start_date high = fkdat-end_date )
  ).
ENDIF.

IF NOT r_fkdat[] IS INITIAL.
  SELECT  FROM vbrk
          FIELDS vbeln, fkdat
          WHERE fkdat IN @r_fkdat[]
      INTO TABLE @DATA(lt_vbrk).
ELSEIF lv_sdate IS INITIAL.
  SELECT vbeln, fkdat
      INTO TABLE @lt_vbrk
      FROM vbrk
      WHERE vbeln IS NOT NULL.
ELSEIF NOT lv_sdate IS INITIAL AND lv_edate IS INITIAL.
  SELECT FROM vbrk
         FIELDS vbeln, fkdat
         WHERE fkdat EQ @lv_sdate
    INTO TABLE @lt_vbrk.
ENDIF .
  SORT lt_vbrk BY vbeln.

* Step 2: Populate range table for vbeln
  r_vbeln = VALUE #(
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
  IF lt_vbrk IS NOT INITIAL.
    SELECT vbeln, aubel, vgbel, posnr, matnr, arktx, fklmg
    INTO TABLE @DATA(lt_vbrp)
          FROM vbrp
          FOR ALL ENTRIES IN @lt_vbrk
          WHERE vbeln = @lt_vbrk-vbeln.

    SORT lt_vbrp BY vbeln.
   ENDIF.
* Step 5: Select distinct vbelv from vbfa
  IF lt_vbrk IS NOT INITIAL.
    SELECT DISTINCT vbeln, vbelv
    INTO TABLE @DATA(lt_vbfa)
          FROM vbfa
          FOR ALL ENTRIES IN @lt_vbrk
          WHERE vbeln = @lt_vbrk-vbeln
          AND vbtyp_v = 'G'. "#EC CI_NOFIELD

    SORT lt_vbfa BY vbeln.
   ENDIF.
** Step 6: Combine data into ts_final
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
