# Build a banked test case from a column

Profiles a column, computes its signature and candidate shortlist, and
writes a self-describing JSON test case (values, profile, label,
difficulty) to the bank directory. These cases are the replayable
substrate for router training and regression testing.

## Usage

``` r
fx_make_test_case(
  x,
  case_number,
  data_type = NA_character_,
  semantic_family = NA_character_,
  semantic_type = NA_character_,
  semantic_type_id = NA_character_,
  variant_id = NA_character_,
  depth_labeled = NA_integer_,
  label_confidence = NA_character_,
  label_method = "unlabeled",
  reviewer = NA_character_,
  relabeled = FALSE,
  relabel_reason = NA_character_,
  label_notes = NA_character_,
  difficulty = NA_character_,
  difficulty_rationale = NA_character_,
  noise_markers = character(0),
  corpus = "manual",
  corpus_version = NA_character_,
  original_header = NA_character_,
  original_label = NA_character_,
  table_id = NA_character_,
  parent_case_id = NA_character_,
  ontology = NULL,
  ontology_version = NA_character_,
  ontology_status = "in_ontology",
  proposed_parent = NA_character_,
  detector_exists = TRUE,
  hard_negative_for = character(0),
  order_is_signal = FALSE,
  mutations_allowed = character(0),
  mutations_forbidden = character(0),
  mutation_target = NA_character_,
  outdir = ".",
  n_candidates = 8
)
```

## Arguments

- x:

  A column (coerced to character).

- case_number:

  Integer index used to mint the case id.

- data_type, semantic_family, semantic_type, semantic_type_id,
  variant_id, depth_labeled:

  Ontology label fields (a later labelling pass may overwrite them).

- label_confidence, label_method, reviewer, relabeled, relabel_reason,
  label_notes:

  Labelling provenance for the case's ground truth.

- difficulty, difficulty_rationale, noise_markers:

  Difficulty annotation (`difficulty` is one of `"easy"`, `"medium"`,
  `"hard"`, or `NA`).

- corpus, corpus_version, original_header, original_label, table_id,
  parent_case_id:

  Source-corpus provenance recorded with the case.

- ontology, ontology_version, ontology_status, proposed_parent,
  detector_exists, hard_negative_for:

  Ontology binding: the ontology to validate the label against, its
  version and status, and whether a detector exists for the labelled
  type.

- order_is_signal, mutations_allowed, mutations_forbidden,
  mutation_target:

  Mutation contract governing how the case may be perturbed for
  training.

- outdir:

  Directory the JSON case is written to.

- n_candidates:

  Number of signature-distance candidates to store.

## Value

Invisibly, a list with the written `path` and the case `obj`.

## See also

[`fx_index_bank()`](https://lecy.github.io/formex/reference/fx_index_bank.md),
[`fx_bank_coverage()`](https://lecy.github.io/formex/reference/fx_bank_coverage.md)
