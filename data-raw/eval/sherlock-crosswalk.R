## data-raw/eval/sherlock-crosswalk.R
## -------------------------------------------------------------------------
## Crosswalk: Sherlock / VizNet 78 semantic types (from the T2Dv2 Gold Standard
## DBpedia properties; see Hulsebos et al., KDD 2019, Table 7) -> formex
## (data_type, data_subtype, data_class). Consumed by run-sherlock-eval.R and by
## evaluate_columns(crosswalk = sherlock_crosswalk()).
##
## data_class = NA marks a Sherlock type with NO clean formex home (out of scope
## for this eval). Every non-NA (type, subtype, class) triple is a real row in
## data-types/research_data_type_ontology.csv.
##
## The mapping is JUDGMENT, not ground truth -- several Sherlock types are
## polysemous (see `note`). Two deliberate honesty calls worth flagging:
##   * "weight" is PHYSICAL weight in Sherlock (boxers, horses) -> measurement,
##     NOT formex's statistical sampling `weight` class. The eval will therefore
##     "miss" weight columns; that surfaces a real name-vs-value ontology tension
##     rather than a detector bug.
##   * "status"/"result"/"gender"/"sex" are multi-valued categoricals in the data
##     -> categorical/nominal/category, even though a header like "status" would
##     trip the boolean/binary/status name rule. Edit freely to explore.
## -------------------------------------------------------------------------

sherlock_crosswalk <- function() {
  r <- function(source_label, data_type, data_subtype, data_class, note = "") {
    data.frame(source_label = source_label, data_type = data_type,
               data_subtype = data_subtype, data_class = data_class,
               note = note, stringsAsFactors = FALSE)
  }
  rbind(
    # --- cleanly value-detectable by formex today -----------------------------
    r("address",     "text",        "line",    "address"),
    r("birth date",  "temporal",    "point",   "calendar_date"),
    r("city",        "categorical", "nominal", "geography"),
    r("country",     "categorical", "nominal", "geography"),
    r("county",      "categorical", "nominal", "geography"),
    r("state",       "categorical", "nominal", "geography"),
    r("continent",   "categorical", "nominal", "geography"),
    r("region",      "categorical", "nominal", "geography"),
    r("location",    "categorical", "nominal", "geography"),
    r("birth place", "categorical", "nominal", "geography"),
    r("origin",      "categorical", "nominal", "geography"),
    r("nationality", "categorical", "nominal", "geography", "or category"),
    r("currency",    "number",      "continuous", "currency"),
    r("isbn",        "identifier",  "numeric_id", "administrative_id"),
    r("year",        "temporal",    "period",  "year"),
    r("day",         "temporal",    "phase",   "day_of_week", "sometimes day-of-month"),

    # --- reachable only via the NAME side (metadata-gated by value) ------------
    r("age",         "number",      "continuous", "duration"),
    r("duration",    "number",      "continuous", "duration"),
    r("weight",      "number",      "continuous", "measurement", "physical, not sampling weight"),
    r("area",        "number",      "continuous", "measurement"),
    r("depth",       "number",      "continuous", "measurement"),
    r("elevation",   "number",      "continuous", "measurement"),
    r("capacity",    "number",      "continuous", "measurement"),
    r("file size",   "number",      "continuous", "measurement"),
    r("range",       "number",      "range",      "numeric_range"),
    r("rank",        "number",      "discrete",   "rank"),
    r("ranking",     "number",      "discrete",   "rank"),
    r("plays",       "number",      "discrete",   "count"),
    r("sales",       "number",      "continuous", "currency", "or count"),
    r("credit",      "text",        "line",       "person_name", "film credits"),

    # --- names / organizations / titles ---------------------------------------
    r("name",         "text", "line", "person_name"),
    r("person",       "text", "line", "person_name"),
    r("artist",       "text", "line", "person_name"),
    r("director",     "text", "line", "person_name"),
    r("creator",      "text", "line", "person_name"),
    r("jockey",       "text", "line", "person_name"),
    r("owner",        "text", "line", "person_name", "or organization"),
    r("affiliate",    "text", "line", "organization_name"),
    r("affiliation",  "text", "line", "organization_name"),
    r("club",         "text", "line", "organization_name"),
    r("company",      "text", "line", "organization_name"),
    r("manufacturer", "text", "line", "organization_name"),
    r("operator",     "text", "line", "organization_name"),
    r("organisation", "text", "line", "organization_name"),
    r("publisher",    "text", "line", "organization_name"),
    r("team",         "text", "line", "organization_name"),
    r("team name",    "text", "line", "organization_name"),
    r("album",        "text", "line", "title"),
    r("collection",   "text", "line", "title"),
    r("product",      "text", "line", "title", "or category"),

    # --- free text ------------------------------------------------------------
    r("description",  "text", "block", "long_text"),
    r("notes",        "text", "block", "long_text"),
    r("requirement",  "text", "block", "long_text"),
    r("command",      "text", "token", "label"),
    r("symbol",       "text", "token", "label", "ticker/abbrev"),

    # --- categoricals / ordinals ----------------------------------------------
    r("category",       "categorical", "nominal", "category"),
    r("class",          "categorical", "nominal", "category"),
    r("classification", "categorical", "nominal", "category", "or classification_code"),
    r("code",           "categorical", "nominal", "category", "or classification_code"),
    r("component",      "categorical", "nominal", "category"),
    r("brand",          "categorical", "nominal", "category"),
    r("format",         "categorical", "nominal", "category"),
    r("genre",          "categorical", "nominal", "category"),
    r("industry",       "categorical", "nominal", "category"),
    r("language",       "categorical", "nominal", "category"),
    r("family",         "categorical", "nominal", "category", "taxonomic"),
    r("order",          "categorical", "nominal", "category", "taxonomic or rank"),
    r("species",        "categorical", "nominal", "category"),
    r("service",        "categorical", "nominal", "category"),
    r("type",           "categorical", "nominal", "category"),
    r("position",       "categorical", "nominal", "category", "role or rank"),
    r("gender",         "categorical", "nominal", "category", "header trips boolean/status"),
    r("sex",            "categorical", "nominal", "category"),
    r("result",         "categorical", "nominal", "category", "or boolean"),
    r("status",         "categorical", "nominal", "category", "or boolean/status"),
    r("education",      "categorical", "ordinal", "grade_level", "or category"),
    r("grades",         "categorical", "ordinal", "grade_level"),
    r("religion",       "categorical", "nominal", "category")
  )
}
