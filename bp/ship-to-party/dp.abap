*&---------------------------------------------------------------------*
*& Report ZDEMO_CODE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zdp_stp.

TYPES : BEGIN OF ts_stp,
          org_name        TYPE c LENGTH 40,
          street1         TYPE c LENGTH 60,
          street2         TYPE c LENGTH 60,
          street3         TYPE c LENGTH 40,
          street4         TYPE c LENGTH 40,
          street5         TYPE c LENGTH 40,
          city            TYPE c LENGTH 40,
          district        TYPE c LENGTH 40,
          state           TYPE n LENGTH 2,
          postalcode      TYPE c LENGTH 40,
          country         TYPE c LENGTH 2,
          gstn            TYPE c LENGTH 15,
          phone           TYPE n LENGTH 10,
          email           TYPE c LENGTH 60,
          lang            TYPE c LENGTH 2,
          pan             TYPE string,
          aadhar          TYPE string,
          gst             TYPE string,
          lv_pan_ftype    TYPE saeobjart,
          lv_aadhar_ftype TYPE saeobjart,
          lv_gst_ftype    TYPE saeobjart,
          lv_pan_fname    TYPE c LENGTH 255,
          lv_aadhar_fname TYPE c LENGTH 255,
          lv_gst_fname    TYPE c LENGTH 255,
        END OF ts_stp.


DATA :
  gt_stp                       TYPE TABLE OF ts_stp,
  gs_stp                       TYPE ts_stp,
  gt_cvis_data                 TYPE cvis_ei_extern_t,
  gs_cvis_data                 TYPE cvis_ei_extern,
  gt_bus_ei_addr               TYPE bus_ei_bupa_address_t,
  gt_bus_ei_tax                TYPE bus_ei_bupa_taxnumber_t,
  gt_bus_ei_smtp               TYPE bus_ei_bupa_smtp_t,
  gt_bus_ei_bupa_roles         TYPE bus_ei_bupa_roles_t,
  gt_bus_ei_bupa_telephone     TYPE bus_ei_bupa_telephone_t,
  gt_bus_ei_bupa_addressremark TYPE bus_ei_bupa_addressremark_t,
  gt_return                    TYPE bapiretm,
  v_error                      TYPE abap_bool,
  lv_msg                       TYPE string.


CONSTANTS :
  gv_msg_e(1) TYPE c VALUE 'E',
  gv_msg_s(1) TYPE c VALUE 'S',
  c_true      TYPE abap_bool VALUE 'X',
  task        TYPE bus_ei_object_task VALUE 'I'.

IMPORT gt_stp TO gt_stp FROM MEMORY ID 'table'.

START-OF-SELECTION.


  LOOP AT gt_stp INTO gs_stp.

    TRY.
        DATA(lv_uuid) = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ).
      CATCH cx_uuid_error INTO DATA(e_uuid). " Error Class for UUID Processing Errors
        MESSAGE : e_uuid->get_text( ) TYPE gv_msg_e DISPLAY LIKE gv_msg_e.
    ENDTRY.

    gs_cvis_data-partner-header-object_task = task.
    gs_cvis_data-partner-header-object_instance-bpartnerguid = lv_uuid.

    gs_cvis_data-partner-central_data-common-data-bp_control-grouping = 'ZS04'.
    gs_cvis_data-partner-central_data-common-data-bp_control-category = '2'.
    gs_cvis_data-partner-central_data-common-data-bp_centraldata-title_key = '0003'.
    gs_cvis_data-partner-central_data-common-data-bp_organization-name1 = gs_stp-org_name.
    gs_cvis_data-partner-central_data-common-datax-bp_organization-name1 = c_true.


    APPEND INITIAL LINE TO gt_bus_ei_addr ASSIGNING FIELD-SYMBOL(<fs_bus_ei_addr>).
    <fs_bus_ei_addr>-task = task.
    <fs_bus_ei_addr>-data-postal-data-city = gs_stp-city.
    <fs_bus_ei_addr>-data-postal-data-district = gs_stp-district.
    <fs_bus_ei_addr>-data-postal-data-str_suppl1 = gs_stp-street2.
    <fs_bus_ei_addr>-data-postal-data-str_suppl2 = gs_stp-street3.
    <fs_bus_ei_addr>-data-postal-data-street = gs_stp-street1.
    <fs_bus_ei_addr>-data-postal-data-str_suppl3 = gs_stp-street4.
    <fs_bus_ei_addr>-data-postal-data-location = gs_stp-street5.
    <fs_bus_ei_addr>-data-postal-data-country = gs_stp-country.
    <fs_bus_ei_addr>-data-postal-data-region = gs_stp-state.
    <fs_bus_ei_addr>-data-postal-data-postl_cod1 = gs_stp-postalcode.
    <fs_bus_ei_addr>-data-postal-data-langu = gs_stp-lang.
    <fs_bus_ei_addr>-data-addr_dep_attr-data-location_3 = '0'.
*
    <fs_bus_ei_addr>-data-postal-datax-city = c_true.
    <fs_bus_ei_addr>-data-postal-datax-district = c_true.
    <fs_bus_ei_addr>-data-postal-datax-str_suppl1 = c_true.
    <fs_bus_ei_addr>-data-postal-datax-str_suppl2 = c_true.
    <fs_bus_ei_addr>-data-postal-datax-street = c_true.
    <fs_bus_ei_addr>-data-postal-datax-postl_cod1 = c_true.
    <fs_bus_ei_addr>-data-postal-datax-str_suppl3 = c_true.
    <fs_bus_ei_addr>-data-postal-datax-location = c_true.
    <fs_bus_ei_addr>-data-postal-datax-country = c_true.
    <fs_bus_ei_addr>-data-postal-datax-region = c_true.
    <fs_bus_ei_addr>-data-postal-datax-langu = c_true.
    <fs_bus_ei_addr>-data-addr_dep_attr-datax-location_3 = c_true.

    APPEND INITIAL LINE TO gt_bus_ei_bupa_telephone ASSIGNING FIELD-SYMBOL(<fs_bus_ei_bupa_telephone>).
    <fs_bus_ei_bupa_telephone>-contact-task = task.
    <fs_bus_ei_bupa_telephone>-contact-data-telephone = gs_stp-phone.
    <fs_bus_ei_bupa_telephone>-contact-datax-telephone = c_true.
    <fs_bus_ei_bupa_telephone>-contact-data-country = gs_stp-country.
    <fs_bus_ei_bupa_telephone>-contact-datax-country = c_true.
    <fs_bus_ei_bupa_telephone>-contact-data-r_3_user = '3'.
    <fs_bus_ei_bupa_telephone>-contact-datax-r_3_user = c_true.

    APPEND INITIAL LINE TO gt_bus_ei_smtp ASSIGNING FIELD-SYMBOL(<fs_bus_ei_smtp>).
    <fs_bus_ei_smtp>-contact-task = task.
    <fs_bus_ei_smtp>-contact-data-e_mail = gs_stp-email.
    <fs_bus_ei_smtp>-contact-datax-e_mail = c_true.

    APPEND INITIAL LINE TO gt_bus_ei_bupa_addressremark ASSIGNING FIELD-SYMBOL(<fs_bus_ei_bupa_addressremark>).
    <fs_bus_ei_bupa_addressremark>-task = task.
    <fs_bus_ei_bupa_addressremark>-data-langu = 'E'.
    <fs_bus_ei_bupa_addressremark>-data-adr_notes = 'remark'.
    <fs_bus_ei_bupa_addressremark>-datax-langu = c_true.
    <fs_bus_ei_bupa_addressremark>-datax-adr_notes = c_true.

    <fs_bus_ei_addr>-data-communication-phone-phone = gt_bus_ei_bupa_telephone.
    <fs_bus_ei_addr>-data-communication-smtp-smtp = gt_bus_ei_smtp.
    <fs_bus_ei_addr>-data-remark-remarks = gt_bus_ei_bupa_addressremark.

    gs_cvis_data-partner-central_data-address-addresses = gt_bus_ei_addr[].

    APPEND INITIAL LINE TO gt_bus_ei_bupa_roles ASSIGNING FIELD-SYMBOL(<fs_bus_ei_bupa_roles>).
    <fs_bus_ei_bupa_roles>-task = task.
    <fs_bus_ei_bupa_roles>-data_key = 'Z00000' .

    APPEND INITIAL LINE TO gt_bus_ei_bupa_roles ASSIGNING <fs_bus_ei_bupa_roles>.
    <fs_bus_ei_bupa_roles>-task = task.
    <fs_bus_ei_bupa_roles>-data_key = 'ZUKM00' .

    APPEND INITIAL LINE TO gt_bus_ei_bupa_roles ASSIGNING <fs_bus_ei_bupa_roles>.
    <fs_bus_ei_bupa_roles>-task = task.
    <fs_bus_ei_bupa_roles>-data_key = 'ZFLCU0' .

    APPEND INITIAL LINE TO gt_bus_ei_bupa_roles ASSIGNING <fs_bus_ei_bupa_roles>.
    <fs_bus_ei_bupa_roles>-task = task.
    <fs_bus_ei_bupa_roles>-data_key = 'ZFLCU1' .

    gs_cvis_data-partner-central_data-role-roles = gt_bus_ei_bupa_roles[].


    APPEND INITIAL LINE TO gt_bus_ei_tax ASSIGNING FIELD-SYMBOL(<fs_bus_ei_tax>).
    <fs_bus_ei_tax>-task = task.
    <fs_bus_ei_tax>-data_key-taxtype = 'IN3'.
    <fs_bus_ei_tax>-data_key-taxnumxl = gs_stp-gstn.

    gs_cvis_data-partner-central_data-taxnumber-taxnumbers = gt_bus_ei_tax[].

  ENDLOOP.
  NEW cl_md_bp_maintain( )->validate_single(
    EXPORTING
      i_data           = gs_cvis_data
      iv_test_run_mode = 'X'  " Boolean Variable (X=True, Space=False)
    IMPORTING
      et_return_map    = DATA(gt_et_return)
  ).

  IF line_exists( gt_et_return[ type = 'E' ] ) OR line_exists( gt_et_return[ type = 'A' ] ).
    LOOP AT gt_et_return INTO DATA(gs_et_return).
      lv_msg = gs_et_return-message.
    ENDLOOP.
    EXIT.
  ENDIF.

  APPEND gs_cvis_data TO gt_cvis_data[].

  NEW cl_md_bp_maintain( )->maintain(
  EXPORTING
    i_data     = gt_cvis_data[]  " Inbound for Customer/Vendor Integration
  IMPORTING
    e_return   = gt_return       " BAPIRETI Table Type for Multiple Objects
  ).

  LOOP AT gt_return INTO DATA(gs_return).
    LOOP AT gs_return-object_msg INTO DATA(gs_msg).
      IF gs_msg-type = 'E' OR gs_msg-type = 'A'.
        v_error = abap_true.
      ENDIF.
      IF gs_msg-type = 'S'.
        lv_msg = gs_msg-message.
      ENDIF.
    ENDLOOP.
  ENDLOOP.

  IF v_error IS INITIAL.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
    SELECT FROM but000
      FIELDS partner
      WHERE name_org1 EQ @gs_stp-org_name
      INTO @DATA(lv_partner).
    ENDSELECT.
    INCLUDE zdoc_upload.
    lv_msg = |Ship-To-Party { lv_partner } has been created for { gs_stp-org_name }.|.
    EXPORT lv_msg = lv_msg TO MEMORY ID 'lv_msg'.

  ENDIF.
