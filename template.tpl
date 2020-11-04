___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "__wm": "VGVtcGxhdGUtQXV0aG9yX2VlYy1wcm9kdWN0cy1nYTQtaXRlbXMtU2ltby1BaGF2YQ\u003d\u003d",
  "categories": [
    "UTILITY",
    "TAG_MANAGEMENT"
  ],
  "version": 1,
  "securityGroups": [],
  "displayName": "EEC Products -\u003e GA4 Items",
  "description": "Converts Universal Analytics Enhanced Ecommerce products/impressions/promotions dataLayers to the format required by GA4\u0027s items array.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "RADIO",
    "name": "option",
    "displayName": "Map Source",
    "radioItems": [
      {
        "value": "auto",
        "displayValue": "Map ecommerce object automatically"
      },
      {
        "value": "products",
        "displayValue": "Map products array",
        "subParams": [
          {
            "type": "SELECT",
            "name": "productsVar",
            "displayName": "",
            "macrosInSelect": true,
            "selectItems": [],
            "simpleValueType": true,
            "notSetText": "Select variable that returns a \"products\" array"
          }
        ]
      },
      {
        "value": "impressions",
        "displayValue": "Map impressions array",
        "subParams": [
          {
            "type": "SELECT",
            "name": "impressionsVar",
            "macrosInSelect": true,
            "selectItems": [],
            "simpleValueType": true,
            "notSetText": "Select variable that returns an \"impressions\" array"
          }
        ]
      },
      {
        "value": "promotions",
        "displayValue": "Map promotions array",
        "subParams": [
          {
            "type": "SELECT",
            "name": "promotionsVar",
            "macrosInSelect": true,
            "selectItems": [],
            "simpleValueType": true,
            "notSetText": "Select variable that returns a \"promotions\" array"
          }
        ]
      }
    ],
    "simpleValueType": true,
    "help": "Choose \u003cstrong\u003eMap ecommerce object automatically\u003c/strong\u003e to map the most recently pushed \u003cstrong\u003eecommerce\u003c/strong\u003e object\u0027s item array into the format required by Google Analytics 4. Select another option to reference a specific type of array directly."
  },
  {
    "type": "GROUP",
    "name": "mapGroup",
    "displayName": "Map Custom Definitions To Item Parameters",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "LABEL",
        "name": "customdeflabel",
        "displayName": "If your Enhanced Ecommerce object contains product-scoped custom dimensions/metrics, you can use this table to map those into GA4 item parameter names. Input the index number of the custom definition in the first field, and the parameter name with which the value should be sent to GA4 in the second."
      },
      {
        "type": "SIMPLE_TABLE",
        "name": "customDims",
        "simpleTableColumns": [
          {
            "defaultValue": "",
            "displayName": "Custom Dimension Index",
            "name": "cdindex",
            "type": "TEXT",
            "valueValidators": [
              {
                "type": "POSITIVE_NUMBER"
              }
            ],
            "isUnique": true
          },
          {
            "defaultValue": "",
            "displayName": "Item Parameter Name",
            "name": "cdparam",
            "type": "TEXT",
            "valueValidators": [
              {
                "type": "NON_EMPTY"
              }
            ]
          }
        ],
        "newRowButtonText": "Add custom dimension map"
      },
      {
        "type": "SIMPLE_TABLE",
        "name": "customMets",
        "simpleTableColumns": [
          {
            "defaultValue": "",
            "displayName": "Custom Metric Index",
            "name": "cmindex",
            "type": "TEXT",
            "valueValidators": [
              {
                "type": "POSITIVE_NUMBER"
              }
            ],
            "isUnique": true
          },
          {
            "defaultValue": "",
            "displayName": "Item Parameter Name",
            "name": "cmparam",
            "type": "TEXT",
            "valueValidators": [
              {
                "type": "NON_EMPTY"
              }
            ]
          }
        ],
        "newRowButtonText": "Add custom metric map"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const copyFromDataLayer = require('copyFromDataLayer');
const makeNumber = require('makeNumber');
const makeTableMap = require('makeTableMap');

const customDimMap = data.customDims ? makeTableMap(data.customDims, 'cdindex', 'cdparam') : {};
const customMetMap = data.customMets ? makeTableMap(data.customMets, 'cmindex', 'cmparam') : {};

const mapProductData = i => {
  const category = i.category ? i.category.split('/') : [];
  const itemObj = {
    item_id: i.id,
    item_name: i.name,
    price: i.price,
    item_brand: i.brand,
    item_variant: i.variant,
    quantity: i.quantity
  };
  category.forEach((c, i) => {
    if (i === 0) itemObj.item_category = c;
    else itemObj['item_category_' + (i + 1)] = c;
  });
  for (let prop in i) {
    if (prop.indexOf('dimension') === 0) {
      let paramName = customDimMap[prop.split('dimension')[1]];
      itemObj[paramName || prop] = i[prop];
    } else if (prop.indexOf('metric') === 0) {
      let paramName = customMetMap[prop.split('metric')[1]];
      itemObj[paramName || prop] = makeNumber(i[prop]) || 0;
    }
  }
  return itemObj;
};

const mapImpressionData = i => {
  const impression = mapProductData(i);
  impression.item_list_name = i.list;
  impression.index = i.position;
  return impression;
};

const mapPromotionData = i => {
  return {
    promotion_name: i.name,
    promotion_id: i.id,
    creative_name: i.creative,
    creative_slot: i.position
  };
};  

if (data.option === 'auto') {
  const eec = copyFromDataLayer('ecommerce', 1) || {};

  if (eec.hasOwnProperty('click')) {
    return eec.click.products.map(i => {
      const product = mapProductData(i);
      product.item_list_name = eec.click.actionField ? eec.click.actionField.list : undefined;
      product.index = i.position;
      return product;
    });
  }

  if (eec.hasOwnProperty('detail')) {
    return eec.detail.products.map(i => {
      const product = mapProductData(i);
      product.item_list_name = eec.detail.actionField ? eec.detail.actionField.list : undefined;
      return product;
    });
  }

  if (eec.hasOwnProperty('add')) {
    return eec.add.products.map(i => {
      const product = mapProductData(i);
      product.item_list_name = eec.add.actionField ? eec.add.actionField.list : undefined;
      return product;
    });
  }

  if (eec.hasOwnProperty('remove')) {
    return eec.remove.products.map(i => {
      const product = mapProductData(i);
      product.item_list_name = eec.remove.actionField ? eec.remove.actionField.list : undefined;
      return product;
    });
  }

  if (eec.hasOwnProperty('checkout')) {
    return eec.checkout.products.map(i => {
      const product = mapProductData(i);
      product.item_list_name = eec.checkout.actionField ? eec.checkout.actionField.list : undefined;
      return product;
    });
  }

  if (eec.hasOwnProperty('purchase')) {
    return eec.purchase.products.map(i => {
      const product = mapProductData(i);
      product.item_list_name = eec.purchase.actionField ? eec.purchase.actionField.list : undefined;
      return product;
    });
  }

  if (eec.hasOwnProperty('refund')) {
    return eec.refund.products.map(i => {
      const product = mapProductData(i);
      product.item_list_name = eec.refund.actionField ? eec.refund.actionField.list : undefined;
      return product;
    });
  }

  if (eec.hasOwnProperty('impressions')) {
    return eec.impressions.map(mapImpressionData);
  }

  if (eec.hasOwnProperty('promoView')) {
    return eec.promoView.promotions.map(mapPromotionData);
  }

  if (eec.hasOwnProperty('promoClick')) {
    return eec.promoClick.promotions.map(mapPromotionData);
  }

  return [];
}

if (data.option === 'products') {
  return data.productsVar.map(mapProductData);
}

if (data.option === 'impressions') {
  return data.impressionsVar.map(mapImpressionData);
}

if (data.option === 'promotions') {
  return data.promotionsVar.map(mapPromotionData);
}


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "ecommerce"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Read custom products variable correctly
  code: |-
    mockData.option = 'products';

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    // Verify that the variable returns a result.
    assertThat(variableResult).isEqualTo(expected.products);
- name: Read custom impressions variable correctly
  code: |-
    mockData.option = 'impressions';

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    // Verify that the variable returns a result.
    assertThat(variableResult).isEqualTo(expected.impressions);
- name: Read custom promotions variable correctly
  code: |-
    mockData.option = 'promotions';

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    // Verify that the variable returns a result.
    assertThat(variableResult).isEqualTo(expected.promotions);
- name: Read ecommerce_impressions dataLayer correctly
  code: |-
    mock('copyFromDataLayer', (n, v) => {
      assertThat(v).isEqualTo(1);
      return {impressions: mockData.impressionsVar};
    });

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    // Verify that the variable returns a result.
    assertThat(variableResult).isEqualTo(expected.impressions);
- name: Read ecommerce_promoView dataLayer correctly
  code: |-
    mock('copyFromDataLayer', (n, v) => {
      assertThat(v).isEqualTo(1);
      return {promoView: {promotions: mockData.promotionsVar}};
    });

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    // Verify that the variable returns a result.
    assertThat(variableResult).isEqualTo(expected.promotions);
- name: Read ecommerce_checkout dataLayer correctly
  code: |-
    mock('copyFromDataLayer', (n, v) => {
      assertThat(v).isEqualTo(1);
      return {checkout: {products: mockData.productsVar}};
    });

    expected.products = expected.products.map(p => {
      p.item_list_name = undefined;
      return p;
    });

    // Call runCode to run the template's code.
    let variableResult = runCode(mockData);

    // Verify that the variable returns a result.
    assertThat(variableResult).isEqualTo(expected.products);
setup: |-
  const mockData = {
    option: 'auto',
    productsVar: [{
      id: 'p1',
      name: 'n1',
      price: 10.00,
      brand: 'b1',
      variant: 'v1',
      quantity: 1,
      dimension1: 'd1',
      dimension17: 'd17',
      metric1: '1',
      metric17: '17'
    },{
      id: 'p2',
      name: 'n2',
      price: 11.00,
      brand: 'b2',
      variant: 'v2',
      quantity: 2,
      dimension2: 'd2',
      metric2: '2',
      dimension18: 'd18',
      metric18: '18'
    }],
    impressionsVar: [{
      id: 'impi1',
      name: 'imn1',
      price: 12.00,
      brand: 'imb1',
      variant: 'imv1',
      quantity: 1,
      dimension3: 'd3',
      metric3: '3',
      dimension19: 'd19',
      metric19: '19',
      list: 'il1',
      position: 1
    },{
      id: 'impi2',
      name: 'imn2',
      price: 13.00,
      brand: 'imb2',
      variant: 'imv2',
      quantity: 2,
      dimension4: 'd4',
      metric4: '4',
      dimension20: 'd20',
      metric20: '20',
      list: 'il1',
      position: 2
    }],
    promotionsVar: [{
      id: 'promo1',
      name: 'promon1',
      creative: 'promoc1',
      position: 'slot1'
    },{
      id: 'promo2',
      name: 'promon2',
      creative: 'promoc2',
      position: 'slot2'
    }],
    customDims: [{
      cdindex: '17',
      cdparam: 'dim17'
    },{
      cdindex: '18',
      cdparam: 'dim18'
    },{
      cdindex: '19',
      cdparam: 'dim19'
    },{
      cdindex: '20',
      cdparam: 'dim20'
    }],
    customMets: [{
      cmindex: '17',
      cmparam: 'met17'
    },{
      cmindex: '18',
      cmparam: 'met18'
    },{
      cmindex: '19',
      cmparam: 'met19'
    },{
      cmindex: '20',
      cmparam: 'met20'
    }]
  };

  const expected = {
    products: [{
      item_id: 'p1',
      item_name: 'n1',
      price: 10.00,
      item_brand: 'b1',
      item_variant: 'v1',
      quantity: 1,
      dimension1: 'd1',
      metric1: 1,
      dim17: 'd17',
      met17: 17
    },{
      item_id: 'p2',
      item_name: 'n2',
      price: 11.00,
      item_brand: 'b2',
      item_variant: 'v2',
      quantity: 2,
      dimension2: 'd2',
      metric2: 2,
      dim18: 'd18',
      met18: 18
    }],
    impressions: [{
      item_id: 'impi1',
      item_name: 'imn1',
      price: 12.00,
      item_brand: 'imb1',
      item_variant: 'imv1',
      quantity: 1,
      dimension3: 'd3',
      metric3: 3,
      dim19: 'd19',
      met19: 19,
      item_list_name: 'il1',
      index: 1
    },{
      item_id: 'impi2',
      item_name: 'imn2',
      price: 13.00,
      item_brand: 'imb2',
      item_variant: 'imv2',
      quantity: 2,
      dimension4: 'd4',
      metric4: 4,
      dim20: 'd20',
      met20: 20,
      item_list_name: 'il1',
      index: 2
    }],
    promotions: [{
      promotion_id: 'promo1',
      promotion_name: 'promon1',
      creative_name: 'promoc1',
      creative_slot: 'slot1'
    },{
      promotion_id: 'promo2',
      promotion_name: 'promon2',
      creative_name: 'promoc2',
      creative_slot: 'slot2'
    }]
  };


___NOTES___

Created on 17/10/2020, 22:54:27


