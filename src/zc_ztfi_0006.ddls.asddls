@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_ZTFI_0006
  provider contract transactional_query
  as projection on ZR_ZTFI_0006
{
  key Itemno,
  key Extend1,
      Koart,
      Glaccount,
      Altvrecnclnaccts,
      Debitcreditcode,
      Reasoncode,
      BhsFlag,
      SeFlag,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt

}
