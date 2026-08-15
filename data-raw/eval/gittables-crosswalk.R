## data-raw/eval/gittables-crosswalk.R
## -------------------------------------------------------------------------
## Crosswalk: GitTables column-type benchmark DBpedia labels -> formex
## (data_type, data_subtype, data_class). Consumed by run-gittables-eval.R.
##
## Covers the frequent, cleanly-mappable labels (top of the ~122-label
## distribution, which account for the bulk of the 2,533 annotations); rarer or
## genuinely ambiguous labels (parent, dam, source, field, reference, ...) are
## omitted and fall through to NA = out of scope, and are excluded from scoring.
## Every non-NA triple is a real row in research_data_type_ontology.csv.
## -------------------------------------------------------------------------

gittables_crosswalk <- function() {
  r <- function(source_label, data_type, data_subtype, data_class, note = "") {
    data.frame(source_label = source_label, data_type = data_type,
               data_subtype = data_subtype, data_class = data_class,
               note = note, stringsAsFactors = FALSE)
  }
  rbind(
    r("id",          "identifier",  "text_id",    "record_id"),
    r("comment",     "text",        "block",      "long_text"),
    r("note",        "text",        "block",      "long_text"),
    r("notes",       "text",        "block",      "long_text"),
    r("description", "text",        "block",      "long_text"),
    r("name",        "text",        "line",       "person_name"),
    r("author",      "text",        "line",       "person_name"),
    r("title",       "text",        "line",       "title"),
    r("project",     "text",        "line",       "title"),
    r("product",     "text",        "line",       "title"),
    r("publication", "text",        "line",       "title"),
    r("team",        "text",        "line",       "organization_name"),
    r("type",        "categorical", "nominal",    "category"),
    r("status",      "categorical", "nominal",    "category", "or boolean/status"),
    r("class",       "categorical", "nominal",    "category"),
    r("species",     "categorical", "nominal",    "category"),
    r("genus",       "categorical", "nominal",    "category"),
    r("code",        "categorical", "nominal",    "category"),
    r("category",    "categorical", "nominal",    "category"),
    r("format",      "categorical", "nominal",    "category"),
    r("language",    "categorical", "nominal",    "category"),
    r("role",        "categorical", "nominal",    "category"),
    r("component",   "categorical", "nominal",    "category"),
    r("orientation", "categorical", "nominal",    "category"),
    r("material",    "categorical", "nominal",    "category"),
    r("rating",      "categorical", "ordinal",    "rating"),
    r("state",       "categorical", "nominal",    "geography", "US state or status"),
    r("city",        "categorical", "nominal",    "geography"),
    r("country",     "categorical", "nominal",    "geography"),
    r("year",        "temporal",    "period",     "year"),
    r("date",        "temporal",    "point",      "calendar_date"),
    r("end date",    "temporal",    "point",      "calendar_date"),
    r("created",     "temporal",    "point",      "timestamp"),
    r("time",        "temporal",    "point",      "time_of_day"),
    r("period",      "temporal",    "period",     "reporting_period"),
    r("rank",        "number",      "discrete",   "rank"),
    r("min",         "number",      "continuous", "decimal", "minimum value"),
    r("value",       "number",      "continuous", "decimal"),
    r("width",       "number",      "continuous", "measurement"),
    r("height",      "number",      "continuous", "measurement"),
    r("depth",       "number",      "continuous", "measurement"),
    r("length",      "number",      "continuous", "measurement"),
    r("volume",      "number",      "continuous", "measurement"),
    r("weight",      "number",      "continuous", "measurement", "physical"),
    r("temperature", "number",      "continuous", "measurement"),
    r("resolution",  "number",      "continuous", "measurement"),
    r("duration",    "number",      "continuous", "duration"),
    r("range",       "number",      "range",      "numeric_range"),
    r("price",       "number",      "continuous", "currency"),
    r("version",     "identifier",  "text_id",    "version_id")
  )
}
