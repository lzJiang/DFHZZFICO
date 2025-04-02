@EndUserText.label: '收入成本明细表'
@ObjectModel.query.implementedBy: 'ABAP:ZZCL_RFICO001'
@UI.headerInfo: {
    typeName: '收入成本明细表',
    typeNamePlural: '收入成本明细表',
    title: {
        value: 'AccountingDocument',
        type: #STANDARD
    }
}
@Search.searchable: true
define root custom entity ZC_RFICO001

{

      // FACET SECTION

      @UI.facet                   : [
      // Header Facet (Object Page):

                 { id             :        'HeaderFacet',
                   purpose        :         #HEADER,
                   type           :         #FIELDGROUP_REFERENCE,
                   label          :         '收入成本明细表',
                   targetQualifier:         'HeaderItems', // Refers to lineItems with @UI.fieldGroup: [{qualifier: 'HeaderItems'}]
                   position       :         10 },

      // Body Facets (Object Page)

           // Facet 1

                 { id             :         'Facet1-ID',
                   purpose        :         #STANDARD,
                   type           :         #IDENTIFICATION_REFERENCE, // Refers to elements annotated with '@UI.identification' in the element list below
                   label          :         '明细信息',
                   position       :        10 }


                 ]

      @UI                         : { lineItem       : [ { position: 10,
                                                           importance: #HIGH } ],
                                      identification : [ { position: 10 } ],
                                      fieldGroup     : [ { qualifier: 'HeaderItems',
                                                         position: 10 } ] }
      @EndUserText                : { label:  '会计年度'}
      @UI.selectionField          : [ { position: 10 } ]
      @Consumption.filter         : { mandatory:true,
                                      selectionType: #SINGLE }
      @Search.defaultSearchElement: true
  key FiscalYear                  : gjahr;
      @UI                         : { lineItem       : [ { position: 20,
                                                           importance: #HIGH } ],
                                      identification : [ { position: 20 } ],
                                      fieldGroup     : [ { qualifier: 'HeaderItems',
                                                           position: 20 } ] }
      @EndUserText                : { label:  '期间'}
      @UI.selectionField          : [ { position: 20 } ]
  key FiscalPeriod                : monat;
      @UI                         : { lineItem       : [ { position: 30,
                                                           importance: #HIGH } ],
                                      identification : [ { position: 30 } ],
                                      fieldGroup     : [ { qualifier: 'HeaderItems',
                                                           position: 30 } ] }
      @EndUserText                : { label:  '公司代码'}
      @UI.selectionField          : [ { position: 30 } ]
      @Consumption.valueHelpDefinition:[ { entity: { name: 'I_CompanyCode', element: 'CompanyCode' } } ]
  key CompanyCode                 : bukrs;
      @UI                         : { lineItem       : [ { position: 40,
                                                           importance: #HIGH } ],
                                      identification : [ { position: 40 } ],
                                      fieldGroup     : [ { qualifier: 'HeaderItems',
                                                           position: 40 } ]}
      @EndUserText                : { label:  '日记账分录'}
  key AccountingDocument          : abap.char(10);
      @UI                         : { lineItem       : [ { position: 45 } ],
                                      identification : [ { position: 45 } ],
                                      fieldGroup     : [ { qualifier: 'HeaderItems',
                                                           position: 45 } ]}
      @EndUserText                : { label:  '日记账分录行号'}
  key LedgerGLLineItem            : abap.char(6);
      @UI                         : { lineItem       : [ { position: 50,
                                                           importance: #HIGH } ],
                                      identification : [ { position: 50 } ]}
      @UI.selectionField          : [ { position: 40 } ]
      @Consumption.valueHelpDefinition:[ { entity: { name: 'I_GLAccount', element: 'GLAccount' } } ]
      @EndUserText                : { label:  '总账科目'}
      GLAccount                   : hkont;
      @UI                         : { lineItem       : [ { position: 60 } ],
                                         identification : [ { position: 60 } ]}
      @EndUserText                : { label:  '总账科目长名称'}
      GLAccountLongName           : abap.char(50);
      @UI                         : { lineItem       : [ { position: 45 } ],
                                         identification : [ { position: 45 } ]}
      @EndUserText                : { label:  '公司代码名称'}
      CompanyCodeName             : butxt;
      @UI                         : { lineItem       : [ { position: 65 } ],
                                      identification : [ { position: 65 } ]}
      @EndUserText                : { label:  '日记账分录创建人'}
      AccountingDocCreatedByUser  : usnam;
      @UI                         : { lineItem       : [ { position: 70,
                                                           importance: #HIGH } ],
                                      identification : [ { position: 70 } ]}
      @EndUserText                : { label:  '以公司代码货币计金额'}
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmountInCompanyCodeCurrency : abap.curr( 23, 2 );
      @UI                         : { lineItem       : [ { position: 75 } ],
                                      identification : [ { position: 75 } ]}
      @EndUserText                : { label:  '公司代码货币'}
      CompanyCodeCurrency         : abap.cuky(5);
      @UI                         : { lineItem       : [ { position: 80 } ],
                                      identification : [ { position:80 } ]}
      @UI.selectionField          : [ { position: 50 } ]
      @Consumption.valueHelpDefinition:[ { entity: { name: 'I_ProductText', element: 'Product' } } ]
      @EndUserText                : { label:  '产品'}
      Product                     : matnr;
      @UI                         : { lineItem       : [ { position: 90 } ],
                                      identification : [ { position: 90 } ]}
      @EndUserText                : { label:  '产品名称'}
      ProductName                 : maktx;
      @UI                         : { lineItem       : [ { position: 110,
                                                           importance: #HIGH } ],
                                      identification : [ { position: 110 } ]}
      @EndUserText                : { label:  '供应商'}
      Supplier                    : lifnr;
      @UI                         : { lineItem       : [ { position: 120 } ],
                                      identification : [ { position: 120 } ]}
      @EndUserText                : { label:  '供应商名称'}
      SupplierName                : abap.char(35);
      @UI                         : { lineItem       : [ { position: 130,
                                                           importance: #HIGH } ],
                                      identification : [ { position: 130 } ]}
      @EndUserText                : { label:  '客户'}
      Customer                    : kunnr;
      @UI                         : { lineItem       : [ { position: 140 } ],
                                      identification : [ { position: 140 } ]}
      @EndUserText                : { label:  '客户名称'}
      CustomerName                : abap.char(35);
      @UI                         : { lineItem       : [ { position: 150 } ],
                                      identification : [ { position: 150 } ]}
      @EndUserText                : { label:  '税码'}
      TaxCode                     : mwskz;
      @UI                         : { lineItem       : [ { position: 160,
                                                           importance: #HIGH } ],
                                      identification : [ { position: 160 } ]}
      @UI.selectionField          : [ { position: 60 } ]
      @EndUserText                : { label:  '过账日期'}
      PostingDate                 : budat;
      @UI                         : { lineItem       : [ { position: 170 } ],
                                      identification : [ { position: 170 } ]}
      @EndUserText                : { label:  '利润中心'}
      ProfitCenter                : prctr;
      @UI                         : { lineItem       : [ { position: 180 } ],
                                      identification : [ { position: 180 } ]}
      @EndUserText                : { label:  '利润中心名称'}
      ProfitCenterName            : abap.char(30);
      @UI                         : { lineItem       : [ { position: 200 } ],
                                      identification : [ { position: 200 } ]}
      @EndUserText                : { label:  '参考凭证'}
      ReferenceDocument           : awref;
      @UI                         : { lineItem       : [ { position: 205 } ],
                                      identification : [ { position: 205 } ]}
      @EndUserText                : { label:  '以销售单位计的数量'}
      @Semantics.quantity.unitOfMeasure: 'saleUnit'
      Quantity                    : menge_d;
      @UI                         : { lineItem       : [ { position: 206,
                                                           exclude: true,
                                                           hidden : true } ],
                                      identification : [ { position: 206,
                                                           exclude: true,
                                                           hidden : true  } ]}
      @EndUserText                : { label:  '销售单位编码'}
      saleUnit                    : abap.unit(3);
      @UI                         : { lineItem       : [ { position: 210 } ],
                                      identification : [ { position: 210 } ]}
      @EndUserText                : { label:  '销售单位'}
      saleUnitDesc                : abap.char(20);
      @UI                         : { lineItem       : [ { position: 220 } ],
                                      identification : [ { position: 220 } ]}
      @EndUserText                : { label:  '采购凭证'}
      PurchasingDocument          : ebeln;
      @UI                         : { lineItem       : [ { position: 230 } ],
                                      identification : [ { position: 230 } ]}
      @EndUserText                : { label:  '销售凭证'}
      SalesDocument               : vbeln;
      @UI                         : { lineItem       : [ { position: 235,
                                                           exclude: true,
                                                           hidden : true } ],
                                      identification : [ { position: 235,
                                                           exclude: true,
                                                           hidden : true  } ]}
      @EndUserText                : { label:  '最小单位编码'}
      BaseUnit                    : abap.unit(3);
      @UI                         : { lineItem       : [ { position: 240 } ],
                                      identification : [ { position: 240 } ]}
      @EndUserText                : { label:  '最小单位'}
      BaseUnitDesc                : abap.char(20);
      @UI                         : { lineItem       : [ { position: 250,
                                                           exclude: true,
                                                           hidden : true } ],
                                      identification : [ { position: 250,
                                                           exclude: true,
                                                           hidden : true  } ]}
      @EndUserText                : { label:  '账面库存单位的可选计量单位'}
      AlternativeUnit             : abap.unit(3);
      @UI                         : { lineItem       : [ { position: 260 } ],
                                      identification : [ { position: 260 } ]}
      @EndUserText                : { label:  '转换为基本计量单位的分子'}
      QuantityNumerator           : umrez;
      @UI                         : { lineItem       : [ { position: 270 } ],
                                      identification : [ { position: 270 } ]}
      @EndUserText                : { label:  '转换为基本计量单位的分母'}
      QuantityDenominator         : umren;
      @UI                         : { lineItem       : [ { position: 280 } ],
                                      identification : [ { position: 280 } ]}
      @EndUserText                : { label:  '以最小单位计的数量'}
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      QuantityInBaseUnit          : menge_d;
}
