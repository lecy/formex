# formex 0.0.0.9000

* Initial extraction from `datagoodr` (at tag `v0.1.0-monolith`).
* Detector families: address, codes, color, currency, datetime, geography,
  government IDs, hashes, phone, research/scholarly IDs, science/bio IDs, web.
* `guess_data_type()` / `score_data_type()` — the dispatchable detection entry
  point, backed by a data-type registry and the type/class/subclass ontology.
* AutoType test-case generation and detector benchmarking
  (`generate_autotype_test_cases()`, `build_autotype_results()`).
* `as_*` format helpers and the *formex* format-expression syntax.
* Bundled data: `data_type_tests` (frozen detector fixture) and internal
  geography/code lookups; regenerate via `data-raw/build_lookups.R` and
  `data-raw/build_test_cases.R`.
