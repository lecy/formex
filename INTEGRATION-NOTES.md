# datagoodr ← formex integration notes

Changes to make in **datagoodr** once `formex` is published (Phase 1), against
tag `v0.1.0-monolith`:

## Remove from datagoodr `R/`
Delete these files — they now live in `formex`:
- `dt-address.R`, `dt-codes.R`, `dt-color.R`, `dt-currency.R`, `dt-datetime.R`,
  `dt-geography.R`, `dt-gov.R`, `dt-hash.R`, `dt-phone.R`, `dt-research-id.R`,
  `dt-scibio.R`, `dt-web.R`
- `00-autotype-functions.R`, `00-data-type-registry.R`,
  `00-data-type-ontology.R`, `00-dt-helpers.R`, `00-checksum-helpers.R`
- `02-01-guess-data-type.R`, `02-01-format-functions.R`
- `00-data.R` (documents `data_type_tests`, now a formex dataset)

## Split `R/sysdata.rda`
Currently 13 objects. Keep only the 6 `layout.*` tables; the 7 lookups
(`.us_cities`, `.state_fips`, `.iso3166_alpha2`, `.cbsa`, `.csa`,
`.metro_area_names`, `.naics`) move to formex. Regenerate datagoodr's
`sysdata.rda` from just the layout builders.

## Move out of datagoodr
- `data/data_type_tests.rda` (formex owns it)
- `data-raw/build_lookups.R`, `build_test_cases.R`, `datatypes/`, and the raw
  NAICS/CBSA Excel files
- `data-types/` tree
- vignettes: `data-type-detectors.Rmd`, `data-type-ontology.Rmd`, `formex.Rmd`,
  `guess-data-type.Rmd`
- tests: `test-detectors.R`, `test-detector-additions.R`, `test-currency.R`,
  `test-ontology-conformance.R`

## Keep in datagoodr (the seam)
- `detect_temporal()` / `detect_identifier()` stay — base-pass pre-checks in the
  stats/DGF layer. They are NOT in formex.
- `01-06-guess-dgf-types.R` becomes the adapter: it calls `formex::guess_data_type()`.
- `wrap_preview()` (in `03-00-BUILD-RG-DICT.R`) stays — `test-formatting.R` stays.

## DESCRIPTION
Add `formex` to `Imports:`. The functions datagoodr actually calls across the
seam: `guess_data_type()`, `as_mm()`, `as_EIN()`, and the autotype test helpers
(`generate_autotype_test_cases()`, `build_autotype_results()`,
`generate_autotype_report()`). Qualify these as `formex::` (exported) or import
them; drop any `datagoodr:::` references to the moved internals.

## Verify
`test-guess-dgf-types.R`, `test-temporal.R`, `test-identifier.R` remain in
datagoodr and now exercise formex through the import — they are the integration
check that the seam is wired correctly.
