##############################
### Variable-name lexicon (header -> ontology class)
###############################
## The value detectors (R/dt-*.R) reach a class only when the VALUES carry a
## signature. A large part of the ontology is metadata-gated: a column of bare
## doubles could be a weight, a rate, an estimate, a standard error -- identical
## as values, separable only by the variable NAME. This lexicon is the name-side
## complement: an ordered set of rules mapping header keywords/patterns to an
## ontology (data_type, data_subtype, data_class) triple, consumed by
## classify_by_name() and reconciled with the value guess by guess_column().
##
## Each rule: list(id, pat, coords = c(type, subtype, class), conf).
##  * `pat` is matched (case-insensitively, word-boundaried) against the
##    NORMALIZED header -- camelCase split, separators collapsed to spaces
##    (see .tokenize_name()), so write patterns against the spaced form
##    ("std err", not "std_err") and add glued variants ("stderr") explicitly.
##  * `conf` is a base confidence in [0,1]; the most confident matching rule
##    wins, ties broken by list order (so put more specific rules first).
##  * every `coords` triple MUST be a row in the ontology catalog (enforced by
##    test-name-lexicon.R); the class need not have a value detector.
##
## This is a PROTOTYPE lexicon: broad enough to be useful, deliberately small
## and legible. Extend by adding rules; keep the specific-before-general order.


#' @keywords internal
#' @noRd
.name_lexicon <- list(
  ## --- strong domain identifiers (also value-detectable; name reinforces) ----
  list(id = "email",   pat = "\\b(email|e ?mail)\\b",                  coords = c("text", "token", "email"),          conf = 0.85),
  list(id = "url",     pat = "\\b(url|uri|link|website|homepage)\\b",  coords = c("text", "token", "url"),            conf = 0.80),
  list(id = "phone",   pat = "\\b(phone|telephone|tel|mobile|cell|fax)\\b", coords = c("text", "token", "phone"),     conf = 0.80),
  list(id = "admin_id",pat = "\\b(ssn|ein|npi|doi|orcid|isbn|issn|duns|uei|dea)\\b", coords = c("identifier", "text_id", "administrative_id"), conf = 0.90),
  list(id = "record_id", pat = "(^| )id$|\\b(identifier|uuid|guid|rowid|row id|primary key)\\b", coords = c("identifier", "text_id", "record_id"), conf = 0.72),

  ## --- boolean roles ---------------------------------------------------------
  list(id = "eligibility", pat = "\\b(eligible|eligibility|qualif\\w*)\\b",      coords = c("boolean", "binary", "eligibility"), conf = 0.78),
  list(id = "response",    pat = "\\b(response|responded|consent\\w*|agree\\w*|answered)\\b", coords = c("boolean", "binary", "response"), conf = 0.66),
  list(id = "presence",    pat = "\\b(present|presence|exists|has)\\b",          coords = c("boolean", "binary", "presence"),    conf = 0.60),
  list(id = "indicator",   pat = "^(is|has|had|was|does|do|can|should|will) |\\b(flag|flg|indicator|dummy|binary|bool|boolean|yn)\\b", coords = c("boolean", "binary", "indicator"), conf = 0.80),
  list(id = "status",      pat = "\\b(status|active|inactive|enabled|disabled)\\b", coords = c("boolean", "binary", "status"),   conf = 0.55),

  ## --- numeric semantic classes (the core metadata-gated gap) ----------------
  list(id = "standard_error",     pat = "\\b(se|stderr|std err|standard error)\\b",         coords = c("number", "continuous", "standard_error"),     conf = 0.80),
  list(id = "standardized_score", pat = "\\b(z score|zscore|t score|tscore|std score|standardized)\\b", coords = c("number", "continuous", "standardized_score"), conf = 0.82),
  list(id = "coefficient",        pat = "\\b(coef\\w*|beta|slope|elasticity)\\b",           coords = c("number", "continuous", "coefficient"),        conf = 0.70),
  list(id = "weight",             pat = "\\b(wt|wgt|weight|pweight|aweight|fweight)\\b",     coords = c("number", "continuous", "weight"),             conf = 0.72),
  list(id = "percentile",         pat = "\\b(pctile|percentile|quantile|decile|quartile)\\b", coords = c("number", "continuous", "percentile"),       conf = 0.80),
  list(id = "probability",        pat = "\\b(prob\\w*|likelihood|pval\\w*|p value)\\b",      coords = c("number", "continuous", "probability"),        conf = 0.68),
  list(id = "growth_rate",        pat = "\\b(growth|cagr|yoy|mom|pct change|percent change)\\b", coords = c("number", "continuous", "growth_rate"),    conf = 0.72),
  list(id = "rate",               pat = "\\b(rate|per capita|percapita|incidence|prevalence|mortality)\\b", coords = c("number", "continuous", "rate"), conf = 0.68),
  list(id = "ratio",              pat = "\\b(ratio|odds)\\b",                                coords = c("number", "continuous", "ratio"),              conf = 0.70),
  list(id = "proportion",         pat = "\\b(prop|proportion|share|fraction|pct|percent|percentage)\\b", coords = c("number", "continuous", "proportion"), conf = 0.62),
  list(id = "estimate",           pat = "\\b(est|estimate\\w*|predicted|prediction|fitted|yhat)\\b", coords = c("number", "continuous", "estimate"),    conf = 0.60),
  list(id = "difference",         pat = "\\b(diff\\w*|delta|change|gap|net change)\\b",      coords = c("number", "continuous", "difference"),         conf = 0.58),
  list(id = "balance",            pat = "\\b(balance|net worth|assets|liabilities)\\b",      coords = c("number", "continuous", "balance"),            conf = 0.70),
  list(id = "currency",           pat = "\\b(amount|amt|cost|price|revenue|income|salary|wage|wages|earnings|expense|expenditure|budget|usd|eur|gbp|dollars?|payment|fee|funding)\\b", coords = c("number", "continuous", "currency"), conf = 0.65),
  list(id = "coordinate",         pat = "\\b(lat|latitude|lon|lng|longitude|easting|northing|x coord|y coord)\\b", coords = c("number", "continuous", "coordinate"), conf = 0.80),
  list(id = "index",              pat = "\\b(index|idx)\\b",                                 coords = c("number", "continuous", "index"),              conf = 0.55),
  list(id = "duration",           pat = "\\b(duration|elapsed|tenure|age|los|length of stay|time spent)\\b", coords = c("number", "continuous", "duration"), conf = 0.62),
  list(id = "measurement",        pat = "\\b(height|length|width|depth|temperature|temp|mass|volume|distance|km|cm|mm|kg)\\b", coords = c("number", "continuous", "measurement"), conf = 0.58),

  ## --- discrete numbers ------------------------------------------------------
  list(id = "frequency", pat = "\\b(freq|frequency)\\b",                 coords = c("number", "discrete", "frequency"), conf = 0.70),
  list(id = "rank",      pat = "\\b(rank\\w*|position|placement)\\b",    coords = c("number", "discrete", "rank"),      conf = 0.70),
  list(id = "score",     pat = "\\b(score|pts|points)\\b",              coords = c("number", "discrete", "score"),     conf = 0.62),
  list(id = "count",     pat = "\\b(count|cnt|tally|num|number of)\\b|^n ", coords = c("number", "discrete", "count"),  conf = 0.66),

  ## --- ordinal / nominal categorical ----------------------------------------
  list(id = "likert",      pat = "\\b(likert|satisfaction)\\b",         coords = c("categorical", "ordinal", "likert"),      conf = 0.72),
  list(id = "grade_level", pat = "\\b(grade|grade level|class year)\\b", coords = c("categorical", "ordinal", "grade_level"), conf = 0.66),
  list(id = "rating",      pat = "\\b(rating|stars)\\b",                coords = c("categorical", "ordinal", "rating"),      conf = 0.68),
  list(id = "missingness", pat = "\\b(missingness|nonresponse reason|reason missing|refused)\\b", coords = c("categorical", "nominal", "missingness_reason"), conf = 0.72),
  list(id = "group",       pat = "\\b(group|grp|arm|cohort|treatment|condition|segment|category|cat)\\b", coords = c("categorical", "nominal", "group"), conf = 0.55),
  list(id = "geography",   pat = "\\b(state|county|city|zip|zipcode|country|region|fips|cbsa|tract|census)\\b", coords = c("categorical", "nominal", "geography"), conf = 0.68),

  ## --- temporal --------------------------------------------------------------
  list(id = "quarter",          pat = "\\b(quarter|qtr|q[1-4])\\b",             coords = c("temporal", "period", "quarter"),          conf = 0.70),
  list(id = "year",             pat = "\\b(year|yr|fy|fiscal year|vintage)\\b", coords = c("temporal", "period", "year"),             conf = 0.68),
  list(id = "reporting_period", pat = "\\b(period|reporting period|fiscal period|as of|snapshot)\\b", coords = c("temporal", "period", "reporting_period"), conf = 0.58),
  list(id = "calendar_date",    pat = "\\b(date|dob|dt|timestamp|datetime)\\b", coords = c("temporal", "point", "calendar_date"),     conf = 0.60),

  ## --- text ------------------------------------------------------------------
  list(id = "person_name",  pat = "\\b(name|fname|lname|first name|last name|surname|full name)\\b", coords = c("text", "line", "person_name"), conf = 0.58),
  list(id = "org_name",     pat = "\\b(company|employer|organization|org name|firm|agency|institution)\\b", coords = c("text", "line", "organization_name"), conf = 0.62),
  list(id = "address",      pat = "\\b(address|addr|street|mailing)\\b",   coords = c("text", "line", "address"),  conf = 0.66),
  list(id = "title",        pat = "\\b(title|headline|subject line)\\b",   coords = c("text", "line", "title"),    conf = 0.55),
  list(id = "long_text",    pat = "\\b(comment|comments|note|notes|description|remarks|feedback|narrative|abstract)\\b", coords = c("text", "block", "long_text"), conf = 0.60)
)
