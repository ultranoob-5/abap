*&---------------------------------------------------------------------*
*& Report ZCUST_LEDGER_RPT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zcust_ledger_rpt.

*TYPES : BEGIN OF ts_report,
*  Assignment       TYPE dzuonr,
*  DocumentNo       TYPE belnr_d,
*  DocumentType     TYPE blart,
*  DocumentDate     TYPE bldat,
*  Amount           TYPE dmshb_x8,
*  LocalCurrency    TYPE hwaer,
*  ClearingDocument TYPE augbl,
*  text             TYPE sgtxt,
*END OF ts_report.

TYPES : BEGIN OF ts_report,
          zuonr TYPE dzuonr,    " Assignment
          belnr TYPE belnr_d,   " Document No
          blart TYPE blart,     " Type
          bldat TYPE bldat,     " Document Date
          dmshb TYPE dmshb_x8,  " Amount
          hwaer TYPE hwaer,     " Currency
          augbl TYPE augbl,     " Clearing Document Number
          sgtxt TYPE sgtxt,     " Item Text
        END OF ts_report.

DATA : it_report  TYPE TABLE OF ts_report,
       wa_report  TYPE ts_report,
       lv_cust    TYPE knb1-kunnr,
       lv_comp    TYPE knb1-bukrs,
       lv_status  TYPE c,
       lv_postds  TYPE budat,
       lv_postde  TYPE budat,
       lv_postd   TYPE budat.

*DATA r_pos TYPE REF TO data.

SELECT-OPTIONS : r_cust   FOR lv_cust,
                 r_comp   FOR lv_comp,
                 r_postd  FOR lv_postd.

FIELD-SYMBOLS : <lt_pos> TYPE table.

IMPORT lv_cust TO lv_cust FROM MEMORY ID 'CUST'.
IMPORT lv_comp TO lv_comp FROM MEMORY ID 'COMP'.
IMPORT lv_status TO lv_status FROM MEMORY ID 'STATUS'.
IMPORT lv_postds TO lv_postds FROM MEMORY ID 'POSTDS'.
IMPORT lv_postde TO lv_postde FROM MEMORY ID 'POSTDE'.

IF lv_cust IS NOT INITIAL.
  r_cust-low = lv_cust.
  r_cust-option = 'EQ'.
  r_cust-sign = 'I'.
  APPEND r_cust.
ENDIF.

IF lv_comp IS NOT INITIAL.
  r_comp-low = lv_comp.
  r_comp-option = 'EQ'.
  r_comp-sign = 'I'.
  APPEND r_comp.
ENDIF.

IF lv_postds IS NOT INITIAL.
    r_postd-low = lv_postds.
  r_postd-option = 'GE'.
  r_postd-sign = 'I'.
  APPEND r_postd.
IF lv_postde IS NOT INITIAL.
  r_postd-high = lv_postde.
  r_postd-option = 'LE'.
  r_postd-sign = 'I'.
  APPEND r_postd.
  ELSEIF lv_postde IS INITIAL.
    r_postd-high = sy-datum.
  r_postd-option = 'LE'.
  r_postd-sign = 'I'.
  APPEND r_postd.
ENDIF.
ENDIF.

START-OF-SELECTION.
cl_salv_bs_runtime_info=>set(
    display        = abap_false
    metadata       = abap_false
    data           = abap_true
).

  CASE lv_status.
    WHEN 'X'.
      SUBMIT rfitemar USING SELECTION-SCREEN '1000' WITH dd_kunnr IN r_cust[]
                                                    WITH so_wlbuk IN r_comp[]
                                                    WITH x_opsel = abap_true
                                                    WITH pa_stida LE lv_postds
                                                    AND RETURN. "#EC CI_SUBMIT
    WHEN 'Y'.
      SUBMIT rfitemar USING SELECTION-SCREEN '1000' WITH dd_kunnr IN r_cust[]
                                                    WITH so_wlbuk IN r_comp[]
                                                    WITH x_clsel = abap_true
                                                    WITH so_augdt IN r_postd[]
                                                    AND RETURN. "#EC CI_SUBMIT

    WHEN 'Z'.
      SUBMIT rfitemar USING SELECTION-SCREEN '1000' WITH dd_kunnr IN r_cust[]
                                                    WITH so_wlbuk IN r_comp[]
                                                    WITH x_aisel = abap_true
                                                    WITH so_budat IN r_postd[]
                                                    AND RETURN. "#EC CI_SUBMIT
  ENDCASE.

TRY.
cl_salv_bs_runtime_info=>get_data_ref(
  IMPORTING
    r_data            = DATA(r_pos)
).

ASSIGN r_pos->* TO <lt_pos>.

      IF <lt_pos> IS ASSIGNED.
        LOOP AT <lt_pos> ASSIGNING FIELD-SYMBOL(<ls_pos>).
          MOVE-CORRESPONDING <ls_pos> TO wa_report.
          APPEND wa_report TO it_report.
          CLEAR wa_report.
         ENDLOOP.
      ENDIF.

      IF lv_status = 'Z'.

        ##ITAB_KEY_IN_SELECT
        ##ITAB_DB_SELECT
        SELECT SUM( dmshb ) AS total FROM @it_report AS a WHERE augbl IS NOT INITIAL INTO @DATA(lv_sum) .
        wa_report-dmshb = lv_sum.
        APPEND wa_report TO it_report.
        CLEAR wa_report.

      ENDIF.


      ##ITAB_KEY_IN_SELECT
      ##ITAB_DB_SELECT
      SELECT SUM( dmshb ) AS total FROM @it_report AS a INTO @lv_sum.
      wa_report-dmshb = lv_sum.
      APPEND wa_report TO it_report.
      CLEAR wa_report.

  CATCH cx_salv_bs_sc_runtime_info INTO DATA(error).
  ENDTRY.

  cl_salv_bs_runtime_info=>clear_all( ).

LOOP AT it_report ASSIGNING FIELD-SYMBOL(<ls_report>).
ENDLOOP.

EXPORT it_report[] TO MEMORY ID 'CUSTREPORT'.
