##############################
### Data type family: tolerant date / timestamp
###############################
## is_date() recognizes a calendar date or timestamp in essentially any
## plausible written form, by trying a LIBRARY of strptime formats rather than
## one regex per canonical shape. A value is a date if some format parses it to
## a valid in-range date AND the parse round-trips (so partial/garbage matches
## are rejected). Delimiter, padding and case damage are absorbed by (a) the
## library's delimiter variants and (b) a normalized round-trip comparison; the
## ISO `T` separator, Zulu `Z`, numeric offsets, fractional seconds, weekday
## prefixes and named time zones are folded to one shape in normalization.
##
## The format library is the detector's REACH -- what it cannot parse, it is
## not. It is generated once at load from the date "genome" (order x month
## style x year x delimiter), see dev/date_genome_design.md.

## order x month-style x year x delimiter cores
#' @keywords internal
#' @noRd
.date_cores <- function(){
  delim  <- c("-","/",".","_"," ","")
  orders <- list(YMD=c("Y","m","d"), DMY=c("d","m","Y"),
                 MDY=c("m","d","Y"), YDM=c("Y","d","m"))
  msty   <- c("%m","%b","%B")
  out <- character(0)
  for(ord in orders) for(ms in msty) for(yy in c("%Y","%y")){
    toks <- vapply(ord, function(e) switch(e, Y=yy, m=ms, d="%d"), "")
    for(dl in delim) out <- c(out, paste(toks, collapse=dl))
  }
  out <- c(out, "%b %d, %Y", "%B %d, %Y")
  unique(out)
}

## generated ONCE at load (a few hundred small strings)
#' @keywords internal
#' @noRd
.DATE_FORMATS <- local({
  cores <- .date_cores()
  times <- c("", " %H:%M", " %H:%M:%S", " %I:%M %p", " %I:%M:%S %p")
  as.vector(outer(cores, times, paste0))
})

## fold weekday prefix, ordinal day, fractional seconds, ISO T, Zulu Z, numeric
## offset and named tz to a canonical space-joined shape
#' @keywords internal
#' @noRd
.date_norm_input <- function(x){
  x <- trimws(as.character(x))
  x <- sub("^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*,?\\s+", "", x, ignore.case = TRUE)
  x <- sub(", (?=[0-9]{1,2}:[0-9]{2})", " ", x, perl = TRUE)   # "date, HH:MM" datetime join -> space (keeps "Mar 5, 2020")
  x <- gsub("([0-9]{1,2})(st|nd|rd|th)\\b", "\\1", x, ignore.case = TRUE)
  x <- sub("(:[0-9]{2})\\.[0-9]+", "\\1", x)
  x <- gsub("([0-9])T([0-9])", "\\1 \\2", x)
  x <- sub("(:[0-9]{2})\\s*[+-][0-9]{2}:?[0-9]{2}\\s*$", "\\1", x)
  x <- sub("([0-9Mm])Z\\s*$", "\\1", x)
  x <- sub("\\s+(UTC|GMT|[A-Z]{2,4})\\s*$", "", x)
  gsub("\\s+", " ", x)
}
## case-, space- and zero-pad-insensitive comparison key
#' @keywords internal
#' @noRd
.date_norm_cmp <- function(x){
  x <- gsub("(?<![0-9])0(?=[0-9])", "", x, perl = TRUE)
  gsub("[[:space:]]", "", tolower(x))
}

#' Is it a date or timestamp?
#'
#' A tolerant detector: recognizes a calendar date or datetime in essentially
#' any plausible written form (ISO, US, European, named-month, with or without
#' time, 12/24-hour, `T`-separated, offsets, fractional seconds, weekday
#' prefixes) by trying a library of `strptime` formats. Non-dates -- counts,
#' ZIPs, phones, ids, free text -- are rejected by the in-range + round-trip
#' guard.
#'
#' @param x A character vector.
#' @param min_year,max_year Plausible calendar-year window (default 1900-2100).
#' @return Logical vector; `TRUE` for a parseable in-range date/timestamp.
#' @examples
#' is_date(c("2016-03-15", "05/Mar/2016", "March 5, 2016 2:00 PM",
#'           "20160305T14:00:00Z", "banana", "12345"))
#' @family datetime detectors
#' @export
is_date <- function(x, min_year = 1900, max_year = 2100){
  x0 <- .date_norm_input(x)
  parsed <- rep(FALSE, length(x))
  live <- !is.na(x0) & nzchar(x0)
  for(f in .DATE_FORMATS){
    todo <- which(live & !parsed); if(!length(todo)) break
    p <- suppressWarnings(strptime(x0[todo], f, tz = "UTC"))
    ok <- which(!is.na(p$year))
    if(!length(ok)) next
    yr <- p$year[ok] + 1900
    good <- ok[yr >= min_year & yr <= max_year]
    if(!length(good)) next
    keep <- which(.date_norm_cmp(format(p[good], f)) == .date_norm_cmp(x0[todo][good]))
    if(length(keep)) parsed[todo[good][keep]] <- TRUE
  }
  out <- parsed
  out[is.na(x)] <- NA
  out
}
