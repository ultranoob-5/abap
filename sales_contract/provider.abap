METHOD if_rest_resource~post.

  TYPES: BEGIN OF gty_sc_desc,
           SerialNo                TYPE int8,       " Serial number of the sales contract
           SalesDocumentType       TYPE auart,      " Sales document type
           SalesOrganization       TYPE vkorg,      " Sales organization
           DistributionChannel     TYPE vtweg,      " Distribution channel
           Division                TYPE spart,      " Division
           SalesOffice             TYPE vkbur,      " Sales office
           SalesGroup              TYPE vkgrp,      " Sales group
           ContractStartDate       TYPE guebg,      " Start of validity period
           ContractEndDate         TYPE gueen,      " End of validity period
           Currency                TYPE waers,      " Currency
           CustomerReferenceNumber TYPE ebeln,      " Purchase order number
           CustomerReferenceDate   TYPE aedat,      " Document date
           SalesDocumentNumber     TYPE vbeln,      " Sales document number
           Incoterms               TYPE inco1,      " Incoterms (Part 1)
           IncotermsLocation       TYPE inco2_l,    " Incoterms (Part 2)
           PaymentTerms            TYPE dzterm,     " Payment terms
           PartnerFunction         TYPE parvw,      " Partner function
           CustomerNumber          TYPE kunnr,      " Customer number
           ItemNumber              TYPE posnr,      " Item number
           MaterialNumber          TYPE matnr,      " Material number
           Quantity                TYPE kwmeng,     " Target quantity
           Plant                   TYPE werks_d,    " Plant
           ConditionType           TYPE kschl,      " Condition type
           ConditionValue          TYPE vfprc_element_value, " Condition value
           Remarks                 TYPE string,
           ShipFromDate            TYPE datum,
           ShipToDate              TYPE datum,
           VesselName              TYPE string,
           DutyCondition           TYPE string,
           DeliveryFromDate        TYPE datum,
           DeliveryToDate          TYPE datum,
           Origin                  TYPE string,
         END OF gty_sc_desc,

         BEGIN OF gty_sc,
           sr_no            TYPE int8,       " Serial number of the sales contract
           auart            TYPE auart,      " Sales document type
           vkorg            TYPE vkorg,      " Sales organization
           vtweg            TYPE vtweg,      " Distribution channel
           spart            TYPE spart,      " Division
           vkbur            TYPE vkbur,      " Sales office
           vkgrp            TYPE vkgrp,      " Sales group
           guebg            TYPE guebg,      " Start of validity period
           gueen            TYPE gueen,      " End of validity period
           waers            TYPE waers,      " Currency
           ebeln            TYPE ebeln,      " Purchase order number
           aedat            TYPE aedat,      " Document date
           vbeln            TYPE vbeln,      " Sales document number
           inco1            TYPE inco1,      " Incoterms (Part 1)
           inco2_l          TYPE inco2_l,    " Incoterms (Part 2)
           zterm            TYPE dzterm,     " Payment terms
           parvw            TYPE parvw,      " Partner function
           kunnr            TYPE kunnr,      " Customer number
           posnr            TYPE posnr,      " Item number
           matnr            TYPE matnr,      " Material number
           kwmeng           TYPE kwmeng,     " Target quantity
           werks            TYPE werks_d,    " Plant
           kschl            TYPE kschl,      " Condition type
           kwert            TYPE vfprc_element_value, " Condition value
           Remarks          TYPE string,
           ShipFromDate     TYPE datum,
           ShipToDate       TYPE datum,
           VesselName       TYPE string,
           DutyCondition    TYPE string,
           DeliveryFromDate TYPE datum,
           DeliveryToDate   TYPE datum,
           Origin           TYPE string,
         END OF gty_sc,

         BEGIN OF gty_log,
           vbeln TYPE char20,    " Sales document number for logging
           msgs  TYPE string,    " Log messages
         END OF gty_log.

  " Define internal tables and work structures for processing
  DATA: gt_sc      TYPE TABLE OF gty_sc,      " Table to store sales contract data
        gt_sc_desc TYPE TABLE OF gty_sc_desc,      " Table to store sales contract data
        gt_log     TYPE TABLE OF gty_log.     " Table to store logs

  " Retrieve the entity data from the request
  DATA(lo_entity) = mo_request->get_entity( ).
  DATA(lt_sc_raw) = lo_entity->get_string_data( ).

  " Deserialize the incoming JSON data into internal table GT_SC
  /ui2/cl_json=>deserialize(
  EXPORTING
    json  = lt_sc_raw
  CHANGING
  data  = gt_sc_desc
  ).

  gt_sc = gt_sc_desc.

  EXPORT gt_sc = gt_sc TO MEMORY ID 'SALESCONTRACT'.

  SUBMIT zsales_contract EXPORTING LIST TO MEMORY AND RETURN.

  IMPORT gt_log TO gt_log FROM MEMORY ID 'SALESCONTRACTMSG'.
  /ui2/cl_json=>serialize(
    EXPORTING
      data  = gt_log
    RECEIVING
      r_json = DATA(lv_json)
  ).

  mo_response->create_entity( )->set_string_data( iv_data = lv_json ).

ENDMETHOD.
