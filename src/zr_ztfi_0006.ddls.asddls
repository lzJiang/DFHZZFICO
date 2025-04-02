@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_ZTFI_0006
  as select from zztfi_0006
{
  key itemno           as Itemno,
  key extend1          as Extend1,
      koart            as Koart,
      glaccount        as Glaccount,
      altvrecnclnaccts as Altvrecnclnaccts,
      debitcreditcode  as Debitcreditcode,
      reasoncode       as Reasoncode,
      bhs_flag         as BhsFlag,
      se_flag          as SeFlag,
      @Semantics.user.createdBy: true
      created_by       as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at       as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by  as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at  as LastChangedAt

}
