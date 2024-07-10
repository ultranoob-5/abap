REPORT zcustomer.

TYPES: BEGIN OF ts_cust,
         org_name          TYPE c LENGTH 40,   " Organization Name
         street1           TYPE c LENGTH 60,   " Street Address Line 1
         street2           TYPE c LENGTH 60,   " Street Address Line 2
         street3           TYPE c LENGTH 40,   " Street Address Line 3
         street4           TYPE c LENGTH 40,   " Street Address Line 4
         street5           TYPE c LENGTH 40,   " Street Address Line 5
         city              TYPE c LENGTH 40,   " City
         district          TYPE c LENGTH 40,   " District
         state             TYPE n LENGTH 2,    " State Code
         postalcode        TYPE c LENGTH 40,   " Postal Code
         country           TYPE c LENGTH 2,    " Country Code
         gstn              TYPE c LENGTH 15,   " GST Number
         phone             TYPE n LENGTH 10,   " Phone Number
         email             TYPE c LENGTH 60,   " Email Address
         lang              TYPE c LENGTH 2,    " Language
         search1           TYPE c LENGTH 20,   " Search Term 1
         search2           TYPE c LENGTH 20,   " Search Term 2
         contactp          TYPE c LENGTH 40,   " Contact Person
         bifsc             TYPE c LENGTH 11,   " Bank IFSC Code
         baccno            TYPE c LENGTH 40,   " Bank Account Number
         taxtype           TYPE c LENGTH 5,    " Tax Type
         taxnum            TYPE c LENGTH 40,   " Tax Number
         idtype            TYPE c LENGTH 5,    " Identification Type
         idno              TYPE c LENGTH 40,   " Identification Number
         salesorg          TYPE c LENGTH 10,   " Sales Organization
         dischannel        TYPE c LENGTH 10,   " Distribution Channel
         division          TYPE c LENGTH 10,   " Division
         salesdis          TYPE c LENGTH 10,   " Sales District
         cusgrp            TYPE c LENGTH 10,   " Customer Group
         salesoffice       TYPE c LENGTH 10,   " Sales Office
         salesgrp          TYPE c LENGTH 10,   " Sales Group
         ordprobability    TYPE c LENGTH 10,   " Order Probability
         currency          TYPE c LENGTH 10,   " Currency
         priprocedure      TYPE c LENGTH 10,   " Pricing Procedure
         shipcondition     TYPE c LENGTH 10,   " Shipping Conditions
         incoterm1         TYPE c LENGTH 10,   " Incoterms 1
         incotermloc1      TYPE c LENGTH 10,   " Incoterms Location 1
         salespaymentterm  TYPE c LENGTH 10,   " Sales Payment Terms
         cuspricegrp       TYPE c LENGTH 10,   " Customer Price Group
         partnerfun        TYPE c LENGTH 20,   " Partner Function
         partnerfunno      TYPE c LENGTH 10,   " Partner Function Number
         companycode       TYPE c LENGTH 10,   " Company Code
         Reconciliationacc TYPE c LENGTH 10,   " Reconciliation Account
         comppaymentterm   TYPE c LENGTH 10,   " Company Payment Terms
         panno             TYPE c LENGTH 15,   " PAN Number
         panname           TYPE c LENGTH 40,   " PAN Name
         credit_sgmnt      TYPE c LENGTH 10,   " Credit Segment
         risk_class        TYPE c LENGTH 10,   " Risk Class
         check_rule        TYPE c LENGTH 10,   " Check Rule
         credit_group      TYPE c LENGTH 10,   " Credit Group
         limit_rule        TYPE c LENGTH 10,   " Limit Rule
         credit_limit      TYPE c LENGTH 10,   " Credit Limit
         pan               TYPE string,         " PAN (additional field)
         aadhar            TYPE string,         " Aadhar Number (additional field)
         gst               TYPE string,         " GST (additional field)
         fssai             TYPE string,         " FSSAI Number (additional field)
         tds               TYPE string,         " TDS (additional field)
         cheque            TYPE string,         " Cheque (additional field)
         tan               TYPE string,         " TAN (additional field)
         lv_pan_ftype      TYPE saeobjart,     " PAN File Type
         lv_aadhar_ftype   TYPE saeobjart,     " Aadhar File Type
         lv_gst_ftype      TYPE saeobjart,     " GST File Type
         lv_fssai_ftype    TYPE saeobjart,     " FSSAI File Type
         lv_tds_ftype      TYPE saeobjart,     " TDS File Type
         lv_cheque_ftype   TYPE saeobjart,     " Cheque File Type
         lv_tan_ftype      TYPE saeobjart,     " TAN File Type
         lv_pan_fname      TYPE c LENGTH 255,  " PAN File Name
         lv_aadhar_fname   TYPE c LENGTH 255,  " Aadhar File Name
         lv_gst_fname      TYPE c LENGTH 255,  " GST File Name
         lv_fssai_fname    TYPE c LENGTH 255,  " FSSAI File Name
         lv_tds_fname      TYPE c LENGTH 255,  " TDS File Name
         lv_cheque_fname   TYPE c LENGTH 255,  " Cheque File Name
         lv_tan_fname      TYPE c LENGTH 255,  " TAN File Name
       END OF ts_cust.

DATA: gt_cust          TYPE TABLE OF ts_cust,      " Internal table for customer data
      gs_cust          TYPE ts_cust,              " Work area for customer data
      gt_cvis_data     TYPE cvis_ei_extern_t,     " External data for CVIS
      gs_cvis_data     TYPE cvis_ei_extern,       " External data for CVIS
      gt_return        TYPE bapiretm,             " BAPI return table
      v_error          TYPE abap_bool,            " Error indicator
      io_facade        TYPE REF TO cl_ukm_facade, " UKM Facade object
      io_partner       TYPE REF TO cl_ukm_business_partner, " UKM Business Partner object
      io_bupa_factory  TYPE REF TO cl_ukm_bupa_factory,     " UKM Business Partner Factory object
      io_account       TYPE REF TO cl_ukm_account,           " UKM Account object
      lw_bp_credit_sgm TYPE ukm_s_bp_cms_sgm,       " UKM Credit Segment structure
      lwa_ukm_s_bp_cms TYPE ukm_s_bp_cms,           " UKM Business Partner structure
      l_partner        TYPE bu_partner,             " Business Partner GUID
      lv_credit_sgmnt  TYPE ukm_credit_sgmnt,       " UKM Credit Segment
      lv_msg           TYPE string,                 " Message string
      c_reconciliationacc TYPE c LENGTH 10.         " Reconciliation Account constant

CONSTANTS: gv_msg_e(1) TYPE c VALUE 'E',   " Error message type
           gv_msg_s(1) TYPE c VALUE 'S',   " Success message type
           c_true      TYPE abap_bool VALUE 'X',   " True constant
           task        TYPE bus_ei_object_task VALUE 'I'.  " Object task constant

IMPORT lt_cust TO gt_cust FROM MEMORY ID 'CUSTOMER'.  " Import customer data from memory

START-OF-SELECTION.

  LOOP AT gt_cust INTO gs_cust.  " Loop through customer data

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'  " Convert reconciliation account
      EXPORTING
        input  = gs_cust-reconciliationacc
      IMPORTING
        output = c_reconciliationacc.

    TRY.
        DATA(lv_uuid) = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ).  " Generate UUID
      CATCH cx_uuid_error INTO DATA(e_uuid).
        " Error handling for UUID generation
        MESSAGE e_uuid->get_text( ) TYPE gv_msg_e DISPLAY LIKE gv_msg_e.
    ENDTRY.

    " Construct CVIS data for business partner
    gs_cvis_data = VALUE #(
      partner-header-object_task = task
      partner-header-object_instance = VALUE #( bpartner = '' bpartnerguid = lv_uuid )
      partner-central_data-common-data = VALUE #(
        bp_control = VALUE #( category = '2' grouping = 'ZS01' )  " Business partner category and grouping
        bp_centraldata = VALUE #( searchterm1 = gs_cust-search1 searchterm2 = gs_cust-search2 title_key = '0003' )  " Search terms and title
        bp_organization = VALUE #( name1 = gs_cust-org_name )  " Organization name
      )
      partner-central_data-role-roles = VALUE #( task = task
                                                ( data_key = 'Z00000' )   " Roles: Customer roles
                                                ( data_key = 'ZUKM00' )   " UKM roles
                                                ( data_key = 'ZFLCU0' )   " Financial roles
                                                ( data_key = 'ZFLCU1' ) ) " More financial roles

    " Construct address data for business partner
    partner-central_data-address = VALUE #( addresses = VALUE #( ( task = task
                                                                  data = VALUE #( postal-data = VALUE #(
                                                                                    street = gs_cust-street1          " Street Address Line 1
                                                                                    str_suppl1 = gs_cust-street2      " Street Address Line 2
                                                                                    str_suppl2 = gs_cust-street3      " Street Address Line 3
                                                                                    str_suppl3 = gs_cust-street4      " Street Address Line 4
                                                                                    location = gs_cust-street5        " Street Address Line 5
                                                                                    city = gs_cust-city               " City
                                                                                    district = gs_cust-district       " District
                                                                                    region = gs_cust-state            " State Code
                                                                                    country = gs_cust-country         " Country Code
                                                                                    postl_cod1 = gs_cust-postalcode   " Postal Code
                                                                                    langu = gs_cust-lang )            " Language
                                                                  remark-remarks = VALUE #( ( task = task
                                                                                              data = VALUE #( adr_notes = gs_cust-contactp  "contact person
                                                                                                              langu = 'E' ) ) )
                                                                  communication-phone-phone = VALUE #( ( contact = VALUE #( task = task
                                                                                                                            data = VALUE #( telephone = gs_cust-phone "mobile number
                                                                                                                                            country = gs_cust-country r_3_user = '3' ) ) ) )
                                                                  communication-smtp-smtp = VALUE #( ( contact = VALUE #( task = task
                                                                                                                          data = VALUE #( e_mail = gs_cust-email ) ) ) ) ) ) ) ) "email

    " Construct bank details for business partner
    partner-central_data-bankdetail-bankdetails = VALUE #( ( task = task
                                                             data = VALUE #( bank_ctry = gs_cust-country       " Bank Country
                                                                             bank_key = gs_cust-bifsc          " Bank IFSC Code
                                                                             bank_acct = gs_cust-baccno ) ) )  " Bank Account Number

    " Construct tax numbers for business partner
    partner-central_data-taxnumber-taxnumbers = VALUE #( ( task = task
                                                           data_key = VALUE #( taxtype = gs_cust-taxtype       " Tax Type
                                                                               taxnumxl = gs_cust-taxnum ) ) ) " Tax Number

    " Construct identification numbers for business partner
    partner-central_data-ident_number-ident_numbers = VALUE #( ( task = task
                                                                 data_key = VALUE #( identificationcategory = gs_cust-idtype   " Identification Type
                                                                                     identificationnumber = gs_cust-idno ) ) ) " Identification Number

    " Construct sales data for business partner
    customer-header-object_task = task
    customer-sales_data-sales = VALUE #( ( task = task
                                           data_key = VALUE #( vkorg = gs_cust-salesorg     " Sales Organization
                                                               vtweg = gs_cust-dischannel   " Distribution Channel
                                                               spart = gs_cust-division )   " Division

                                           data = VALUE #( bzirk = gs_cust-salesdis         " Sales District
                                                           kdgrp = gs_cust-cusgrp           " Customer Group
                                                           vkbur = gs_cust-salesoffice      " Sales Office
                                                           vkgrp = gs_cust-salesgrp         " Sales Group
                                                           awahr = gs_cust-ordprobability   " Order Probability
                                                           waers = gs_cust-currency         " Currency
                                                           kalks = gs_cust-priprocedure     " Pricing Procedure
                                                           vsbed = gs_cust-shipcondition    " Shipping Conditions
                                                           inco1 = gs_cust-incoterm1        " Incoterms 1
                                                           inco2_l = gs_cust-incotermloc1   " Incoterms Location 1
                                                           zterm = gs_cust-salespaymentterm " Sales Payment Terms
                                                           konda = gs_cust-cuspricegrp )    " Customer Price Group

                                           functions-functions = VALUE #( ( data_key-parvw = gs_cust-partnerfun          " Partner Function
                                                                            data-partner  = gs_cust-partnerfunno ) ) ) ) " Partner Function Number

    " Construct company data for business partner
    customer-company_data-company = VALUE #( ( task = task
                                               data_key = VALUE #( bukrs = gs_cust-companycode )     " Company Code
                                               data = VALUE #( akont = c_reconciliationacc           " Reconciliation Account
                                                               zterm = gs_cust-comppaymentterm ) ) ) " Company Payment Terms

    " Construct PAN details for business partner
    customer-central_data-central = VALUE #( data = VALUE #( j_1ipanno = gs_cust-panno        " PAN Number
                                                             j_1ipanref = gs_cust-panname ) ) " PAN Name
    ).

    " Validate the CVIS data
    NEW cl_md_bp_maintain( )->validate_single(
      EXPORTING
        i_data        = gs_cvis_data
      IMPORTING
        et_return_map = DATA(gt_et_return)
    ).

    " Check for validation errors
    IF line_exists( gt_et_return[ type = 'E' ] ) OR line_exists( gt_et_return[ type = 'A' ] ).
      LOOP AT gt_et_return INTO DATA(gs_et_return).
        lv_msg = gs_et_return-message.
      ENDLOOP.
      EXIT.
    ENDIF.

    " Append valid CVIS data to external data table
    APPEND gs_cvis_data TO gt_cvis_data[].

    " Perform business partner maintenance
    NEW cl_md_bp_maintain( )->maintain(
      EXPORTING
        i_data   = gt_cvis_data[]
      IMPORTING
        e_return = gt_return
    ).

    " Check for errors in return messages
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

    " If no errors occurred, proceed with further processing
    IF v_error IS INITIAL.

      " Commit the transaction
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.

      " Retrieve the Business Partner GUID
      SELECT FROM but000
        FIELDS partner
        WHERE partner_guid = @lv_uuid
        ORDER BY PRIMARY KEY
        INTO @DATA(lv_partner).
      ENDSELECT.

      " Initialize UKM facade and objects
      io_facade = cl_ukm_facade=>create( i_activity = cl_ukm_cnst_eventing=>bp_maintenance ).
      io_bupa_factory = io_facade->get_bupa_factory( ).

      " Retrieve and set credit management data
      l_partner = lv_partner.
      lv_credit_sgmnt = gs_cust-credit_sgmnt.
      io_partner = io_bupa_factory->get_business_partner( l_partner ).
      io_partner->get_bp_cms( IMPORTING es_bp_cms = lwa_ukm_s_bp_cms ).
      lwa_ukm_s_bp_cms = VALUE #( risk_class = gs_cust-risk_class
                                  check_rule = gs_cust-check_rule
                                  credit_group = gs_cust-credit_group
                                  limit_rule = gs_cust-limit_rule ).
      io_partner->set_bp_cms( lwa_ukm_s_bp_cms ).

      " Retrieve and set credit account data
      CALL METHOD io_bupa_factory->get_credit_account
        EXPORTING
          i_partner         = l_partner
          i_credit_sgmnt    = lv_credit_sgmnt
        RECEIVING
          ro_credit_account = io_account.

      io_account->get_bp_cms_sgm( IMPORTING es_bp_cms_sgm = lw_bp_credit_sgm ).
      lw_bp_credit_sgm-credit_limit = gs_cust-credit_limit.
      io_account->set_bp_cms_sgm( EXPORTING is_bp_cms_sgm = lw_bp_credit_sgm ).

      " Save all changes to business partner data
      io_bupa_factory->save_all( ).

      " Commit the transaction
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.

      " Include additional document upload logic
      INCLUDE zcust_doc_upload.

      " Query and display UKM CMS data for verification
      WITH
      +cms AS (
        SELECT FROM ukmbp_cms
          FIELDS ukmbp_cms~partner,
                 check_rule,
                 risk_class
          WHERE partner EQ @lv_partner ),
      +cms_sgm AS (
        SELECT FROM ukmbp_cms_sgm
          FIELDS ukmbp_cms_sgm~partner,
                 credit_sgmnt,
                 credit_limit
          WHERE partner EQ @lv_partner ),
      +output( partner, c_rule, r_class, credit_st, credit_lmt ) AS (
        SELECT a~partner, a~check_rule, a~risk_class, b~credit_sgmnt, b~credit_limit
          FROM +cms AS a
          INNER JOIN +cms_sgm AS b ON a~partner = b~partner )
      SELECT * FROM +output
        ORDER BY partner
        INTO TABLE @DATA(gt_ukm_cms_sgm).

      " Check if UKM CMS data is retrieved successfully
      IF gt_ukm_cms_sgm[] IS NOT INITIAL.
        lv_msg =  text-001 && ` ` && lv_partner && text-002 && ` ` && gs_cust-org_name.
      ELSE.
        " Rollback the transaction if UKM CMS data is not found
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      ENDIF.

    ENDIF. " End of error check

  ENDLOOP. " End of customer data loop

  " Export final message to memory for display or further processing
  EXPORT lv_msg = lv_msg TO MEMORY ID 'CUST_MSG'.
