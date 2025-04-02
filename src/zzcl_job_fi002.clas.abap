CLASS zzcl_job_fi002 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_apj_dt_exec_object .
    INTERFACES if_apj_rt_exec_object .
    INTERFACES if_oo_adt_classrun.
    CLASS-METHODS postcbs
      IMPORTING VALUE(i_wbbs) TYPE char1 OPTIONAL
      CHANGING  i_zztfi_0007  TYPE zztfi_0007.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZZCL_JOB_FI002 IMPLEMENTATION.


  METHOD if_apj_dt_exec_object~get_parameters.
    et_parameter_def = VALUE #(
      ( selname        = 'NUMBER'
        kind           = if_apj_dt_exec_object=>select_option
        datatype       = 'C'
        length         = 50
        param_text     = '交易流水号'
        changeable_ind = abap_true )

      ( selname        = 'PROCESS'
        kind           = if_apj_dt_exec_object=>parameter
        datatype       = 'C'
        length         = 1
        param_text     = 'JOB处理方式(1前台;2后台)'
        changeable_ind = abap_true
        mandatory_ind  = abap_true  )
       ).


  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.


    DATA:lv_stamp TYPE zztfi_0007-zztstmpl.
    DATA: lv_flag     TYPE bapi_mtype,
          lv_msg      TYPE bapi_msg,
          lv_text     TYPE char200,
          lv_severity TYPE c LENGTH 1.
    DATA:ls_request      TYPE zjournal_entry_bulk_create_req,
         lt_journalentry TYPE zjournal_entry_create_requ_tab,
         ls_journalentry TYPE zjournal_entry_create_request,
         ls_response     TYPE zjournal_entry_bulk_create_con.
    DATA:lt_gl TYPE TABLE OF zjournal_entry_create_request9,
         ls_gl TYPE zjournal_entry_create_request9.
    DATA:lt_debtor TYPE TABLE OF zjournal_entry_create_reques13,
         ls_debtor TYPE zjournal_entry_create_reques13.
    DATA:lv_dmbtr TYPE dmbtr.

    DATA:lt_md    TYPE TABLE OF zztfi_0007,
         ls_md    TYPE zztfi_0007,
         lt_mdall TYPE TABLE OF zztfi_0007.

    DATA:r_tmstmp  TYPE RANGE OF zztfi_0007-zztstmpl,
         lv_bstamp TYPE zztfi_0007-zztstmpl,
         lv_estamp TYPE zztfi_0007-zztstmpl.
    DATA:lv_process TYPE ze_job_proc.
    DATA:r_number TYPE RANGE OF zztfi_0007-transactionserialnumber.
    DATA:lv_count TYPE i.

    LOOP AT it_parameters INTO DATA(l_parameter).
      CASE l_parameter-selname.
        WHEN 'NUMBER'.
          APPEND VALUE #( sign   = l_parameter-sign
                          option = l_parameter-option
                          low    = l_parameter-low
                          high   = l_parameter-high  ) TO r_number.

        WHEN 'PROCESS'.
          lv_process = l_parameter-low.
      ENDCASE.
    ENDLOOP.

*    CASE lv_process.
*      WHEN '1'.
*        SELECT *
*          FROM zztfi_0007
*         WHERE transactionserialnumber IN @r_number
*           AND flag <> 'S'
*          INTO TABLE @DATA(lt_ztfi007).
*      WHEN '2'.
*        "没有参数，默认后台增量推送
*        lv_bstamp =  zzcl_comm_tool=>get_last_execute( 'FI003' ).
*        GET TIME STAMP FIELD lv_estamp.
*        APPEND  VALUE #( option = 'BT'
*                         sign   = 'I'
*                         low    = lv_bstamp
*                         high   = lv_estamp
*                    ) TO r_tmstmp.
*
*        SELECT *
*          FROM zztfi_0007
*         WHERE zztstmpl IN @r_tmstmp
*           AND transactionserialnumber IS NOT INITIAL
*          INTO TABLE @lt_ztfi007.
*    ENDCASE.

    SELECT *
      FROM zztfi_0007
     WHERE transactionserialnumber IN @r_number
       AND flag = ''
      INTO TABLE @DATA(lt_ztfi007).

    "管理货币
    SELECT *
      FROM zztfi_0002
     INTO TABLE @DATA(lt_zztfi_0002).
    SORT lt_zztfi_0002 BY zcurrency.
    "银行账号&开户行&开户行账户关系维护表
    SELECT *
      FROM zztfi_0001
     INTO TABLE @DATA(lt_zztfi_0001).
    SORT lt_zztfi_0001 BY bankn.
    "CBS配置表
    SELECT *
      FROM zztfi_0006
     INTO TABLE @DATA(lt_zztfi_0006).
    SORT lt_zztfi_0006 BY extend1 itemno.

    SORT lt_ztfi007 BY transactionserialnumber.
    "将FLAG标识更新为R，避免后续交叉处理
    LOOP AT lt_ztfi007 ASSIGNING FIELD-SYMBOL(<fs_ztfi007>).
      <fs_ztfi007>-flag = 'R'.
    ENDLOOP.
    MODIFY zztfi_0007 FROM TABLE @lt_ztfi007.
    COMMIT WORK AND WAIT.
    TRY.
        DATA(l_log) = cl_bali_log=>create_with_header(
             header = cl_bali_header_setter=>create( object = 'ZZ_ALO_API'
                                                     subobject = 'ZZ_ALO_API_SUB' ) ).
        IF lt_ztfi007[] IS INITIAL.
          l_log->add_item( item = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_information
                                                              text = '未获取到增量数据！' ) ).
          cl_bali_log_db=>get_instance( )->save_log_2nd_db_connection( log = l_log
                                                             assign_to_current_appl_job = abap_true ).
          RETURN.
        ENDIF.
        LOOP AT lt_ztfi007 ASSIGNING <fs_ztfi007>.
          lv_count = lv_count + 1.
          lv_text = |{ lv_count }.开始处理交易流水号【{ <fs_ztfi007>-transactionserialnumber }】|.
          l_log->add_item( item = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_status
                                                text = lv_text ) ).
          postcbs( CHANGING i_zztfi_0007 = <fs_ztfi007> ).
          IF <fs_ztfi007>-flag = 'E'.
            lv_text = |{ lv_count }.处理失败:【{ <fs_ztfi007>-msg }】|.
            l_log->add_item( item = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_error
                                                  text = lv_text ) ).
          ELSE.
            lv_text = |{ lv_count }.处理成功:【{ <fs_ztfi007>-msg }】|.
            l_log->add_item( item = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_status
                                                  text = lv_text ) ).
          ENDIF.
          lv_text = |{ lv_count }.结束处理交易流水号【{ <fs_ztfi007>-transactionserialnumber }】|.
          l_log->add_item( item = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_status
                                                text = lv_text ) ).
        ENDLOOP.
        cl_bali_log_db=>get_instance( )->save_log_2nd_db_connection( log = l_log
                                                   assign_to_current_appl_job = abap_true ).
      CATCH cx_bali_runtime.
        "handle exception
    ENDTRY.


  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.

    DATA  et_parameters TYPE if_apj_rt_exec_object=>tt_templ_val  .

    et_parameters = VALUE #(
        ( selname = 'TSTMPL'
          kind = if_apj_dt_exec_object=>parameter
          sign = 'I'
          option = 'EQ'
          low = '20241216021000.4605050' )
      ).
    TRY.
        if_apj_rt_exec_object~execute( it_parameters = et_parameters ).
      CATCH cx_root INTO DATA(job_scheduling_exception).
        DATA(lv_text) = job_scheduling_exception->get_longtext( ).
    ENDTRY.
  ENDMETHOD.


  METHOD postcbs.
    DATA: lv_bhs TYPE zztfi_0007-amountintransactioncurrency,
          lv_se  TYPE zztfi_0007-amountintransactioncurrency,
          lv_cid TYPE abp_behv_cid.
    DATA(lv_date) = cl_abap_context_info=>get_system_date( ).
    DATA(lv_time) = cl_abap_context_info=>get_system_time( ).
    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).
    i_zztfi_0007-updated_date = lv_date.
    i_zztfi_0007-updated_time = lv_time.
    i_zztfi_0007-updated_by = lv_user.
    "1.拉取配置表，填充zztfi_0007日志表数据
    SELECT SINGLE *
             FROM zztfi_0001 WITH PRIVILEGED ACCESS
            WHERE bankn = @i_zztfi_0007-accountno
             INTO @DATA(ls_zztfi_0001).
    IF sy-subrc = 0.
      i_zztfi_0007-companycode = ls_zztfi_0001-bukrs.
      i_zztfi_0007-housebank = ls_zztfi_0001-hbkid.
      i_zztfi_0007-housebankaccount = ls_zztfi_0001-hktid.
      i_zztfi_0007-profitcenter = ls_zztfi_0001-prctr.
    ELSE.
      i_zztfi_0007-flag = 'E'.
      i_zztfi_0007-msg = |银行账号【{ i_zztfi_0007-accountno }】在银行账号&开户行&开户行账户关系维护表未配置，请检查|.
      MODIFY zztfi_0007 FROM @i_zztfi_0007.
      IF i_wbbs IS INITIAL."前台调用标识
        COMMIT WORK AND WAIT.
      ENDIF.
      RETURN.
    ENDIF.
    SELECT SINGLE *
             FROM zztfi_0002 WITH PRIVILEGED ACCESS
            WHERE zcurrency = @i_zztfi_0007-currency
             INTO @DATA(ls_zztfi_0002).
    IF sy-subrc = 0.
      i_zztfi_0007-waers = ls_zztfi_0002-waers.
    ELSE.
      i_zztfi_0007-flag = 'E'.
      i_zztfi_0007-msg = |币种【{ i_zztfi_0007-currency }】在管理货币和银行科目维护表未配置，请检查|.
      MODIFY zztfi_0007 FROM @i_zztfi_0007.
      IF i_wbbs IS INITIAL."前台调用标识
        COMMIT WORK AND WAIT.
      ENDIF.
      RETURN.
    ENDIF.
    SELECT  *
      FROM zztfi_0006 WITH PRIVILEGED ACCESS
     WHERE extend1 = @i_zztfi_0007-extend1
      INTO TABLE @DATA(lt_zztfi_0006).
    IF sy-subrc NE 0.
      i_zztfi_0007-flag = 'E'.
      i_zztfi_0007-msg = |款项性质【{ i_zztfi_0007-extend1 }】在CBS收款凭证配置表未配置，请检查|.
      MODIFY zztfi_0007 FROM @i_zztfi_0007.
      IF i_wbbs IS INITIAL."前台调用标识
        COMMIT WORK AND WAIT.
      ENDIF.
      RETURN.
    ENDIF.
    i_zztfi_0007-accountingdocumenttype = 'C2'.
    i_zztfi_0007-documentheadertext = i_zztfi_0007-transactionserialnumber.
    i_zztfi_0007-documentdate = i_zztfi_0007-claimsuccesstime.
    i_zztfi_0007-postingdate = lv_date.
    i_zztfi_0007-transactioncurrency = i_zztfi_0007-waers.
    i_zztfi_0007-amountintransactioncurrency = i_zztfi_0007-claimamount.
    lv_bhs = i_zztfi_0007-amountintransactioncurrency / '1.13'.
    lv_se  = i_zztfi_0007-amountintransactioncurrency - lv_bhs.
    "2调用接口，创建会计凭证
    TRY.
        DATA(destination) = cl_soap_destination_provider=>create_by_comm_arrangement(
          comm_scenario  = 'ZZHTTP_INBOUND_API'
          service_id     = 'ZZ_OS_FI001_SPRX'
          comm_system_id = 'THIRD_TO_SAP'
        ).

        DATA(proxy) = NEW zco_journal_entry_create_reque( destination = destination ).

        " fill request
        DATA(request) = VALUE zjournal_entry_bulk_create_req( ).

        TRY.
            DATA(lv_zone) = cl_abap_context_info=>get_user_time_zone( ).
          CATCH cx_abap_context_info_error.
            "handle exception
        ENDTRY.
        CONVERT DATE lv_date TIME lv_time INTO TIME STAMP request-journal_entry_bulk_create_requ-message_header-creation_date_time TIME ZONE lv_zone.
        APPEND INITIAL LINE TO request-journal_entry_bulk_create_requ-journal_entry_create_request ASSIGNING FIELD-SYMBOL(<fs_request>).
        <fs_request>-message_header-creation_date_time = request-journal_entry_bulk_create_requ-message_header-creation_date_time.
        ASSIGN <fs_request>-journal_entry TO FIELD-SYMBOL(<fs_entry>).
        "抬头
        <fs_entry>-original_reference_document_ty = 'BKPFF'.
*        <fs_entry>-original_reference_document = i_zztfi_0007-pk_no.
        <fs_entry>-original_reference_document_lo = 'CBS'.
        <fs_entry>-business_transaction_type = 'RFBU'.
        <fs_entry>-accounting_document_type = 'C2'.
        <fs_entry>-document_header_text = i_zztfi_0007-documentheadertext.
        <fs_entry>-created_by_user = i_zztfi_0007-createbyname.
        <fs_entry>-company_code = i_zztfi_0007-companycode.
        <fs_entry>-document_date = i_zztfi_0007-documentdate.
        <fs_entry>-posting_date = i_zztfi_0007-postingdate.
        "行项目
        LOOP AT lt_zztfi_0006 INTO DATA(ls_zztfi_0006).
          CASE ls_zztfi_0006-koart.
            WHEN 'S'.
              APPEND INITIAL LINE TO <fs_entry>-item ASSIGNING FIELD-SYMBOL(<fs_item>).
              <fs_item>-reference_document_item = '1'.
              <fs_item>-glaccount-content = ls_zztfi_0006-glaccount.
              <fs_item>-debit_credit_code = ls_zztfi_0006-debitcreditcode.
              <fs_item>-account_assignment-profit_center = i_zztfi_0007-profitcenter.
              <fs_item>-amount_in_transaction_currency-currency_code = i_zztfi_0007-waers.
              IF ls_zztfi_0006-bhs_flag = 'X'.
                <fs_item>-amount_in_transaction_currency-content = lv_bhs.
              ELSEIF ls_zztfi_0006-se_flag = 'X'.
                <fs_item>-amount_in_transaction_currency-content = lv_se.
              ELSE.
                <fs_item>-amount_in_transaction_currency-content = i_zztfi_0007-claimamount.
              ENDIF.
              IF <fs_item>-debit_credit_code = 'H'.
                <fs_item>-amount_in_transaction_currency-content = abs( <fs_item>-amount_in_transaction_currency-content  ) * -1.
              ENDIF.
*              <fs_item>-amount_in_group_currency-content = ls_zztfi_0006-amountingroupcurrency.
*              <fs_item>-amount_in_group_currency-currency_code = 'CNY'.
              <fs_item>-reason_code = ls_zztfi_0006-reasoncode.
              IF ls_zztfi_0002-racct = ls_zztfi_0006-glaccount.
                i_zztfi_0007-glaccount = ls_zztfi_0006-glaccount.
                <fs_item>-house_bank = ls_zztfi_0001-hbkid.
                <fs_item>-house_bank_account = ls_zztfi_0001-hktid.
                IF strlen( i_zztfi_0007-merchantcode ) = 4.
                  <fs_item>-trading_partner = i_zztfi_0007-merchantcode.
                ENDIF.
              ENDIF.
              IF i_zztfi_0007-extend2 IS INITIAL.
                <fs_item>-document_item_text = i_zztfi_0007-transactionserialnumber.
              ELSE.
                <fs_item>-document_item_text = i_zztfi_0007-extend2.
              ENDIF.
              <fs_item>-assignment_reference = i_zztfi_0007-transactionserialnumber.

            WHEN 'A'.
              APPEND INITIAL LINE TO <fs_entry>-debtor_item ASSIGNING FIELD-SYMBOL(<fs_ditem>).
              <fs_ditem>-reference_document_item = '1'.
              <fs_ditem>-debtor = i_zztfi_0007-merchantcode.
              <fs_ditem>-debit_credit_code = ls_zztfi_0006-debitcreditcode.
              <fs_ditem>-altv_recncln_accts-content = ls_zztfi_0006-altvrecnclnaccts.
              <fs_ditem>-amount_in_transaction_currency-currency_code = i_zztfi_0007-waers.
              IF ls_zztfi_0006-bhs_flag = 'X'.
                <fs_ditem>-amount_in_transaction_currency-content = lv_bhs.
              ELSEIF ls_zztfi_0006-se_flag = 'X'.
                <fs_ditem>-amount_in_transaction_currency-content = lv_se.
              ELSE.
                <fs_ditem>-amount_in_transaction_currency-content = i_zztfi_0007-claimamount.
              ENDIF.
              IF <fs_ditem>-debit_credit_code = 'H'.
                <fs_ditem>-amount_in_transaction_currency-content = abs( <fs_ditem>-amount_in_transaction_currency-content  ) * -1.
              ENDIF.
*              <fs_item>-amount_in_group_currency-content = ls_zztfi_0006-amountingroupcurrency.
*              <fs_item>-amount_in_group_currency-currency_code = 'CNY'.
              IF i_zztfi_0007-extend2 IS INITIAL.
                <fs_ditem>-document_item_text = i_zztfi_0007-transactionserialnumber.
              ELSE.
                <fs_ditem>-document_item_text = i_zztfi_0007-extend2.
              ENDIF.
              <fs_ditem>-assignment_reference = i_zztfi_0007-transactionserialnumber.
            WHEN 'K'.
              APPEND INITIAL LINE TO <fs_entry>-creditor_item ASSIGNING FIELD-SYMBOL(<fs_citem>).
              <fs_citem>-reference_document_item = '1'.
              <fs_citem>-creditor = i_zztfi_0007-merchantcode.
              <fs_citem>-debit_credit_code = ls_zztfi_0006-debitcreditcode.
              <fs_citem>-altv_recncln_accts-content = ls_zztfi_0006-altvrecnclnaccts.
              <fs_citem>-amount_in_transaction_currency-currency_code = i_zztfi_0007-waers.
              <fs_citem>-amount_in_transaction_currency-content = i_zztfi_0007-claimamount.
              IF ls_zztfi_0006-bhs_flag = 'X'.
                <fs_citem>-amount_in_transaction_currency-content = lv_bhs.
              ELSEIF ls_zztfi_0006-se_flag = 'X'.
                <fs_citem>-amount_in_transaction_currency-content = lv_se.
              ELSE.
                <fs_citem>-amount_in_transaction_currency-content = i_zztfi_0007-claimamount.
              ENDIF.
              IF <fs_citem>-debit_credit_code = 'H'.
                <fs_citem>-amount_in_transaction_currency-content = abs( <fs_citem>-amount_in_transaction_currency-content  ) * -1.
              ENDIF.
*              <fs_citem>-amount_in_group_currency-currency_code = 'CNY'.
*              <fs_citem>-amount_in_group_currency-content = ls_zztfi_0006-amountingroupcurrency.
              IF i_zztfi_0007-extend2 IS INITIAL.
                <fs_citem>-document_item_text = i_zztfi_0007-transactionserialnumber.
              ELSE.
                <fs_citem>-document_item_text = i_zztfi_0007-extend2.
              ENDIF.
              <fs_citem>-assignment_reference = i_zztfi_0007-transactionserialnumber.
          ENDCASE.
        ENDLOOP.

        proxy->journal_entry_create_request_c(
          EXPORTING
            input = request
          IMPORTING
            output = DATA(response)
        ).
        DATA(lt_confirmat) = response-journal_entry_bulk_create_conf-journal_entry_create_confirmat.
        READ TABLE lt_confirmat INTO DATA(ls_confirmat) INDEX 1.
        IF ls_confirmat-journal_entry_create_confirmat-accounting_document IS NOT INITIAL
        AND ls_confirmat-journal_entry_create_confirmat-accounting_document NE '0000000000'.
          i_zztfi_0007-flag = 'S'.
          i_zztfi_0007-accountingdocument = ls_confirmat-journal_entry_create_confirmat-accounting_document.
          i_zztfi_0007-fiscalyear = ls_confirmat-journal_entry_create_confirmat-fiscal_year.
          CLEAR:i_zztfi_0007-reversedaccountingdocument,i_zztfi_0007-reversedfiscalyear.
          i_zztfi_0007-msg = |交易流水号【{ i_zztfi_0007-transactionserialnumber }】生成会计凭证【{ i_zztfi_0007-accountingdocument }-{ i_zztfi_0007-fiscalyear }】|.
        ELSE.
          i_zztfi_0007-flag = 'E'.
          LOOP AT ls_confirmat-log-item[] INTO DATA(ls_item_log).
            i_zztfi_0007-msg = |{ i_zztfi_0007-msg }/{ ls_item_log-note }|.
          ENDLOOP.
        ENDIF.
        " handle response
      CATCH cx_soap_destination_error INTO DATA(destination_error).
        " handle error
        i_zztfi_0007-flag = 'E'.
        i_zztfi_0007-msg = '调用接口异常1:' && destination_error->get_longtext( ).
      CATCH cx_ai_system_fault INTO DATA(system_fault).
        " handle error
        i_zztfi_0007-flag = 'E'.
        i_zztfi_0007-msg = '调用接口异常2:' && system_fault->get_longtext( ).
    ENDTRY.
    "3.更新日志表
    MODIFY zztfi_0007 FROM @i_zztfi_0007.
    IF i_wbbs IS INITIAL."前台调用标识
      COMMIT WORK AND WAIT.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
