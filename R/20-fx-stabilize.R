## ===========================================================================
## 20-fx-stabilize.R  --  execute an ontology recipe: raw values -> stable form
##
## fx_stabilize() is the transformation half of the engine (guess_data_type() is
## the classification half). Given a semantic_type (+ optional format_label) it
## resolves the ontology RECIPE row and runs its raw_to_stable_transform DSL,
## returning the format mask, the stabilized values, the stable format, and the
## import rule -- i.e. the four things the row's recipe columns declare.
##
## The DSL (in raw_to_stable_transform) is a small grammar:
##   {{ verb }}           a single verb            e.g. {{ as_mmddyyyy }}
##   verb:arg             verb with an argument    e.g. lookup:iso3166
##   [step][step]         a bracketed pipeline     e.g. [strip:$,][dec:.2]
##   verb+verb            a chained pipeline       e.g. split+order
## Each verb dispatches to an R function; confirm-then-transform means the
## normalization (strip a prefix, canonicalize) runs as part of the recipe.
##
## Verbs reuse the package's own detectors (is_email, is_isbn, is_date machinery)
## and lexicons (.first_names, .iso3166_alpha2, ...), so coverage scales with the
## shipped reference data.
## ===========================================================================

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a

## ---- DSL parser -----------------------------------------------------------
.fx_parse_transform <- function(expr){
  e <- trimws(gsub("\\{\\{|\\}\\}", "", expr %||% ""))
  if (!nzchar(e)) return(list())
  steps <- if (grepl("^\\[", e)) gsub("^\\[|\\]$", "", regmatches(e, gregexpr("\\[[^]]+\\]", e))[[1]])
           else if (grepl("\\+", e)) strsplit(e, "\\+")[[1]] else e
  lapply(trimws(steps), function(s){
    if (grepl("\\[", s)) list(verb = sub("\\[.*", "", s), arg = sub("^[^\\[]*\\[|\\]$", "", s))
    else if (grepl(":", s)){ p <- strsplit(s, ":", fixed = TRUE)[[1]]; list(verb = p[1], arg = paste(p[-1], collapse = ":")) }
    else list(verb = s, arg = NA_character_) })
}

## ---- canonical-mapping tables (built once, from package data) --------------
.fx_canon <- function(x) gsub("(^|[ -])([a-z])", "\\1\\U\\2", tolower(trimws(x)), perl = TRUE)
.FX_ISO_NAME2CODE <- c(afghanistan="AF",albania="AL",algeria="DZ",argentina="AR",australia="AU",austria="AT",
 bangladesh="BD",belgium="BE",bolivia="BO",brazil="BR",bulgaria="BG",canada="CA",chile="CL",china="CN",
 colombia="CO","costa rica"="CR",croatia="HR",cuba="CU","czech republic"="CZ",czechia="CZ",denmark="DK",
 "dominican republic"="DO",ecuador="EC",egypt="EG",england="GB",estonia="EE",ethiopia="ET",finland="FI",
 france="FR",germany="DE",ghana="GH",greece="GR","hong kong"="HK",hungary="HU",iceland="IS",india="IN",
 indonesia="ID",iran="IR",iraq="IQ",ireland="IE",israel="IL",italy="IT",jamaica="JM",japan="JP",jordan="JO",
 kenya="KE","south korea"="KR","north korea"="KP",kuwait="KW",latvia="LV",lebanon="LB",lithuania="LT",
 luxembourg="LU",malaysia="MY",mexico="MX",morocco="MA",netherlands="NL","new zealand"="NZ",nigeria="NG",
 norway="NO",pakistan="PK",panama="PA",peru="PE",philippines="PH",poland="PL",portugal="PT",qatar="QA",
 romania="RO",russia="RU","saudi arabia"="SA",scotland="GB",singapore="SG",slovakia="SK",slovenia="SI",
 "south africa"="ZA",spain="ES","sri lanka"="LK",sweden="SE",switzerland="CH",taiwan="TW",thailand="TH",
 turkey="TR",ukraine="UA","united arab emirates"="AE","united kingdom"="GB","united states"="US",
 "united states of america"="US",uruguay="UY",venezuela="VE",vietnam="VN",wales="GB",usa="US",uk="GB",uae="AE")

.fx_cache <- new.env(parent = emptyenv())
.fx_maps <- function(){
  if (!is.null(.fx_cache$maps)) return(.fx_cache$maps)
  get0 <- function(nm) if (exists(nm)) base::get(nm) else character(0)
  usps  <- c(stats::setNames(datasets::state.abb, tolower(datasets::state.name)),
             stats::setNames(datasets::state.abb, tolower(datasets::state.abb)), "dc"="DC","district of columbia"="DC")
  codes <- { z <- get0(".iso3166_alpha2"); stats::setNames(toupper(tolower(z)), tolower(z)) }
  iso   <- c(.FX_ISO_NAME2CODE, codes); iso <- iso[!duplicated(names(iso))]
  first <- get0(".first_names"); last <- get0(".last_names"); city <- get0(".us_cities")
  m <- list(usps = usps, iso3166 = iso,
            given   = stats::setNames(.fx_canon(first), first),
            surname = stats::setNames(.fx_canon(last),  last),
            place   = stats::setNames(.fx_canon(city),  city),
            us_city = stats::setNames(.fx_canon(city),  city))
  .fx_cache$maps <- m; m
}

## ---- verb library ---------------------------------------------------------
.fx_num <- function(x) suppressWarnings(as.numeric(gsub("[^0-9.eE+-]", "", gsub(",", "", x))))
.fx_parse_iso_date <- function(x, with_time = FALSE){
  x0 <- .date_norm_input(x); out <- rep(NA_character_, length(x)); live <- !is.na(x0) & nzchar(x0)
  for (f in .DATE_FORMATS){ todo <- which(live & is.na(out)); if (!length(todo)) break
    p <- suppressWarnings(strptime(x0[todo], f, tz = "UTC")); ok <- which(!is.na(p$year)); if (!length(ok)) next
    keep <- .date_norm_cmp(format(p[ok], f)) == .date_norm_cmp(x0[todo][ok])
    iso <- format(p[ok], if (with_time) "%Y-%m-%dT%H:%M:%S" else "%Y-%m-%d")
    out[todo][ok[keep]] <- iso[keep] }
  out
}
.fx_verbs <- function(){
  if (!is.null(.fx_cache$verbs)) return(.fx_cache$verbs)
  V <- new.env(parent = emptyenv()); A <- function(n, f) assign(n, f, V)
  ## shape / numeric
  A("as_number",    function(x,a){ v<-.fx_num(x); ifelse(is.na(v),NA,as.character(v)) })
  A("as_integer",   function(x,a){ v<-.fx_num(x); ifelse(is.na(v)|v!=round(v),NA,as.character(as.integer(round(v)))) })
  A("as_rank",      function(x,a) get("as_integer",V)(x,a))
  A("as_percent",   function(x,a){ v<-.fx_num(x); ifelse(is.na(v),NA,as.character(v)) })
  A("as_probability",function(x,a){ v<-.fx_num(x); ifelse(is.na(v)|v< -0.001|v>1.001,NA,as.character(v)) })
  A("as_usd",       function(x,a){ v<-suppressWarnings(as.numeric(gsub("[^0-9.\\-]","",gsub(",","",x)))); ifelse(is.na(v),NA,as.character(v)) })
  A("as_euro",      function(x,a) get("as_usd",V)(x,a))
  A("as_currency",  function(x,a) get("as_usd",V)(x,a))
  A("as_coord",     function(x,a){ v<-.fx_num(x); ifelse(is.na(v)|abs(v)>180,NA,as.character(v)) })
  A("as_range",     function(x,a) ifelse(grepl("[0-9].*(-|to|,).*[0-9]", x), trimws(x), NA))
  ## genome / temporal
  A("as_mmddyyyy",  function(x,a) .fx_parse_iso_date(x))
  A("as_datetime",  function(x,a) .fx_parse_iso_date(x, with_time = TRUE))
  A("as_yyyy",      function(x,a) ifelse(grepl("^(1[89]\\d{2}|20\\d{2})$", trimws(x)), trimws(x), NA))
  A("as_yyyymm",    function(x,a){ d<-.fx_parse_iso_date(x); ifelse(is.na(d),NA,substr(d,1,7)) })
  A("as_quarter",   function(x,a){ q<-toupper(gsub("\\s","",x)); ifelse(grepl("^(Q[1-4]-?\\d{4}|\\d{4}-?Q[1-4])$", q), q, NA) })
  A("as_clock",     function(x,a) ifelse(grepl("^\\s*\\d{1,2}:\\d{2}(:\\d{2})?\\s*([AaPp][.]?[Mm][.]?)?\\s*$", x), trimws(x), NA))
  ## mask / identifier
  A("as_email",     function(x,a){ e<-tolower(trimws(x)); ifelse(is_email(e), e, NA) })
  A("as_url",       function(x,a) ifelse(is_url(x) | is_url(paste0("http://",x)), trimws(x), NA))
  A("as_ein",       function(x,a){ d<-gsub("\\D","",x); ifelse(nchar(d)==9, paste0(substr(d,1,2),"-",substr(d,3,9)), NA) })
  A("as_phone",     function(x,a){ d<-gsub("\\D","",x); ifelse(nchar(d)%in%c(10,11), d, NA) })
  A("as_hex",       function(x,a) ifelse(is_hex_color(x), toupper(trimws(x)), NA))
  A("as_id",        function(x,a){ s<-trimws(x); ifelse(nzchar(s), s, NA) })
  A("as_serial",    function(x,a) get("as_id",V)(x,a))
  A("as_handle",    function(x,a){ s<-trimws(x); ifelse(grepl("^@?[A-Za-z0-9_.]{2,}$", s), sub("^@","",s), NA) })
  A("as_isbn",      function(x,a){ s<-trimws(x); s<-sub("\\[[0-9]+\\]\\s*$","",s); s<-sub("^[A-Za-z]{2,}[ :._-]*","",s)
    s<-gsub("[- ]","",s); ifelse(nzchar(s) & suppressWarnings(is_isbn(s)), s, NA) })
  A("as_doi",       function(x,a){ s<-sub("^doi[: ]*","",tolower(trimws(x))); ifelse(suppressWarnings(is_doi(s)), s, NA) })
  A("as_orcid",     function(x,a){ s<-trimws(x); ifelse(suppressWarnings(is_orcid(s)), s, NA) })
  A("as_issn",      function(x,a){ s<-trimws(x); ifelse(suppressWarnings(is_issn(s)), s, NA) })
  ## pipeline operators
  A("strip",        function(x,a){ for(ch in strsplit(a %||% "","")[[1]]) x<-gsub(ch,"",x,fixed=TRUE); x })
  A("dec",          function(x,a){ n<-as.integer(gsub("[^0-9]","",a %||% "2")); v<-.fx_num(x); ifelse(is.na(v),NA,formatC(round(v,n),format="f",digits=n)) })
  A("range",        function(x,a) x)
  A("validate",     function(x,a) x)
  A("zeropad5",     function(x,a){ d<-gsub("\\D","",x); ifelse(nchar(d)>=1 & nchar(d)<=5, sprintf("%05d", suppressWarnings(as.integer(d))), NA) })
  A("lookup",       function(x,a){ m<-.fx_maps()[[a]]; if(is.null(m)) return(rep(NA_character_,length(x))); unname(m[tolower(trimws(x))]) })
  ## categorical / identity
  A("none",         function(x,a){ s<-trimws(x); ifelse(nzchar(s), s, NA) })
  A("as_factor",    function(x,a){ s<-trimws(x); ifelse(nzchar(s), s, NA) })
  A("as_ordered",   function(x,a){ s<-trimws(x); ifelse(nzchar(s), s, NA) })
  A("as_boolean",   function(x,a){ b<-tolower(trimws(x))
    map<-c(yes="TRUE",no="FALSE",y="TRUE",n="FALSE","true"="TRUE","false"="FALSE",t="TRUE",f="FALSE","1"="TRUE","0"="FALSE","on"="TRUE","off"="FALSE")
    unname(map[b]) })
  ## person full name
  A("as_full_name", function(x,a){ m<-.fx_maps(); vapply(x, function(s){
    if(is.na(s)||!nzchar(trimws(s))) return(NA_character_)
    comma <- grepl(",", s, fixed=TRUE); p <- strsplit(trimws(gsub("[.,]"," ",s)), "\\s+")[[1]]; p<-p[nzchar(p)]
    if(length(p)<2 || length(p)>4) return(NA_character_)
    lp<-tolower(p); if(!(any(lp %in% names(m$given)) && any(lp %in% names(m$surname)))) return(NA_character_)
    if(comma) p<-c(p[-1],p[1]); .fx_canon(paste(p,collapse=" ")) }, "") })
  A("split",        function(x,a) get("as_full_name",V)(x,a))
  A("order",        function(x,a) x)
  .fx_cache$verbs <- V; V
}

## ---- executor -------------------------------------------------------------
#' Run an ontology transform-DSL expression on a vector
#'
#' Low-level executor behind [fx_stabilize()]. Parses the recipe grammar
#' (`{{ verb }}`, `verb:arg`, `[step][step]`, `verb+verb`) and applies each verb.
#'
#' @param x A character vector of raw values.
#' @param expr A transform expression from `raw_to_stable_transform`.
#' @return A character vector of stabilized values; `NA` where the recipe cannot
#'   apply. An unimplemented verb yields all-`NA` with an `unimplemented` attribute.
#' @seealso [fx_stabilize()]
#' @export
fx_transform <- function(x, expr){
  x <- as.character(x); steps <- .fx_parse_transform(expr); if (!length(steps)) return(rep(NA_character_, length(x)))
  V <- .fx_verbs()
  for (st in steps){ if (!exists(st$verb, V)) return(structure(rep(NA_character_, length(x)), unimplemented = st$verb))
    x <- tryCatch(get(st$verb, V)(x, st$arg), error = function(e) rep(NA_character_, length(x))) }
  x
}

#' Stabilize a column via its ontology recipe
#'
#' Resolves the recipe row for a `semantic_type` (and optional `format_label`)
#' and runs its `raw_to_stable_transform`, returning the recipe's four outputs.
#'
#' @param x A character vector (one column of raw values).
#' @param semantic_type The ontology leaf, e.g. `"calendar"`, `"administrative"`.
#' @param format_label Optional variant within the type, e.g. `"isbn"`. If `NULL`
#'   the first variant of the semantic_type is used.
#' @param ontology An ontology data frame (defaults to [fx_ontology()]).
#' @return A list: `variant_id`, `format_mask` (recognition pattern, from
#'   `data_format`), `stable` (the transformed values), `stable_format` (canonical
#'   target), and `import_rule` (how to re-ingest, from `stable_import_rule`).
#' @examples
#' fx_stabilize(c("03/15/2019", "12/31/2020"), "calendar")
#' fx_stabilize(c("isbn 0395629764"), "administrative", "isbn")
#' fx_stabilize(c("California", "TX"), "geographic", "us_state")
#' @seealso [fx_transform()], [guess_data_type()]
#' @export
fx_stabilize <- function(x, semantic_type, format_label = NULL, ontology = fx_ontology()){
  rows <- ontology[ontology$semantic_type == semantic_type, , drop = FALSE]
  if (!nrow(rows)) stop("unknown semantic_type: ", semantic_type)
  if (!is.null(format_label)){
    rows <- rows[rows$format_label == format_label, , drop = FALSE]
    if (!nrow(rows)) stop("no variant with format_label '", format_label, "' for ", semantic_type)
  }
  r <- rows[1, ]
  list(variant_id    = r$variant_id,
       format_mask   = r$data_format,
       stable        = fx_transform(as.character(x), r$raw_to_stable_transform),
       stable_format = r$stable_format,
       import_rule   = r$stable_import_rule)
}
