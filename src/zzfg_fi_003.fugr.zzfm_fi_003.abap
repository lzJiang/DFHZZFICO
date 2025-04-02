FUNCTION zzfm_fi_003.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(I_REQ) TYPE  ZZS_FII003_REQ OPTIONAL
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------

  DATA:lt_zztfi_0007 TYPE TABLE OF zztfi_0007,
       ls_zztfi_0007 TYPE zztfi_0007.

  DATA:lv_zztstmpl TYPE tzntstmpl.
  GET TIME STAMP FIELD lv_zztstmpl.
  DATA(lv_date) = cl_abap_context_info=>get_system_date( ).
  DATA(lv_time) = cl_abap_context_info=>get_system_time( ).
  DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).
  LOOP AT i_req-req INTO DATA(ls_data).
    MOVE-CORRESPONDING ls_data TO ls_zztfi_0007.
    ls_zztfi_0007-zztstmpl = lv_zztstmpl.
    ls_zztfi_0007-created_date = lv_date.
    ls_zztfi_0007-created_time = lv_time.
    ls_zztfi_0007-created_by = lv_user.
    APPEND ls_zztfi_0007 TO lt_zztfi_0007.
  ENDLOOP.

  CHECK lt_zztfi_0007[] IS NOT INITIAL.
  "删除已经成功处理的数据
  SELECT transactionserialnumber
    FROM zztfi_0007 WITH PRIVILEGED ACCESS AS a
    INNER JOIN i_journalentry WITH PRIVILEGED ACCESS AS b
      ON a~accountingdocument = b~accountingdocument AND a~fiscalyear = b~fiscalyear
     FOR ALL ENTRIES IN @lt_zztfi_0007
   WHERE transactionserialnumber = @lt_zztfi_0007-transactionserialnumber
     AND flag = 'S'
     AND b~isreversed = ''
   INTO TABLE @DATA(lt_tmp).
  "删除正在处理的数据
  SELECT transactionserialnumber
    FROM zztfi_0007 WITH PRIVILEGED ACCESS AS a
     FOR ALL ENTRIES IN @lt_zztfi_0007
   WHERE transactionserialnumber = @lt_zztfi_0007-transactionserialnumber
     AND flag = 'R'
   APPENDING TABLE @lt_tmp.

  SORT lt_tmp BY transactionserialnumber.
  LOOP AT lt_zztfi_0007 INTO ls_zztfi_0007.
    READ TABLE lt_tmp TRANSPORTING NO FIELDS WITH KEY transactionserialnumber = ls_zztfi_0007-transactionserialnumber BINARY SEARCH.
    IF sy-subrc = 0.
      DELETE lt_zztfi_0007.
    ENDIF.
  ENDLOOP.

  IF lt_zztfi_0007 IS NOT INITIAL.
    MODIFY zztfi_0007 FROM TABLE @lt_zztfi_0007.
  ENDIF.
*  "后台JOB处理
*  DATA job_template_name TYPE cl_apj_rt_api=>ty_template_name VALUE 'ZZ_JT_FI002'.
*  DATA job_start_info TYPE cl_apj_rt_api=>ty_start_info.
*  DATA job_parameters TYPE cl_apj_rt_api=>tt_job_parameter_value.
*  DATA job_name TYPE cl_apj_rt_api=>ty_jobname.
*  DATA job_count TYPE cl_apj_rt_api=>ty_jobcount.
*  DATA p_tstmpl TYPE c LENGTH 50.
*
*  p_tstmpl = lv_zztstmpl.
*  CONDENSE p_tstmpl NO-GAPS.
*
*  job_parameters = VALUE #( ( name  = 'TSTMPL'
*                              t_value = VALUE #( ( sign = 'I' option = 'EQ'  low = p_tstmpl ) ) ) ).
*
*  TRY.
*      cl_apj_rt_api=>schedule_job(
*            EXPORTING
*            iv_job_template_name = job_template_name
*            iv_job_text = |收款凭证创建 { lv_zztstmpl }|
*            is_start_info = job_start_info
*            it_job_parameter_value = job_parameters
*            IMPORTING
*            ev_jobname  = job_name
*            ev_jobcount = job_count
*            ).
*
*    CATCH cx_apj_rt INTO DATA(job_scheduling_error).
*      DATA(lv_text) = job_scheduling_error->get_longtext( ).
*  ENDTRY.

  o_resp-msgty = 'S'.
  o_resp-msgtx = '数据接收成功'.

ENDFUNCTION.
