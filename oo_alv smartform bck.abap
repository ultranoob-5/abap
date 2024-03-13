*&---------------------------------------------------------------------*
*& Report  ZDP_SALESDOC
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT ZDP_SALESDOC.

DATA: lt_vbak  TYPE TABLE OF ZSTR_VBAK_SALESDOC,
      ls_vbak  TYPE ZSTR_VBAK_SALESDOC,
      lt_vbap  TYPE TABLE OF ZSTR_VBAP_SALESDOC,
      ls_vbap  TYPE ZSTR_VBAP_SALESDOC,
      lt_final TYPE TABLE OF ZSTR_FINAL_SALESDOC,
      ls_final TYPE ZSTR_FINAL_SALESDOC,
      ls_layout TYPE slis_layout_alv,
      lt_fcat   TYPE slis_t_fieldcat_alv,
      ls_fcat   TYPE slis_fieldcat_alv,
      lt_subt   TYPE slis_t_sortinfo_alv,
      ls_subt   TYPE slis_sortinfo_alv,
      lv_prog   TYPE sy-repid,
      lt_listh  TYPE slis_t_listheader,
      ls_listh  TYPE slis_listheader.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-002.
PARAMETERS: p_vbeln TYPE vbak-vbeln.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

IF p_vbeln IS INITIAL.
  MESSAGE: text-001 TYPE 'E'.
ELSEIF p_vbeln IS NOT INITIAL.
  SELECT vbeln erdat erzet ernam
    FROM vbak
    INTO TABLE lt_vbak
    WHERE vbeln = p_vbeln.
ENDIF.

IF lt_vbak IS NOT INITIAL.
  SELECT vbeln posnr matnr matwa
    FROM vbap
    INTO TABLE lt_vbap
    FOR ALL ENTRIES IN lt_vbak
    WHERE vbeln = lt_vbak-vbeln.
ENDIF.

LOOP AT lt_vbap INTO ls_vbap.
  ls_final-vbeln = ls_vbap-vbeln.
  ls_final-posnr = ls_vbap-posnr.
  ls_final-matnr = ls_vbap-matnr.
  ls_final-matwa = ls_vbap-matwa.
  READ TABLE lt_vbak INTO ls_vbak WITH KEY vbeln = ls_vbap-vbeln BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    ls_final-erdat = ls_vbak-erdat.
    ls_final-erzet = ls_vbak-erzet.
    ls_final-ernam = ls_vbak-ernam.
  ENDIF.
  APPEND ls_final TO lt_final.
  CLEAR: ls_final, ls_vbak, ls_vbap.
ENDLOOP.

*ls_layout-colwidth_optimize = 'X'.
*ls_layout-zebra = 'X'.
*
*CLEAR: ls_fcat.
*ls_fcat-col_pos = '1'.
*ls_fcat-fieldname = 'VBELN'.
*ls_fcat-seltext_m = 'Sales Document'.
*ls_fcat-tabname = 'LT_FINAL'.
*APPEND ls_fcat TO lt_fcat.
*
*CLEAR: ls_fcat.
*ls_fcat-col_pos = '2'.
*ls_fcat-fieldname = 'ERDAT'.
*ls_fcat-seltext_m = 'Date on Which Record Was Created'.
*ls_fcat-tabname = 'LT_FINAL'.
*APPEND ls_fcat TO lt_fcat.
*
*CLEAR: ls_fcat.
*ls_fcat-col_pos = '3'.
*ls_fcat-fieldname = 'ERZET'.
*ls_fcat-seltext_m = 'Entry time'.
*ls_fcat-tabname = 'LT_FINAL'.
*APPEND ls_fcat TO lt_fcat.
*
*CLEAR: ls_fcat.
*ls_fcat-col_pos = '4'.
*ls_fcat-fieldname = 'ERNAM'.
*ls_fcat-seltext_m = 'Name of Person who Created the Object'.
*ls_fcat-tabname = 'LT_FINAL'.
*APPEND ls_fcat TO lt_fcat.
*
*CLEAR: ls_fcat.
*ls_fcat-col_pos = '5'.
*ls_fcat-fieldname = 'POSNR'.
*ls_fcat-seltext_m = 'Sales Document Item'.
*ls_fcat-tabname = 'LT_FINAL'.
*APPEND ls_fcat TO lt_fcat.
*
*CLEAR: ls_fcat.
*ls_fcat-col_pos = '6'.
*ls_fcat-fieldname = 'MATNR'.
*ls_fcat-seltext_m = 'Material Number'.
*ls_fcat-tabname = 'LT_FINAL'.
*APPEND ls_fcat TO lt_fcat.
*
*CLEAR: ls_fcat.
*ls_fcat-col_pos = '7'.
*ls_fcat-fieldname = 'MATWA'.
*ls_fcat-seltext_m = 'Material entered'.
*ls_fcat-tabname = 'LT_FINAL'.
*APPEND ls_fcat TO lt_fcat.

    cl_salv_table=>factory(
    IMPORTING
    r_salv_table = DATA(lo_alv)
    CHANGING
      t_table      = lt_final
      ).

    DATA lo_columns TYPE REF TO cl_salv_columns.
    lo_columns = lo_alv->get_columns( ).
    lo_columns->set_optimize( 'X' ).

    DATA lo_zebra TYPE REF TO cl_salv_display_settings.
    lo_zebra = lo_alv->get_display_settings( ).
    lo_zebra->set_striped_pattern( cl_salv_display_settings=>true ).

    DATA: lo_logo  TYPE REF TO cl_salv_form_layout_logo,
          lo_grid  TYPE REF TO cl_salv_form_layout_grid,
                    lv_title TYPE string,
          lv_row TYPE string,
          lo_label TYPE REF TO cl_salv_form_label,
          lo_content TYPE REF TO cl_salv_form_element.

        CREATE OBJECT lo_grid.
    CREATE OBJECT lo_logo.

    CLEAR: lv_row.
    DESCRIBE TABLE lt_final LINES lv_row.
    lo_logo->set_right_logo( 'ENJOYSAP_LOGO' ).

    lo_label = lo_grid->create_label(
    EXPORTING
      row         =   1  " Natural Number
      column      =   1  " Natural Number
        text        =  'Sales Document'
        tooltip     = 'Sales Document'
      ).


    lo_grid->create_label(
      EXPORTING
        row         =   2
        column      =   1
        text        =  'No of Records:'
        tooltip     =  'No of Records:'
    ).

    lo_grid->create_text(
      EXPORTING
        row         =   2
        column      =   2
        text        =  lv_row
        tooltip     =  lv_row
    ).

    lo_grid->create_label(
      EXPORTING
        row         =  3   " Natural Number
        column      =  1  " Natural Number
        text        = 'Date :'
        tooltip     = 'Date :'
    ).

    lo_grid->create_text(
      EXPORTING
        row     =    3 " Natural Number
        column  =    2 " Natural Number
        text    = sy-datum
        tooltip = sy-datum
    ).

    lo_grid->create_label(
      EXPORTING
        row         =  4   " Natural Number
        column      =  1  " Natural Number
        text        = 'Program Name :'
        tooltip     = 'Program Name :'
    ).

    lo_grid->create_text(
      EXPORTING
        row         =  4   " Natural Number
        column      =  2  " Natural Number
        text        = sy-cprog
        tooltip     = sy-cprog
    ).


    lo_logo->set_left_content( lo_grid ).
    lo_content = lo_logo.
    lo_alv->set_top_of_list( lo_content ).

    SET PF-STATUS 'ZSALESBT'.
    lo_alv->set_screen_status(
      EXPORTING
        report        =  sy-repid   " ABAP Program: Current Main Program
        pfstatus      =   'ZSALESBT'  " Screens, Current GUI Status
        set_functions = lo_alv->c_functions_all    " ALV: Data Element for Constants
    ).

    lo_alv->display( ).

*CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
*  EXPORTING
*    i_callback_program = sy-repid
*    i_callback_pf_status_set = 'BUTTON'
*    i_callback_user_command  = 'UCOMMAND'
*    i_callback_top_of_page   = 'TOP_OF_PAGE'
*    is_layout          = ls_layout
*    it_fieldcat        = lt_fcat
*  TABLES
*    t_outtab           = lt_final.
*
*FORM top_of_page.
*  DATA: lv_total TYPE i.
*  DESCRIBE TABLE lt_final LINES lv_total.
*
*  CLEAR ls_listh.
*  ls_listh-typ = 'H'.
*  ls_listh-info = 'SALES DOCUMENT REPORT'.
*  APPEND ls_listh TO lt_listh.
*
*  CLEAR ls_listh.
*  ls_listh-typ = 'S'.
*  ls_listh-info = lv_total.
*  ls_listh-key = 'Number of Records:'.
*  APPEND ls_listh TO lt_listh.
*
*  CLEAR ls_listh.
*  ls_listh-typ = 'S'.
*  ls_listh-info = sy-cprog.
*  ls_listh-key = 'Program Name: '.
*  APPEND ls_listh TO lt_listh.
*
*  CLEAR ls_listh.
*  ls_listh-typ = 'S'.
*  ls_listh-key = 'Date:'.
*  CONCATENATE sy-datum+6(2)
*  sy-datum+4(2)
*  sy-datum(4)
*  INTO ls_listh-info
*  SEPARATED BY '/'.
*  APPEND ls_listh TO lt_listh.
*
*  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
*    EXPORTING
*      it_list_commentary = lt_listh.
*
*  REFRESH lt_listh.
*
*
*ENDFORM.
*
*FORM button USING lv_status TYPE slis_t_extab.
*  SET PF-STATUS 'ZSALESBT'.
*ENDFORM.
*
*FORM ucommand USING ucomm LIKE sy-ucomm
*      lv_button TYPE slis_selfield.
*
*  CASE ucomm.
*
*    WHEN 'PDF'.
*        DATA: sfname TYPE rs38l_fnam.
*
* CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
*   EXPORTING
*     formname                 = 'ZSF_SALESDOC'
*  IMPORTING
*    FM_NAME                  = sfname
*  EXCEPTIONS
*    NO_FORM                  = 1
*    NO_FUNCTION_MODULE       = 2
*    OTHERS                   = 3.
*
* CALL FUNCTION sfname
*  TABLES
*    final = LT_FINAL.
*  ENDCASE.
*
*ENDFORM.
*
*
