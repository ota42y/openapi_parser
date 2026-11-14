## Unreleased
* match an exact `additionalOperations` key before a standard method in 3.2 documents, so a `Get` request finds `additionalOperations.Get` rather than `get` ([OpenAPI 3.2](https://spec.openapis.org/oas/v3.2.0.html#path-item-object), [RFC 9110 §9.1](https://www.rfc-editor.org/rfc/rfc9110.html#section-9.1))
* check the keywords next to `$ref` in Schema Objects of OpenAPI 3.1 documents, such as `{ $ref: ..., maxLength: 3 }`. They were ignored before, so a value that passed may now fail. A Reference Object, and any object in a 3.0 document, still ignores them. Readers such as `Schema#type` still return the values of the referenced schema
* accept a value that matches exactly one `oneOf` member as it is when `coerce_value` is on, and keep it uncoerced. `"1"` for `oneOf: [integer, string]` failed with `NotOneOf` before, because coercion made it match both
* support the `propertyNames` keyword (OpenAPI 3.1): every property name of an object is checked against its schema, and the first name that fails returns the error from that schema, such as `InvalidPattern` or `MoreThanMaxLength`. Names are checked as strings even when `coerce_value` is on. It was ignored before, so a value that passed may now fail
* add `SpecValidator` rule `PropertyNamesIn30`: detect `propertyNames` in 3.0 documents (3.1 addition)
* check `enum` on objects and arrays (OpenAPI 3.0 and 3.1). A value now has to equal one of the members, as in JSON Schema: objects are compared by keys and values, and arrays element by element in order. It was ignored before, so a value that passed may now fail. In particular, `enum` written next to `items`, such as `{ type: array, items: { type: string }, enum: [a, b] }`, now rejects every array. To limit the elements, move `enum` into `items`
* support the `patternProperties` keyword (OpenAPI 3.1): a property whose name matches a pattern is now checked against that pattern's schema, as well as its `properties` schema. Such a property is no longer an additional property, so `additionalProperties` does not apply to it. It was ignored before, so a value that passed may now fail, and a value that failed on `additionalProperties` may now pass
* add `SpecValidator` rule `PatternPropertiesIn30`: detect `patternProperties` in 3.0 documents (3.1 addition)

## 2.7.0 (2026-11-06)
* match `additionalOperations` method names case-sensitively ([OpenAPI 3.2](https://spec.openapis.org/oas/v3.2.0.html#path-item-object), [RFC 9110 §9.1](https://www.rfc-editor.org/rfc/rfc9110.html#section-9.1)). Standard methods still match their fixed fields in any case
* check the keywords next to `allOf`, `anyOf` and `oneOf` (OpenAPI 3.0 and 3.1), such as `{ allOf: [...], required: [a] }`, and all of these keywords when a schema has more than one. They were ignored before, so a value that passed may now fail. In particular, `additionalProperties: false` next to `allOf` now rejects the properties defined only in `allOf`, as in JSON Schema
* return the coerced value from `allOf` and `oneOf` when `coerce_value` is on. They returned the original value before
* support the `dependentRequired` keyword (OpenAPI 3.1): an object that has a property but not the properties it depends on now fails with `NotExistDependentRequiredKey`. It was ignored before, so a value that passed may now fail
* add `SpecValidator` rule `DependentRequiredIn30`: detect `dependentRequired` in 3.0 documents (3.1 addition)

## 2.6.0 (2026-11-04)
* support the `multipleOf` keyword (OpenAPI 3.0 and 3.1): a number that is not a multiple of it now fails with `NotMultipleOf`. Decimals are compared exactly, so `19.99` is a multiple of `0.01`. A `multipleOf` that is not a positive number is still ignored. It was ignored before, so a value that passed may now fail
* support the `not` keyword (OpenAPI 3.0 and 3.1): a value that is valid against the `not` schema now fails with `NotSchemaMatched`. It was ignored before, so a value that passed may now fail
* add OpenAPI 3.2 `SpecValidator` rules
  * `CookieStyleBefore32`: detect Parameter `style: cookie` usage in pre-3.2 documents (3.2 addition)
  * `DefaultMappingBefore32`: detect Discriminator `defaultMapping` usage in pre-3.2 documents (3.2 addition)
  * `MediaTypesBefore32`: detect `components.mediaTypes` usage in pre-3.2 documents (3.2 addition)
  * `XmlNodeTypeBefore32`: detect XML Object `nodeType` usage in pre-3.2 documents (3.2 addition)
  * `XmlAttributeDeprecation` / `XmlWrappedDeprecation`: detect XML Object `attribute: true` / `wrapped: true` in 3.2 documents (deprecated in 3.2 in favor of `nodeType`)
  * `QueryMethodBefore32`: detect Path Item `query` usage in pre-3.2 documents (3.2 addition)
  * `AdditionalOperationsBefore32`: detect Path Item `additionalOperations` usage in pre-3.2 documents (3.2 addition)
  * `ResponseSummaryBefore32`: detect Response Object `summary` usage in pre-3.2 documents (3.2 addition)
  * `TagFieldsBefore32`: detect Tag Object `summary` / `parent` / `kind` usage in pre-3.2 documents (3.2 additions)
  * `ServerNameBefore32`: detect Server Object `name` usage in pre-3.2 documents (3.2 addition)
  * `AllowEmptyValueDeprecation`: detect Parameter `allowEmptyValue` usage in 3.2 documents (deprecated in 3.2)
  * `ExampleValueFieldsBefore32`: detect Example Object `dataValue` / `serializedValue` usage in pre-3.2 documents (3.2 additions)
  * `SecuritySchemeFieldsBefore32`: detect Security Scheme `deprecated` / `oauth2MetadataUrl` and the `deviceAuthorization` OAuth flow in pre-3.2 documents (3.2 additions)
  * `StreamingFieldsBefore32`: detect Media Type `itemSchema` / `itemEncoding` / `prefixEncoding` and nested Encoding Object `encoding` / `itemEncoding` / `prefixEncoding` usage in pre-3.2 documents (3.2 additions)
  * `QuerystringBefore32`: detect Parameter `in: querystring` usage in pre-3.2 documents (3.2 addition; not validated at runtime)
* return nil from `request_operation` for a document without `paths` (3.1 allows a document with only `webhooks`), instead of raising `NoMethodError`
* support `$defs` (OpenAPI 3.1) in Schema Objects so `$ref`s into it, such as `#/components/schemas/Pet/$defs/Id`, resolve
* add `SpecValidator` rule `DefsIn30`: detect `$defs` in 3.0 documents (3.1 addition)
* validate a value against a schema without `type`: keywords such as `properties`, `required`, `items`, `maxLength`, `enum` and `minimum` now apply when the value has the type the keyword is for, as in JSON Schema. They were all skipped before, so a value that breaks them may now fail validation
* support Discriminator `defaultMapping` (OpenAPI 3.2): fallback schema when the discriminator property is absent or its value has no explicit or implicit mapping; honored in 3.2 documents
* add `allow_3_2_features` config to apply OpenAPI 3.2 runtime behavior to documents that declare an earlier version (default `false`: pre-3.2 documents behave as before)
* accept `null` for a schema without `type`, as in JSON Schema. `enum` still applies, so `null` must be listed there when `enum` is set. A schema without `type` used to reject `null` with `NotNullError`, so a value that failed before may now pass
* accept a Float with no fractional part, such as `1.0`, for `type: integer` in OpenAPI 3.1 documents, as in JSON Schema. OpenAPI 3.0 defines an integer as a number without a fraction, so 3.0 documents still reject it. In 3.1 documents a value that failed before may now pass, and `oneOf` with both `integer` and `number` now rejects `1.0` because it matches both
* support `components.mediaTypes` (OpenAPI 3.2), resolving `$ref`s in request body and response `content` in 3.2 documents; an unresolved one accepts any body unless `strict_reference_validation` is set
* support the `query` HTTP method and `additionalOperations` (OpenAPI 3.2) on Path Items, including request-operation lookup, in 3.2 documents
* match HTTP methods case-insensitively in request-operation lookup in 3.2 documents (`request_operation("GET", path)` still returns nil before 3.2)
* support Response Object `summary` (OpenAPI 3.2) in the parse layer
* accept a file object for array-form `type` with `format: binary` (3.1) when `coerce_value` is off, the same way as a single `type: string`
* support `itemSchema` (OpenAPI 3.2) in the parse layer; it is not yet used to validate sequential media type bodies

## 2.5.0 (2026-10-21)
* add OpenAPI 3.2 `SpecValidator` rules
  * `SelfBefore32`: detect `$self` usage in pre-3.2 documents (3.2 addition)
* support root-level `$self` (OpenAPI 3.2) in the parse layer (`self_uri`); it is not yet used as the base URI for `$ref` resolution
* support boolean schemas (OpenAPI 3.1): `true` accepts any value and `false` rejects any value with `FalseSchemaError`, instead of crashing the loader with `NoMethodError`
* add `SpecValidator` rule `BooleanSchemaIn30`: detect boolean schemas in 3.0 documents (3.1 addition; `additionalProperties` is not affected)
* coerce non-String values into array-form `type` (3.1) the same way as a single `type` when `coerce_value` is on, so `type: [integer, "null"]` handles a Float the same way as `type: integer`
* stop truncating a Float with a fractional part in integer coercion (`coerce_value`): `1.5` for `type: integer` now fails instead of becoming `1`, while a Float with no fractional part, like `1.0`, is still converted

## 2.4.0 (2026-10-14)
* support `components.pathItems` so `$ref`s into it resolve, unblocking OpenAPI 3.1 documents that use reusable path items
* support array-form `type` (3.1) in value validation
* support root-level `jsonSchemaDialect` (OpenAPI 3.1) in the parse layer
* support `prefixItems` (OpenAPI 3.1) with positional tuple validation
* support `contentMediaType` (OpenAPI 3.1) in the parse layer
* support `contentEncoding` (OpenAPI 3.1) in the parse layer
* add `SpecValidator` with `strict_specification_version` config (`:silent` / `:warn` / `:raise`) to detect version mismatches between declared OpenAPI version and actual field usage
  * `ContentEncodingIn30`: detect `contentEncoding` usage in 3.0 documents (3.1 addition)
  * `ContentMediaTypeIn30`: detect `contentMediaType` usage in 3.0 documents (3.1 addition)
  * `PrefixItemsIn30`: detect `prefixItems` usage in 3.0 documents (3.1 addition)
  * `JsonSchemaDialectIn30`: detect root-level `jsonSchemaDialect` usage in 3.0 documents (3.1 addition)
  * `TypeArrayIn30`: detect array-form `type` usage in 3.0 documents (3.1 form)
  * `NullableDeprecation`: detect `nullable` usage in 3.1 documents (removed in 3.1)
  * `ExampleSingularDeprecation`: detect singular `example` on schemas in 3.1 documents (deprecated in 3.1)
  * `PathItemsIn30`: detect `components.pathItems` usage in 3.0 documents (3.1 addition)
  * `ExclusiveMinimum` / `ExclusiveMaximum`: detect 3.0 Boolean vs 3.1 numeric form mismatch
  * `TypeNullIn30`: detect `type: "null"` usage in 3.0 documents (3.1 primitive)
  * `WebhooksIn30`: detect root-level `webhooks` usage in 3.0 documents (3.1 addition)
  * `ConstIn30`: detect `const` usage in 3.0 documents (3.1 addition)
  * `DynamicRefIn30`: detect `$dynamicRef` usage in 3.0 documents (3.1 addition)
  * `DynamicAnchorIn30`: detect `$dynamicAnchor` usage in 3.0 documents (3.1 addition)
  * `ContentSchemaIn30`: detect `contentSchema` usage in 3.0 documents (3.1 addition)
* expose the declared version as `OpenAPI#openapi_version` (a `Gem::Version`, or nil when the field is missing or malformed) so `SpecValidator` rules compare version ranges; a 3.2 document is checked by the 3.1-or-later rules
* support 3.1-style numeric `exclusiveMinimum` / `exclusiveMaximum` in value validation (standalone bound, not a Boolean modifier on `minimum` / `maximum`)
* support `type: "null"` (3.1 primitive) in value validation
* support root-level `webhooks` (OpenAPI 3.1) in the parse layer
* support `const` (OpenAPI 3.1) with exact-equality value validation
* support `contentSchema` (OpenAPI 3.1) in the parse layer
* coerce String values into array-form `type` (3.1) when `coerce_value` is on, so params like `type: [integer, "null"]` accept `"5"`

## 2.3.1 (2025-11-14)
* add optional date coercion with behavior matching existing datetime coercion

## 2.3.0 (2025-10-01)
* bump base64 dep
* bump actions checkout dep
* improvements for additionalProperties validation #187

## 2.2.6 (2025-04-07)
* support validator options and allow_empty_date_and_datetime for response validate options #183

## 2.2.5 (2025-04-05)
* add allow_empty_date_and_datetime option for more lenient format parsing #182

## 2.2.4 (2025-02-27)
* skip validation if format is set to `binary` #180

## 2.2.3 (2024-12-12)
* fix parent_discriminator_schema nil from all_of_validator #179

## 2.2.2 (2024-11-21)
* make content-type lookup case-insensitive #178

## 2.2.1 (2024-10-23)
* revert schemas validation in additionalProperties and remove additionalProperties logic from allof (breaking things for me, will revisit)

## 2.2.0 (2024-10-23)
### Fixed
* support schemas validation in additionalProperties and remove additionalProperties logic from allof
* suppress method redefined warning
* add base64 dev dependency for ruby-head compatibility
* remove no longer needed activesupport dev dep thanks to a fix upstream
* add dependabot config
* remove no longer used code for old rubies
* bump actions/checkout
* add ruby 3.3 to test matrix
* fix uuid validation logic (make it more strict)

## 2.1.0 (2024-04-03)
### Fixed
* Add full-date compliant date format validation #164

## 2.0.0 (2023-10-15)

### Added

* Support for uniqueItems in array #154
* Fix nullable field does not work with allOf, anyOf and oneOf keyword #128

### Other

* Drop Ruby 2.6 Support #158

## 1.0.0 (2021-02-03)
### Added
* Add date-time format validation #126

## 1.0.0.beta1 (2021-12-15)
### Added
* Add strict_reference_validation config and implementation to address/implement #29 #123

## 0.15.0 (2021-09-27)
### Added
* support: relative file path escape. #117

## 0.14.1 (2021-07-9)
### Fixed
* Fix bug for using path parameter and coerce option #115

## 0.14.0 (2021-05-24)

### Added
* Add basic polymorphism handling #103
* Support empty schema as any type #109
* Add date format validation for string #102

### Fixed
* Fix anyOf coercion to float and integer when value is a non-string type #110

## 0.13.0 (2021-05-01)
* Fix a problem with remote reference to path items which have path parameters #95
* Support enum for booleans. #104

## 0.12.1 (2020-08-27)
* Use CGI.unescape (warning fix) #92

## 0.12.0 (2020-08-26)
* Find path by extracted params than path length #84
* Unescape ref URI before lookup in OpenAPIParser::Findable #85
* Improved path parameter matching code to allow file extensions, multiple parameters inside one path element, etc #90

## 0.11.2 (2020-05-23)
* Allow date and time content in YAML #81

## 0.11.1 (2020-05-09)
* fix too many warning

## 0.11.0 (2020-05-09)
* Add committee friendly interface to use remote references. #74
* Prevent SystemStackError on recursive schema reference #76
* support newest ruby versions #78

## 0.10.0 (2020-04-01)
* Support $ref to objects in other OpenAPI yaml files #66
* Allow $ref for path item objects #71

## 0.9.0 (2020-03-22)
* Added support for validating UUID formatted strings #67

## 0.8.0 (2020-01-21)
* Append the example to the Pattern validator error message #64

## 0.7.0 (2020-01-15)
* Avoid potential `.send(:exit)` #58
* Improve PathItemFinder #44

## 0.6.1 (2019-10-12)
* Bugfix: validate non-nullable response header #54
* Improve grammar in error messages #55
* fix object validator in case of properties missing #56

## 0.6.0 (2019-10-05)
* add email format validation on string #51

## 0.5.0 (2019-09-28)
* Add max and min length validators for string. #45
* Support for minItems and maxItems in array #49

## 0.4.1 (2019-07-27)
* release missed

## 0.4.0 (2019-07-27)
* Add minimum and maximum checks for `integer` and `number` data types (#43)

## 0.3.1 (2019-06-04)
* Add additionalProperties default value (#40)

## 0.3.0 (2019-06-01)

### features
* Perform a strict check on object properties (#33)

### Bugfix
* Support discriminator without mapping (#35)
* Fix upper case request param validation (#38)

## 0.2.7 (2019-05-20)
* Fix for release miss

## 0.2.6 (2019-05-20)
* Add support for discriminator (#32)

## 0.2.5 (2019-04-12)
* Support one of validator (#26)

## 0.2.3 (2019-03-18)
* validate_header_parameter support case incentive (#25)

## 0.2.2 (2019-01-06)
* bugfix for datetime validate (#20)

## 0.2.1 (2019-01-03)
* raise error when invalid datetime format (#19)

## 0.2.0 (2019-01-02)
* support header validate (#18)

## 0.1.9 (2019-01-01)
* add strict option (#17)

## 0.1.8 (2018-12-31)
* add select_media_type method(#16)

## 0.1.7 (2018-12-30)
* Float value validate bugfix (#15)

## 0.1.6 (2018-12-29)
* Support allOf definition (#11)
* Support wildcard status code (#12)
* Support wildcard content type (#13)

## 0.1.5 (2018-12-23)
* First release for production usage
