CLASS zzcl_rfico001 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
    METHODS get_data
      IMPORTING io_request  TYPE REF TO if_rap_query_request
                io_response TYPE REF TO if_rap_query_response
      RAISING   cx_rap_query_prov_not_impl
                cx_rap_query_provider.
    METHODS set_data_return
      IMPORTING io_request  TYPE REF TO if_rap_query_request
                io_response TYPE REF TO if_rap_query_response
      CHANGING  it_data     TYPE ANY TABLE
      RAISING   cx_rap_query_prov_not_impl
                cx_rap_query_provider.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZZCL_RFICO001 IMPLEMENTATION.


  METHOD get_data.
    DATA: lt_result TYPE TABLE OF zc_rfico001,
          ls_result TYPE zc_rfico001.
    DATA:
      rt_fiscalyear         TYPE RANGE OF zc_rfico001-fiscalyear,
      rt_fiscalperiod       TYPE RANGE OF zc_rfico001-fiscalperiod,
      rt_companycode        TYPE RANGE OF zc_rfico001-companycode,
      rt_glaccount          TYPE RANGE OF zc_rfico001-glaccount,
      rt_product            TYPE RANGE OF zc_rfico001-product,
      rt_postingdate        TYPE RANGE OF zc_rfico001-postingdate,
      rt_accountingdocument TYPE RANGE OF zc_rfico001-accountingdocument,
      rt_ledgergllineitem   TYPE RANGE OF zc_rfico001-ledgergllineitem.
    TRY.
        DATA(lo_filter) = io_request->get_filter(  ).     "CDS VIEW ENTITY 选择屏幕过滤器
        DATA(lt_filters) = lo_filter->get_as_ranges(  ).  "ABAP range
*       过滤器
        LOOP AT lt_filters INTO DATA(ls_filter).
          TRANSLATE ls_filter-name TO UPPER CASE.
          CASE ls_filter-name.
            WHEN 'FISCALYEAR'.
              rt_fiscalyear = CORRESPONDING #( ls_filter-range ).
            WHEN 'FISCALPERIOD'.
              rt_fiscalperiod = CORRESPONDING #( ls_filter-range ).
            WHEN 'COMPANYCODE'.
              rt_companycode = CORRESPONDING #( ls_filter-range ).
            WHEN 'GLACCOUNT'.
              rt_glaccount = CORRESPONDING #( ls_filter-range ).
            WHEN 'PRODUCT'.
              rt_product = CORRESPONDING #( ls_filter-range ).
            WHEN 'POSTINGDATE'.
              rt_postingdate = CORRESPONDING #( ls_filter-range ).
            WHEN 'ACCOUNTINGDOCUMENT'.
              rt_accountingdocument = CORRESPONDING #( ls_filter-range ).
            WHEN 'LEDGERGLLINEITEM'.
              rt_ledgergllineitem = CORRESPONDING #( ls_filter-range ).
          ENDCASE.
        ENDLOOP.
        SELECT a~fiscalyear,
               a~fiscalperiod,
               a~companycode,
               b~companycodename,
               a~accountingdocument,
               a~ledgergllineitem,
               a~accountingdoccreatedbyuser,
               a~glaccount,
               c~glaccountlongname,
               a~amountincompanycodecurrency,
               a~companycodecurrency,
               a~product,
               d~productname,
               a~supplier,
               e~suppliername,
               a~customer,
               f~customername,
               a~taxcode,
               a~postingdate,
               a~profitcenter,
               f1~profitcentername,
               a~referencedocument,
               a~quantity,
               a~baseunit AS saleunit,
               a~purchasingdocument,
               a~salesdocument,
               g~baseunit,
               h~alternativeunit,
               h~quantitynumerator,
               h~quantitydenominator
          FROM i_journalentryitem WITH PRIVILEGED ACCESS AS a
          INNER JOIN i_companycode WITH PRIVILEGED ACCESS AS b
            ON a~companycode = b~companycode
          LEFT OUTER JOIN i_glaccounttext WITH PRIVILEGED ACCESS AS c
            ON a~glaccount = c~glaccount AND c~language = @sy-langu
          LEFT OUTER JOIN i_producttext WITH PRIVILEGED ACCESS AS d
            ON a~product = d~product AND d~language = @sy-langu
          LEFT OUTER JOIN i_supplier WITH PRIVILEGED ACCESS AS e
            ON a~supplier = e~supplier
          LEFT OUTER JOIN i_customer WITH PRIVILEGED ACCESS AS f
            ON a~customer = f~customer
          LEFT OUTER JOIN i_profitcentertext WITH PRIVILEGED ACCESS AS f1
            ON a~profitcenter = f1~profitcenter AND f1~language = @sy-langu
          LEFT OUTER JOIN i_product WITH PRIVILEGED ACCESS AS g
            ON a~product = g~product
          LEFT OUTER JOIN i_productunitsofmeasure WITH PRIVILEGED ACCESS AS h
            ON a~product = h~product AND a~baseunit = h~alternativeunit
         WHERE a~fiscalyear IN @rt_fiscalyear
           AND a~fiscalperiod IN @rt_fiscalperiod
           AND a~companycode IN @rt_companycode
           AND a~glaccount IN @rt_glaccount
           AND ( a~glaccount LIKE '6001%' OR a~glaccount LIKE '6051%' OR a~glaccount LIKE '6402%' OR a~glaccount LIKE '6401%' )
           AND a~product IN @rt_product
           AND a~postingdate IN @rt_postingdate
           AND a~accountingdocument IN @rt_accountingdocument
           AND a~ledgergllineitem IN @rt_ledgergllineitem
           INTO CORRESPONDING FIELDS OF TABLE @lt_result.

        SELECT *
          FROM i_unitofmeasure WITH PRIVILEGED ACCESS
          INTO TABLE @DATA(lt_unitofmeasure).
        SORT lt_unitofmeasure BY unitofmeasure.
        LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_result>).
          IF <fs_result>-saleunit IS NOT INITIAL AND <fs_result>-quantitydenominator NE 0.
            <fs_result>-quantityinbaseunit = <fs_result>-quantity * ( <fs_result>-quantitynumerator / <fs_result>-quantitydenominator ).
          ENDIF.
          READ TABLE lt_unitofmeasure INTO DATA(ls_unitofmeasure) WITH KEY unitofmeasure = <fs_result>-saleunit BINARY SEARCH.
          IF sy-subrc = 0.
            <fs_result>-saleunitdesc = ls_unitofmeasure-unitofmeasure_e.
          ENDIF.
          READ TABLE lt_unitofmeasure INTO ls_unitofmeasure WITH KEY unitofmeasure = <fs_result>-baseunit BINARY SEARCH.
          IF sy-subrc = 0.
            <fs_result>-baseunitdesc = ls_unitofmeasure-unitofmeasure_e.
          ENDIF.
        ENDLOOP.

        set_data_return( EXPORTING io_request = io_request
                                   io_response = io_response
                         CHANGING  it_data = lt_result  ).
      CATCH cx_rap_query_filter_no_range.
        RETURN.
    ENDTRY.
  ENDMETHOD.


  METHOD if_rap_query_provider~select.
    CASE io_request->get_entity_id( ).

      WHEN 'ZC_RFICO001'.
        get_data( EXPORTING io_request      = io_request
                            io_response     = io_response ).
      WHEN OTHERS.

    ENDCASE.
  ENDMETHOD.


  METHOD set_data_return.
*&---====================2.数据获取后，select 排序/过滤/分页/返回设置
*&---设置过滤器
    zzcl_query_utils=>filtering( EXPORTING io_filter = io_request->get_filter(  ) CHANGING ct_data = it_data ).
*&---设置记录总数
    IF io_request->is_total_numb_of_rec_requested(  ) .
      io_response->set_total_number_of_records( lines( it_data ) ).
    ENDIF.
*&---设置排序
    zzcl_query_utils=>orderby( EXPORTING it_order = io_request->get_sort_elements( )  CHANGING ct_data = it_data ).
*&---设置按页查询
    zzcl_query_utils=>paging( EXPORTING io_paging = io_request->get_paging(  ) CHANGING ct_data = it_data ).
*&---返回数据
    io_response->set_data( it_data ).
  ENDMETHOD.
ENDCLASS.
