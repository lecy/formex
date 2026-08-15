## ===========================================================================
## fx_extract_features() v2 -- modular, block-gated column feature extraction
##
## Changes from v1:
##   - Restructured into independent block functions sharing one prepared
##     context, so blocks can be computed selectively. At development time run
##     everything; at deployment time run only the blocks your fitted cascade
##     actually references (see fx_feature_manifest()).
##   - NEW blk_charfreq : per-letter and per-digit frequency distributions,
##     including FIRST-letter and FINAL-letter distributions, which carry
##     morphological signal that bag-of-characters discards.
##   - NEW blk_token    : token-level structure, including first/last token
##     stability -- the token analogue of positional punctuation.
##   - NEW blk_lexicon  : pluggable controlled-vocabulary hit rates.
##   - Higher moments (var/skew/kurt) added to punctuation counts.
##
## Every block returns a flat named list of scalars. Missing/inapplicable
## values are NA, never 0.
## ===========================================================================

FEATURE_EXTRACTOR_VERSION <- "2.0"

## ---------------------------------------------------------------------------
## helpers
## ---------------------------------------------------------------------------

wmean  <- function(v, w){ ok <- !is.na(v); if(!any(ok)) return(NA_real_)
                          sum(v[ok]*w[ok])/sum(w[ok]) }
wsd    <- function(v, w){ ok <- !is.na(v); if(sum(ok)<2) return(NA_real_)
                          m <- wmean(v,w); sqrt(sum(w[ok]*(v[ok]-m)^2)/sum(w[ok])) }
wshare <- function(l, w){ ok <- !is.na(l); if(!any(ok)) return(NA_real_)
                          sum(w[ok]*l[ok])/sum(w[ok]) }
wskew  <- function(v, w){ s <- wsd(v,w); if(is.na(s)||s==0) return(NA_real_)
                          wmean(((v-wmean(v,w))/s)^3, w) }
wkurt  <- function(v, w){ s <- wsd(v,w); if(is.na(s)||s==0) return(NA_real_)
                          wmean(((v-wmean(v,w))/s)^4, w) - 3 }
ent    <- function(cts){ p <- cts/sum(cts); p <- p[p>0]; -sum(p*log(p)) }
ent_n  <- function(cts){ k <- sum(cts>0); if(k<2) return(NA_real_); ent(cts)/log(k) }
chi_s  <- function(obs, ep){ n <- sum(obs); if(n==0) return(NA_real_)
                             e <- ep*n; sum((obs-e)^2/e)/n }
kl_div <- function(p, q){ ok <- p>0 & q>0; if(!any(ok)) return(NA_real_)
                          sum(p[ok]*log(p[ok]/q[ok])) }
rxesc  <- function(ch) gsub("([][^$.|?*+(){}\\\\])", "\\\\\\1", ch)
## errors -> NA (a non-computable feature), but do NOT swallow warnings: a real
## warning in a feature block should surface, not vanish as a silent NA.
safe   <- function(e) tryCatch(e, error=function(x) NA_real_)

## English unigram letter frequencies, for divergence scoring
ENGLISH_LETTER_FREQ <- c(
  .0817,.0149,.0278,.0425,.1270,.0223,.0202,.0609,.0697,.0015,.0077,.0403,.0241,
  .0675,.0751,.0193,.0010,.0599,.0633,.0906,.0276,.0098,.0236,.0015,.0197,.0007)
names(ENGLISH_LETTER_FREQ) <- letters

STOPWORDS <- c("the","of","and","a","to","in","for","on","at","by","with","from",
  "as","is","it","or","an","be","this","that","are","was","were","been","has",
  "have","had","not","but","they","we","you","he","she","his","her","its","their",
  "our","all","any","can","will","would","there","which","when","who","what","how",
  "if","no","so","up","out","about","into","over","after","before","than","then")

## ---------------------------------------------------------------------------
## default lexicons -- small, shippable. Extend via the `lexicons` argument;
## each entry becomes lex_<name>_value_rate and lex_<name>_token_rate.
## ---------------------------------------------------------------------------

#' @export
default_lexicons <- function(){
  list(
    ## public-domain person / place gazetteers (see R/dt-name-data.R,
    ## data-raw/gazetteers.R). These carry the person/geographic signal that is
    ## the learned router's strongest discriminator; shipping them here keeps
    ## train and inference features identical.
    first_name    = if (exists(".first_names")) .first_names else character(0),
    last_name     = if (exists(".last_names"))  .last_names  else character(0),
    us_city       = if (exists(".us_cities"))
                      unique(c(.us_cities, tolower(state.name))) else tolower(state.name),
    us_state_name = tolower(state.name),
    us_state_abb  = tolower(state.abb),
    month_name    = tolower(c(month.name, month.abb)),
    day_name      = tolower(c("monday","tuesday","wednesday","thursday","friday",
                              "saturday","sunday","mon","tue","wed","thu","fri","sat","sun")),
    org_suffix    = c("inc","incorporated","corp","corporation","llc","ltd","llp","co",
                      "foundation","trust","fund","assn","association","society","institute",
                      "council","center","centre","church","ministries","alliance","coalition",
                      "network","partnership","university","college","academy","school"),
    street_suffix = c("st","street","ave","avenue","rd","road","blvd","boulevard","ln","lane",
                      "dr","drive","ct","court","pl","place","way","pkwy","parkway","hwy",
                      "highway","ter","terrace","cir","circle","sq","square","apt","suite","ste"),
    honorific     = c("mr","mrs","ms","dr","prof","rev","hon","sr","jr","ii","iii","iv",
                      "phd","md","jd","mba","rn","cpa","esq"),
    direction     = c("north","south","east","west","ne","nw","se","sw","n","s","e","w"),
    unit_token    = c("kg","g","mg","lb","lbs","oz","km","m","cm","mm","mi","ft","in","yd",
                      "l","ml","gal","qt","pt","hr","min","sec","usd","eur","gbp","pct"),
    boolean_word  = c("yes","no","y","n","true","false","t","f","on","off"),
    stopword      = STOPWORDS
  )
}

## ---------------------------------------------------------------------------
## context preparation -- the single pass every block shares
## ---------------------------------------------------------------------------

SENTINEL_NA <- c("", " ", ".", "-", "--", "n/a", "na", "n.a.", "null", "none",
                 "nan", "unknown", "unk", "missing", "not reported", "?", "#n/a")

prep_context <- function( x, max_unique = 20000 ){

  n_total <- length(x)
  is_na   <- is.na(x)
  xs      <- as.character( x[!is_na] ); xs <- xs[!is.na(xs)]

  if( length(xs) && any(grepl("[^\001-\177]", xs, useBytes=TRUE)) ){
    if( all(validUTF8(xs)) ) Encoding(xs) <- "UTF-8"
    else xs <- iconv(xs, from="latin1", to="UTF-8", sub="?")
  }

  sent_hit <- tolower(trimws(xs)) %in% SENTINEL_NA
  pct_sent <- if(length(xs)) mean(sent_hit) else NA_real_
  xv       <- xs[!sent_hit]

  ctx <- list( x_raw = x, n_total = n_total, n_na = sum(is_na),
               pct_missing = if(n_total) mean(is_na) else NA_real_,
               pct_sentinel_na = pct_sent, xs = xs, xv = xv,
               ordered = x[!is_na], ok = length(xv) > 0 )
  if( !ctx$ok ) return(ctx)

  tb <- table(xv)
  ctx$u_all   <- names(tb)
  ctx$w_all   <- as.integer(tb)
  ctx$n_ok    <- length(xv)
  ctx$n_u_all <- length(tb)

  keep <- if( ctx$n_u_all > max_unique ) sample(ctx$n_u_all, max_unique)
          else seq_len(ctx$n_u_all)
  ctx$u  <- ctx$u_all[keep]
  ctx$w  <- ctx$w_all[keep]
  ctx$nu <- length(ctx$u)
  ctx$L  <- nchar(ctx$u)
  ctx$Lz <- pmax(ctx$L, 1)
  ctx$lower <- tolower(ctx$u)
  ctx
}

## ---------------------------------------------------------------------------
## BLOCK: core cardinality  (tier 1 -- always computed)
## ---------------------------------------------------------------------------

blk_core <- function(ctx){
  cnt <- ctx$w_all; N <- ctx$n_ok; nu <- ctx$n_u_all
  cs  <- sort(cnt, decreasing=TRUE)
  H   <- ent(cnt); p <- cnt/N
  list(
    n = ctx$n_total, pct_missing = ctx$pct_missing,
    pct_sentinel_na = ctx$pct_sentinel_na, n_usable = N,
    n_unique = nu, unique_ratio = nu/N, log_n_unique = log1p(nu),
    is_candidate_key = as.integer(nu == N), is_constant = as.integer(nu == 1),
    top1_share = cs[1]/N, top5_share = sum(head(cs,5))/N,
    top1_to_top2 = if(nu>1) cs[1]/cs[2] else NA_real_,
    hapax_ratio = sum(cnt==1)/nu,
    entropy = H, entropy_norm = if(nu>1) H/log(nu) else NA_real_,
    gini_simpson = 1-sum(p^2),
    mean_value_freq = mean(cnt), max_value_freq = max(cnt),
    freq_cv = if(mean(cnt)>0) sd(cnt)/mean(cnt) else NA_real_,
    zipf_slope = if(nu>=10 && max(cnt)>1){
      r <- seq_len(nu); fq <- sort(cnt, decreasing=TRUE)
      safe(unname(coef(lm(log(fq) ~ log(r)))[2])) } else NA_real_,
    zipf_r2 = if(nu>=10 && max(cnt)>1){
      r <- seq_len(nu); fq <- sort(cnt, decreasing=TRUE)
      safe(summary(lm(log(fq) ~ log(r)))$r.squared) } else NA_real_
  )
}

## ---------------------------------------------------------------------------
## BLOCK: sequence / order  (tier 1, but needs the raw ordered vector)
## ---------------------------------------------------------------------------

blk_sequence <- function(ctx){
  xo <- ctx$ordered; no <- length(xo)
  out <- list()
  out$spearman_index <- if(no>=5)
    safe(suppressWarnings(cor(as.numeric(factor(xo)), seq_len(no), method="spearman")))
    else NA_real_
  rl <- rle(as.character(xo))
  out$mean_run_length <- mean(rl$lengths)
  out$max_run_length  <- max(rl$lengths)
  out$run_ratio       <- length(rl$lengths)/no

  v <- suppressWarnings(as.numeric(gsub("[,$ ]", "", as.character(xo))))
  v <- v[!is.na(v)]
  if(length(v) > 5){
    d <- diff(v)
    out$is_monotone_incr <- as.integer(all(d >= 0))
    out$is_monotone_decr <- as.integer(all(d <= 0))
    out$is_autoincrement <- as.integer(all(d == 1))
    out$is_dense_index   <- as.integer(all(v==floor(v)) &&
                              (max(v)-min(v)+1) == length(unique(v)))
    out$diff_constant    <- as.integer(length(unique(d)) == 1)
    out$lag1_autocorr    <- safe(suppressWarnings(cor(v[-length(v)], v[-1])))
    out$pct_diff_zero    <- mean(d == 0)
  } else {
    for(k in c("is_monotone_incr","is_monotone_decr","is_autoincrement",
               "is_dense_index","diff_constant","lag1_autocorr","pct_diff_zero"))
      out[[k]] <- NA_real_
  }
  out
}

## ---------------------------------------------------------------------------
## BLOCK: length / shape  (tier 1)
## ---------------------------------------------------------------------------

blk_length <- function(ctx){
  u <- ctx$u; w <- ctx$w; L <- ctx$L
  lm_ <- wmean(L,w)
  tok <- lengths(strsplit(trimws(u), "\\s+"))
  list(
    len_mean = lm_, len_sd = wsd(L,w),
    len_cv = if(isTRUE(lm_>0)) wsd(L,w)/lm_ else NA_real_,
    len_min = min(L), len_max = max(L), len_range = max(L)-min(L),
    len_skew = wskew(L,w), len_kurt = wkurt(L,w),
    len_median = median(rep(L, pmin(w, 1000))),
    is_fixed_width = as.integer(min(L)==max(L)),
    n_distinct_len = length(unique(L)),
    len_entropy = ent(table(L)), len_entropy_norm = ent_n(table(L)),
    len_top_share = max(tapply(w, L, sum))/sum(w),
    has_leading_zeros = wshare(grepl("^0[0-9]", u), w),
    pct_lead_ws = wshare(grepl("^\\s", u), w),
    pct_trail_ws = wshare(grepl("\\s$", u), w),
    pct_multi_ws = wshare(grepl("\\s{2,}", u), w),
    tok_mean = wmean(tok,w), tok_sd = wsd(tok,w), tok_max = max(tok),
    pct_single_tok = wshare(tok==1, w),
    word_len_mean = if(isTRUE(wmean(tok,w)>0)) lm_/wmean(tok,w) else NA_real_
  )
}

## ---------------------------------------------------------------------------
## BLOCK: character class composition  (tier 1)
## ---------------------------------------------------------------------------

blk_charclass <- function(ctx){
  u <- ctx$u; w <- ctx$w; L <- ctx$L; Lz <- ctx$Lz
  nd <- nchar(gsub("[^0-9]","",u));  na_ <- nchar(gsub("[^A-Za-z]","",u))
  ns <- nchar(gsub("[^ \t]","",u));  np <- nchar(gsub("[^][!-/:-@{-}`^_~]","",u))
  nU <- nchar(gsub("[^A-Z]","",u))
  nm <- nchar(u,type="bytes") - nchar(gsub("[^\001-\177]","",u,useBytes=TRUE),type="bytes")

  cls <- c(wmean(nd/Lz,w), wmean(na_/Lz,w), wmean(ns/Lz,w), wmean(np/Lz,w))
  cls <- c(cls, max(0, 1-sum(cls, na.rm=TRUE)))
  clsp <- cls[!is.na(cls) & cls>0]

  has_alpha <- na_ > 0
  list(
    pct_chr_digit = cls[1], pct_chr_alpha = cls[2], pct_chr_space = cls[3],
    pct_chr_punct = cls[4], pct_chr_other = cls[5],
    pct_nonascii = wmean(nm/Lz, w),
    char_class_entropy = if(length(clsp)) -sum(clsp*log(clsp)) else NA_real_,
    sd_pct_digit = wsd(nd/Lz, w), sd_pct_alpha = wsd(na_/Lz, w),
    pct_all_digits = wshare(grepl("^[0-9]+$",u), w),
    pct_all_alpha  = wshare(grepl("^[A-Za-z]+$",u), w),
    pct_all_alpha_sp = wshare(grepl("^[A-Za-z ]+$",u), w),
    pct_alnum_mixed = wshare(grepl("[0-9]",u) & grepl("[A-Za-z]",u), w),
    pct_starts_digit = wshare(grepl("^[0-9]",u), w),
    pct_ends_digit   = wshare(grepl("[0-9]$",u), w),
    pct_all_upper = wshare(has_alpha & u==toupper(u), w),
    pct_all_lower = wshare(has_alpha & u==tolower(u), w),
    pct_title_case = wshare(grepl("^[A-Z][a-z]+( [A-Z][a-z']+)*$",u), w),
    pct_camel_case = wshare(grepl("^[a-z]+[A-Z]",u), w),
    pct_upper_chr = wmean(ifelse(na_>0, nU/pmax(na_,1), NA), w),
    ## alphabet closure: a tiny closed character set means a coded alphabet
    ## (hex, ACGT, roman numerals) rather than natural text
    n_distinct_chars = length(unique(unlist(strsplit(paste(u,collapse=""), NULL)))),
    alphabet_closure = length(unique(unlist(strsplit(tolower(gsub("[^A-Za-z]","",
                         paste(u,collapse=""))), NULL))))/26
  )
}

## ---------------------------------------------------------------------------
## BLOCK: punctuation, with position and higher moments  (tier 1)
## ---------------------------------------------------------------------------

PUNCT_VOCAB <- c(".", ",", "-", "_", "/", ":", ";", "(", ")", "@", "#", "$",
                 "%", "&", "*", "+", "=", "'", "\"", "|", "?", "!")
PUNCT_NAMES <- c("period","comma","dash","under","slash","colon","semi","lparen",
                 "rparen","at","hash","dollar","pct","amp","star","plus","eq",
                 "apos","quote","pipe","qmark","bang")
PUNCT_POS   <- c(".","-","/","@",":",",","_","(","#","$")

blk_punct <- function(ctx){
  u <- ctx$u; w <- ctx$w; Lz <- ctx$Lz
  out <- list()
  for(i in seq_along(PUNCT_VOCAB)){
    ch <- PUNCT_VOCAB[i]; nm <- PUNCT_NAMES[i]; esc <- rxesc(ch)
    ct <- nchar(u) - nchar(gsub(esc, "", u))
    out[[paste0("has_",nm)]]   <- wshare(ct>0, w)
    out[[paste0("cnt_",nm)]]   <- wmean(ct, w)
    out[[paste0("sd_",nm)]]    <- wsd(ct, w)
    out[[paste0("const_",nm)]] <- as.integer(any(ct>0) && length(unique(ct[ct>0]))==1)
    if(ch %in% PUNCT_POS){
      pos <- regexpr(esc, u, perl=TRUE); pos[pos<0] <- NA
      out[[paste0("possd_",nm)]]  <- wsd(as.numeric(pos), w)
      out[[paste0("posrel_",nm)]] <- wsd(as.numeric(pos)/Lz, w)
      out[[paste0("posmed_",nm)]] <- if(all(is.na(pos))) NA_real_ else median(pos, na.rm=TRUE)
    }
  }
  out
}

## ---------------------------------------------------------------------------
## BLOCK: character frequency distributions  (tier 2)
##
## Sherlock's character block is bag-of-characters -- it counts letters and
## discards position. Morphology lives at word endings, so the FINAL-letter
## distribution is computed separately and typically carries more per-feature
## signal than the all-position distribution.
## ---------------------------------------------------------------------------

blk_charfreq <- function(ctx){
  u <- ctx$u; w <- ctx$w
  out <- list()

  ## all-position letter frequency, frequency-weighted, case-folded
  lw <- tolower(gsub("[^A-Za-z]", "", u))
  tot <- sum(w * nchar(lw))
  for(ch in letters){
    ct <- nchar(lw) - nchar(gsub(ch, "", lw, fixed=TRUE))
    out[[paste0("ltr_", ch)]] <- if(tot>0) sum(w*ct)/tot else NA_real_
  }
  lf <- unlist(out[paste0("ltr_", letters)])
  out$ltr_kl_english <- if(all(!is.na(lf)) && sum(lf)>0)
                          kl_div(lf/sum(lf), ENGLISH_LETTER_FREQ) else NA_real_
  out$ltr_entropy    <- if(all(!is.na(lf)) && sum(lf)>0) ent(lf) else NA_real_

  ## first- and final-letter distributions, computed per TOKEN
  toks <- strsplit(tolower(gsub("[^A-Za-z ]", " ", u)), " +")
  tw   <- rep(w, lengths(toks))
  tk   <- unlist(toks)
  keep <- nchar(tk) > 0
  tk <- tk[keep]; tw <- tw[keep]

  if(length(tk)){
    f1 <- substr(tk, 1, 1)
    fl <- substr(tk, nchar(tk), nchar(tk))
    f2 <- substr(tk, pmax(1, nchar(tk)-1), nchar(tk))
    sw <- sum(tw)
    for(ch in letters){
      out[[paste0("first_", ch)]] <- sum(tw[f1==ch])/sw
      out[[paste0("last_",  ch)]] <- sum(tw[fl==ch])/sw
    }
    ## final-bigram concentration: how closed is the suffix inventory?
    b <- tapply(tw, f2, sum)
    out$suffix2_entropy    <- ent(as.numeric(b))
    out$suffix2_top_share  <- max(b)/sw
    out$suffix2_n_distinct <- length(b)
    out$last_entropy       <- ent(as.numeric(tapply(tw, fl, sum)))
    out$first_entropy      <- ent(as.numeric(tapply(tw, f1, sum)))
  } else {
    for(ch in letters){ out[[paste0("first_",ch)]] <- NA_real_
                        out[[paste0("last_",ch)]]  <- NA_real_ }
    for(k in c("suffix2_entropy","suffix2_top_share","suffix2_n_distinct",
               "last_entropy","first_entropy")) out[[k]] <- NA_real_
  }

  ## digit frequency + positional digit entropy
  dg <- gsub("[^0-9]", "", u); dtot <- sum(w*nchar(dg))
  for(d in 0:9){
    ct <- nchar(dg) - nchar(gsub(as.character(d), "", dg, fixed=TRUE))
    out[[paste0("dig_", d)]] <- if(dtot>0) sum(w*ct)/dtot else NA_real_
  }
  df <- unlist(out[paste0("dig_", 0:9)])
  out$dig_entropy   <- if(all(!is.na(df)) && sum(df)>0) ent(df) else NA_real_
  out$dig_uniform_chi2 <- if(all(!is.na(df)) && sum(df)>0) chi_s(df*1000, rep(0.1,10)) else NA_real_
  out
}

## ---------------------------------------------------------------------------
## BLOCK: mask / pattern abstraction  (tier 1)
## ---------------------------------------------------------------------------

blk_mask <- function(ctx){
  u <- ctx$u; w <- ctx$w; nu <- ctx$nu; sw <- sum(w)
  msk   <- gsub("[a-z]","a", gsub("[A-Z]","A", gsub("[0-9]","9", u)))
  msk_c <- gsub("(.)\\1+", "\\1+", msk)
  mt    <- tapply(w, msk, sum); mtc <- tapply(w, msk_c, sum)

  lcp <- function(s){
    if(length(s)<2) return(0L); m <- min(nchar(s)); if(m==0) return(0L)
    k <- 0L; for(i in seq_len(m)){ ch <- substr(s[1],i,i)
      if(all(substr(s,i,i)==ch)) k <- i else break }; k }
  su <- if(nu>500) sample(u,500) else u

  out <- list(
    n_masks = length(mt), mask_unique_ratio = length(mt)/nu,
    mask_top_share = max(mt)/sw, mask_entropy = ent(as.numeric(mt)),
    mask_entropy_norm = ent_n(as.numeric(mt)),
    mask_residual_rate = 1 - max(mt)/sw,
    is_single_mask = as.integer(max(mt)/sw > 0.95),
    cmask_top_share = max(mtc)/sw, cmask_unique_ratio = length(mtc)/nu,
    cmask_entropy = ent(as.numeric(mtc)),
    lcp_len = lcp(su),
    lcs_len = lcp(vapply(su, function(s)
                 paste(rev(strsplit(s,NULL)[[1]]), collapse=""), character(1))),
    lcp_frac = lcp(su)/max(wmean(nchar(u),w),1)
  )
  for(d in c(",",";","|","/")){
    parts <- lengths(strsplit(u, d, fixed=TRUE))
    nm <- switch(d, ","="comma", ";"="semi", "|"="pipe", "/"="slash")
    out[[paste0("delim_const_",nm)]] <- as.integer(length(unique(parts))==1 && parts[1]>1)
    out[[paste0("delim_nfld_",nm)]]  <- wmean(parts, w)
  }
  out
}

## ---------------------------------------------------------------------------
## BLOCK: regex battery + checksums  (tier 2)
## ---------------------------------------------------------------------------

RX <- list(
  email="^[^@[:space:]]+@[^@[:space:]]+\\.[A-Za-z]{2,}$",
  url="^(https?://|www\\.)\\S+$", ipv4="^([0-9]{1,3}\\.){3}[0-9]{1,3}$",
  uuid="^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$",
  hexhash="^[0-9a-fA-F]{16,}$", hexcolor="^#?[0-9a-fA-F]{6}$",
  base64="^[A-Za-z0-9+/]{16,}={0,2}$",
  filepath="^([A-Za-z]:)?[/\\\\].*[/\\\\]", jsonfrag="^\\s*[{\\[].*[}\\]]\\s*$",
  phone_us="^\\(?[0-9]{3}\\)?[- .]?[0-9]{3}[- .]?[0-9]{4}$",
  phone_intl="^\\+[0-9]{1,3}[- ]?[0-9 -]{6,14}$",
  zip5="^[0-9]{5}$", zip9="^[0-9]{5}-[0-9]{4}$",
  ssn="^[0-9]{3}-[0-9]{2}-[0-9]{4}$", ein="^[0-9]{2}-[0-9]{7}$",
  ein_bare="^[0-9]{9}$", fips_st="^[0-9]{2}$", fips_cty="^[0-9]{5}$",
  naics="^[0-9]{2,6}$", cusip="^[0-9A-Z]{9}$", isin="^[A-Z]{2}[0-9A-Z]{9}[0-9]$",
  money="^\\(?[-$]?[0-9]{1,3}(,[0-9]{3})*(\\.[0-9]{2})?\\)?$",
  percent="^-?[0-9]+(\\.[0-9]+)?%$",
  sci_not="^-?[0-9](\\.[0-9]+)?[eE][-+]?[0-9]+$",
  latlon="^-?[0-9]{1,3}\\.[0-9]{3,}$",
  latlon_dms="^[0-9]{1,3}[^0-9][0-9]{1,2}'[0-9.]+\"?[NSEW]$",
  date_iso="^[0-9]{4}-[0-9]{2}-[0-9]{2}$",
  date_us="^[0-9]{1,2}/[0-9]{1,2}/([0-9]{2}|[0-9]{4})$",
  date_eu="^[0-9]{1,2}[.-][0-9]{1,2}[.-][0-9]{4}$",
  date_word="^[0-9]{0,2} ?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)",
  yyyymm="^(19|20)[0-9]{2}(0[1-9]|1[0-2])$",
  time="^[0-9]{1,2}:[0-9]{2}(:[0-9]{2})?( ?[APap]\\.?[Mm]\\.?)?$",
  timestamp="^[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}",
  duration="^[0-9]+(\\.[0-9]+)? ?(sec|min|hr|hour|day|week|month|year)s?$",
  org_suffix="(Inc|Corp|LLC|Ltd|Foundation|Trust|Assn|Association|Church|Society)\\.?$",
  person_lastfirst="^[A-Z][a-z]+, [A-Z]([a-z]+|\\.)$",
  person_firstlast="^[A-Z][a-z]+ [A-Z][a-z]+$",
  street_addr="^[0-9]+ [A-Z0-9]",
  city_state="^[A-Za-z .'-]+, ?[A-Z]{2}$"
)

blk_regex <- function(ctx){
  u <- ctx$u; w <- ctx$w
  out <- lapply(RX, function(p) wshare(grepl(p, u), w))
  names(out) <- paste0("rx_", names(RX))
  out$rx_boolean <- wshare(grepl("^(y|n|t|f|yes|no|true|false|0|1)$",
                                 tolower(trimws(u))), w)
  out$rx_n_hits  <- sum(unlist(out) > 0.9, na.rm=TRUE)

  luhn_ok <- function(s){
    d <- suppressWarnings(as.integer(strsplit(gsub("[^0-9]","",s), NULL)[[1]]))
    if(length(d) < 12 || anyNA(d)) return(FALSE)
    d <- rev(d); i <- seq_along(d)
    d[i%%2==0] <- d[i%%2==0]*2; d[d>9] <- d[d>9]-9
    sum(d)%%10 == 0 }
  cand <- grepl("^[0-9 -]{12,19}$", u)
  out$chk_luhn_rate <- if(any(cand))
    wshare(ifelse(cand, vapply(u, luhn_ok, logical(1)), NA), w) else NA_real_

  ein_pfx <- sprintf("%02d", c(1:6,10:16,20:27,30:39,40:48,50:59,60:68,71:77,80:88,90:95,98,99))
  shp <- grepl("^[0-9]{2}-?[0-9]{7}$", u)
  out$chk_ein_prefix_rate <- if(any(shp))
    wshare(ifelse(shp, substr(u,1,2) %in% ein_pfx, NA), w) else NA_real_
  out
}

## ---------------------------------------------------------------------------
## BLOCK: numeric  (tier 1)
## ---------------------------------------------------------------------------

NUM_KEYS <- c("num_min","num_max","num_mean","num_sd","num_cv","num_median","num_iqr",
  "pct_integer","all_integer","pct_negative","pct_zero","pct_positive",
  "dec_mean","dec_max","dec_n_distinct","dec_fixed_2","dec_fixed",
  "bound_unit","bound_pct","bound_corr","bound_lat","bound_lon","bound_year",
  "bound_age","range_excel_dt","range_epoch_s","range_epoch_ms",
  "log10_range","n_digits_mean","skewness","kurtosis","skewness_log",
  "overdispersion","zero_inflation","hill_alpha","benford_chi2","lastdigit_chi2",
  "pct_round_10","pct_round_100","granularity","pct_num_sentinel","gini_coef",
  "ks_normal","ks_lognormal","n_modes")

blk_numeric <- function(ctx){
  u <- ctx$u; w <- ctx$w
  us <- sub("^\\((.*)\\)$", "-\\1", gsub("\u00a0","",gsub("[$,% ]","",u), fixed=TRUE))
  nr <- suppressWarnings(as.numeric(u)); nm <- suppressWarnings(as.numeric(us))
  out <- list(coerce_rate_raw = wshare(!is.na(nr), w),
              coerce_rate_strip = wshare(!is.na(nm), w))
  out$coerce_gap <- out$coerce_rate_strip - out$coerce_rate_raw

  ok <- !is.na(nm)
  if(!any(ok) || sum(w[ok]) < 3){ for(k in NUM_KEYS) out[[k]] <- NA_real_; return(out) }

  v <- nm[ok]; vw <- w[ok]
  m <- wmean(v,vw); s <- wsd(v,vw)
  qq <- quantile(rep(v, pmin(vw,500)), c(.25,.75), names=FALSE)

  dec <- nchar(sub("^[^.]*\\.?", "", us[ok])); dec[!grepl("\\.", us[ok])] <- 0
  pv <- v[v>0]; pw <- vw[v>0]

  out$num_min <- min(v); out$num_max <- max(v); out$num_mean <- m; out$num_sd <- s
  out$num_cv <- if(isTRUE(abs(m)>0)) s/abs(m) else NA_real_
  out$num_median <- median(rep(v, pmin(vw,500))); out$num_iqr <- qq[2]-qq[1]
  out$pct_integer <- wshare(v==floor(v), vw); out$all_integer <- as.integer(all(v==floor(v)))
  out$pct_negative <- wshare(v<0,vw); out$pct_zero <- wshare(v==0,vw)
  out$pct_positive <- wshare(v>0,vw)
  out$dec_mean <- wmean(dec,vw); out$dec_max <- max(dec)
  out$dec_n_distinct <- length(unique(dec))
  out$dec_fixed_2 <- as.integer(all(dec==2)); out$dec_fixed <- as.integer(length(unique(dec))==1)
  out$bound_unit <- as.integer(all(v>=0 & v<=1)); out$bound_pct <- as.integer(all(v>=0 & v<=100))
  out$bound_corr <- as.integer(all(v>=-1 & v<=1)); out$bound_lat <- as.integer(all(v>=-90 & v<=90))
  out$bound_lon <- as.integer(all(v>=-180 & v<=180))
  out$bound_year <- as.integer(all(v>=1900 & v<=2100 & v==floor(v)))
  out$bound_age <- as.integer(all(v>=0 & v<=120))
  out$range_excel_dt <- as.integer(all(v>=25000 & v<=60000))
  out$range_epoch_s <- as.integer(all(v>=5e8 & v<=2.5e9))
  out$range_epoch_ms <- as.integer(all(v>=5e11 & v<=2.5e12))
  out$log10_range <- safe(log10(max(abs(v))+1) - log10(min(abs(v[v!=0]))+1))
  out$n_digits_mean <- wmean(nchar(sub("\\..*$","",sub("^-","",us[ok]))), vw)
  out$skewness <- wskew(v,vw); out$kurtosis <- wkurt(v,vw)
  out$skewness_log <- if(length(pv)>3) wskew(log(pv), pw) else NA_real_
  out$overdispersion <- if(isTRUE(m>0) && all(v>=0) && all(v==floor(v))) s^2/m else NA_real_
  out$zero_inflation <- out$pct_zero
  out$hill_alpha <- if(length(pv)>=50){
    sv <- sort(pv, decreasing=TRUE); k <- max(10, floor(0.1*length(sv)))
    1/mean(log(sv[1:k]/sv[k])) } else NA_real_
  out$benford_chi2 <- if(length(pv)>=30){
    d1 <- as.integer(substr(formatC(pv, format="e", digits=0),1,1))
    kp <- d1>=1 & d1<=9
    chi_s(vapply(1:9, function(d) sum(pw[kp][d1[kp]==d]), numeric(1)), log10(1+1/(1:9)))
    } else NA_real_
  sel <- v==floor(v) & abs(v)>=10; iv <- v[sel]; iw <- vw[sel]
  out$lastdigit_chi2 <- if(length(iv)>=30){
    ld <- abs(iv)%%10
    chi_s(vapply(0:9, function(d) sum(iw[ld==d]), numeric(1)), rep(0.1,10)) } else NA_real_
  out$pct_round_10 <- wshare(v%%10==0, vw); out$pct_round_100 <- wshare(v%%100==0, vw)
  out$granularity <- if(all(v==floor(v)) && length(v)<=5000 && any(v!=0))
    as.numeric(Reduce(function(a,b) ifelse(b==0,a,{while(b){t<-b;b<-a%%b;a<-t};a}),
               abs(v[v!=0]))) else NA_real_
  out$pct_num_sentinel <- wshare(v %in% c(-1,-8,-9,-99,-999,-9999,999,9999,99999,999999), vw)

  sv <- sort(v)
  out$gini_coef <- if(all(v>=0) && sum(v)>0)
    sum((2*seq_along(sv)-length(sv)-1)*sv)/(length(sv)*sum(sv)) else NA_real_
  z <- if(!is.na(s) && s>0) (v-m)/s else NULL
  out$ks_normal <- if(!is.null(z) && length(z)>=8)
    safe(suppressWarnings(ks.test(z,"pnorm")$statistic)) else NA_real_
  out$ks_lognormal <- if(length(pv)>=8){
    lz <- (log(pv)-mean(log(pv)))/max(sd(log(pv)),1e-9)
    safe(suppressWarnings(ks.test(lz,"pnorm")$statistic)) } else NA_real_
  out$n_modes <- if(length(unique(v))>=10)
    safe({d <- density(rep(v, pmin(vw,50))); sum(diff(sign(diff(d$y)))==-2)}) else NA_real_
  out
}

## ---------------------------------------------------------------------------
## BLOCK: token structure  (tier 2)
##
## The npmatch transfer. First/last token stability is the token-level analogue
## of positional punctuation: addresses close on a small suffix set, org names
## close on {Inc, Foundation, Trust}, person names open on a given-name set.
## ---------------------------------------------------------------------------

blk_token <- function(ctx){
  u <- ctx$u; w <- ctx$w
  toks <- strsplit(trimws(tolower(gsub("[^A-Za-z0-9' ]", " ", u))), " +")
  tw   <- rep(w, lengths(toks)); tk <- unlist(toks)
  keep <- nchar(tk) > 0; tk <- tk[keep]; tw <- tw[keep]

  out <- list()
  if(!length(tk)){
    for(k in c("tok_n_unique","tok_vocab_closure","tok_entropy","tok_entropy_norm",
      "tok_hapax_ratio","tok_ttr","tok_zipf_slope","stopword_rate","tok_len_mean",
      "tok_len_sd","pct_tok_alpha","pct_tok_numeric","pct_tok_mixed","vowel_rate",
      "first_tok_top_share","last_tok_top_share","first_tok_entropy","last_tok_entropy",
      "first_tok_n_unique","last_tok_n_unique","last_tok_closed","tokmask_top_share",
      "tokmask_n_unique"))
      out[[k]] <- NA_real_
    return(out)
  }

  tt <- tapply(tw, tk, sum); T <- sum(tw); ntu <- length(tt)
  out$tok_n_unique      <- ntu
  out$tok_vocab_closure <- ntu/ctx$nu     # ~1 => each value is its own token
  out$tok_entropy       <- ent(as.numeric(tt))
  out$tok_entropy_norm  <- ent_n(as.numeric(tt))
  out$tok_hapax_ratio   <- sum(tt==1)/ntu
  out$tok_ttr           <- ntu/length(tk)
  out$tok_zipf_slope    <- if(ntu>=10 && max(tt)>1){
    fq <- sort(as.numeric(tt), decreasing=TRUE)
    safe(unname(coef(lm(log(fq) ~ log(seq_along(fq))))[2])) } else NA_real_
  out$stopword_rate     <- sum(tw[tk %in% STOPWORDS])/T
  out$tok_len_mean      <- sum(tw*nchar(tk))/T
  out$tok_len_sd        <- sqrt(sum(tw*(nchar(tk)-out$tok_len_mean)^2)/T)
  out$pct_tok_alpha     <- sum(tw[grepl("^[a-z']+$", tk)])/T
  out$pct_tok_numeric   <- sum(tw[grepl("^[0-9]+$", tk)])/T
  out$pct_tok_mixed     <- sum(tw[grepl("[a-z]", tk) & grepl("[0-9]", tk)])/T
  out$vowel_rate        <- sum(tw*nchar(gsub("[^aeiou]","",tk)))/sum(tw*nchar(tk))

  ## positional token features
  ft <- vapply(toks, function(z){ z <- z[nchar(z)>0]; if(length(z)) z[1] else NA_character_ },
               character(1))
  lt <- vapply(toks, function(z){ z <- z[nchar(z)>0]; if(length(z)) z[length(z)] else NA_character_ },
               character(1))
  fok <- !is.na(ft); lok <- !is.na(lt)
  fts <- tapply(w[fok], ft[fok], sum); lts <- tapply(w[lok], lt[lok], sum)
  out$first_tok_top_share <- max(fts)/sum(fts)
  out$last_tok_top_share  <- max(lts)/sum(lts)
  out$first_tok_entropy   <- ent(as.numeric(fts))
  out$last_tok_entropy    <- ent(as.numeric(lts))
  out$first_tok_n_unique  <- length(fts)
  out$last_tok_n_unique   <- length(lts)
  ## closed suffix inventory: 90% of values end in one of <=10 distinct tokens
  out$last_tok_closed <- as.integer(
    sum(head(sort(as.numeric(lts), decreasing=TRUE), 10))/sum(lts) > 0.9)

  ## token-level mask: "123 Main St" -> "9 Aa Aa"
  tmask <- vapply(toks, function(z){
    z <- z[nchar(z)>0]; if(!length(z)) return(NA_character_)
    paste(ifelse(grepl("^[0-9]+$", z), "9",
           ifelse(grepl("^[a-z]+$", z), "a", "x")), collapse=" ") }, character(1))
  mok <- !is.na(tmask); tms <- tapply(w[mok], tmask[mok], sum)
  out$tokmask_top_share <- max(tms)/sum(tms)
  out$tokmask_n_unique  <- length(tms)
  out
}

## ---------------------------------------------------------------------------
## BLOCK: lexicon hit rates  (tier 3 -- the first genuinely expensive block)
## ---------------------------------------------------------------------------

blk_lexicon <- function(ctx, lexicons = default_lexicons(), top_k = 200){
  u <- ctx$u; w <- ctx$w
  lv <- ctx$lower
  toks <- strsplit(trimws(tolower(gsub("[^A-Za-z0-9' ]", " ", u))), " +")
  tw <- rep(w, lengths(toks)); tk <- unlist(toks)
  keep <- nchar(tk)>0; tk <- tk[keep]; tw <- tw[keep]
  ## restrict dictionary work to the top-k tokens by mass
  if(length(tk)){
    tt <- sort(tapply(tw, tk, sum), decreasing=TRUE)
    tt <- head(tt, top_k); T <- sum(tw)
  } else { tt <- numeric(0); T <- 1 }

  out <- list()
  for(nm in names(lexicons)){
    lex <- lexicons[[nm]]
    out[[paste0("lex_", nm, "_value")]] <- wshare(lv %in% lex, w)
    out[[paste0("lex_", nm, "_token")]] <- if(length(tt))
      sum(tt[names(tt) %in% lex])/T else NA_real_
  }
  out$lex_any_value <- wshare(lv %in% unlist(lexicons, use.names=FALSE), w)
  out$lex_top_k_covered <- if(length(tt)) sum(tt)/T else NA_real_
  out
}

## ---------------------------------------------------------------------------
## BLOCK: header / declared class  (tier 1, free)
## ---------------------------------------------------------------------------

HEADER_KW <- c(
  id="(^|_)(id|key|num|no|nbr)($|_)", code="code|cd$|_cd",
  date="date|dt$|day|month|year|yr|time|stamp",
  amt="amt|amount|total|sum|revenue|expense|cost|price|pay|fee|salary|comp",
  pct="pct|percent|rate|ratio|share|prop", flag="flag|is_|has_|ind$|indicator|_yn",
  name="name|nm$|title|desc|label", geo="city|state|zip|county|fips|addr|street|lat|lon|geo",
  cnt="count|n_|num_|qty|freq|total_n", ein="ein|tin|fein|taxid",
  org="org|company|firm|entity|filer", person="person|first|last|middle|contact")

blk_header <- function(ctx, col_name = NULL){
  out <- list()
  if(is.null(col_name) || is.na(col_name)){
    for(k in names(HEADER_KW)) out[[paste0("nm_",k)]] <- NA_real_
    out$nm_nchar <- out$nm_has_under <- out$nm_is_upper <- out$nm_n_tokens <- NA_real_
  } else {
    cn <- tolower(col_name)
    for(k in names(HEADER_KW)) out[[paste0("nm_",k)]] <- as.integer(grepl(HEADER_KW[[k]], cn))
    out$nm_nchar <- nchar(cn)
    out$nm_has_under <- as.integer(grepl("_", col_name))
    out$nm_is_upper <- as.integer(col_name == toupper(col_name))
    out$nm_n_tokens <- length(strsplit(cn, "[_ .]+")[[1]])
  }
  x <- ctx$x_raw
  out$in_is_numeric <- as.integer(is.numeric(x)); out$in_is_factor <- as.integer(is.factor(x))
  out$in_is_logical <- as.integer(is.logical(x))
  out$in_is_date <- as.integer(inherits(x, c("Date","POSIXt")))
  out
}

## ---------------------------------------------------------------------------
## assembly
## ---------------------------------------------------------------------------

ALL_BLOCKS <- c("core","sequence","length","charclass","punct","mask",
                "charfreq","regex","numeric","token","lexicon","header")

#' @export
fx_extract_features <- function( x, col_name = NULL,
                              blocks = ALL_BLOCKS,
                              lexicons = default_lexicons(),
                              max_unique = 20000,
                              seed = 1L ){

  ## Reproducible AND non-invasive: seed a local RNG stream for the internal
  ## downsamples (prep_context, blk_mask), and restore the caller's global
  ## RNG state on exit. A profile that varies between runs would break the
  ## test bank's replayability, which is the point of pinning extractor_version.
  if( exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE) ){
    .old_seed <- get(".Random.seed", envir = .GlobalEnv)
    on.exit( assign(".Random.seed", .old_seed, envir = .GlobalEnv), add = TRUE )
  } else {
    on.exit( suppressWarnings(rm(".Random.seed", envir = .GlobalEnv)), add = TRUE )
  }
  set.seed( seed )

  ctx <- prep_context(x, max_unique = max_unique)
  f <- list(n = ctx$n_total, pct_missing = ctx$pct_missing,
            pct_sentinel_na = ctx$pct_sentinel_na)
  if(!ctx$ok) return(.finalize(f))

  if("core"      %in% blocks) f <- c(f, blk_core(ctx))
  if("sequence"  %in% blocks) f <- c(f, blk_sequence(ctx))
  if("length"    %in% blocks) f <- c(f, blk_length(ctx))
  if("charclass" %in% blocks) f <- c(f, blk_charclass(ctx))
  if("punct"     %in% blocks) f <- c(f, blk_punct(ctx))
  if("mask"      %in% blocks) f <- c(f, blk_mask(ctx))
  if("charfreq"  %in% blocks) f <- c(f, blk_charfreq(ctx))
  if("regex"     %in% blocks) f <- c(f, blk_regex(ctx))
  if("numeric"   %in% blocks) f <- c(f, blk_numeric(ctx))
  if("token"     %in% blocks) f <- c(f, blk_token(ctx))
  if("lexicon"   %in% blocks) f <- c(f, blk_lexicon(ctx, lexicons))
  if("header"    %in% blocks) f <- c(f, blk_header(ctx, col_name))

  f <- f[!duplicated(names(f))]
  .finalize(f)
}

.finalize <- function(f){
  f <- lapply(f, function(z){ z <- suppressWarnings(as.numeric(z))
    if(length(z)!=1 || !is.finite(z)) NA_real_ else z })
  out <- as.data.frame(f, stringsAsFactors=FALSE)
  rownames(out) <- NULL
  out
}

#' @export
fx_extract_features_df <- function(df, ...){
  rows <- lapply(names(df), function(nm) fx_extract_features(df[[nm]], col_name=nm, ...))
  all_nm <- unique(unlist(lapply(rows, names)))
  rows <- lapply(rows, function(r){
    for(m in setdiff(all_nm, names(r))) r[[m]] <- NA_real_
    r[, all_nm, drop=FALSE] })
  cbind(column = names(df), do.call(rbind, rows), stringsAsFactors=FALSE)
}

## ---------------------------------------------------------------------------
## feature manifest -- feature -> block -> cascade tier.
##
## This is what makes deployment-stage trimming mechanical: once the cascade is
## fitted, take the union of features its detectors reference, look up their
## blocks here, and pass only those blocks to fx_extract_features().
## ---------------------------------------------------------------------------

BLOCK_TIER <- c(core=1, sequence=1, length=1, charclass=1, punct=1, mask=1,
                header=1, numeric=1, charfreq=2, regex=2, token=2, lexicon=3)

#' @export
fx_feature_manifest <- function(lexicons = default_lexicons()){
  probe <- c(sprintf("%02d-%07d", 10:60, 1234567L), "Quercus alba", "12.50", "a@b.com")
  rows <- lapply(ALL_BLOCKS, function(b){
    fs <- names(fx_extract_features(probe, col_name="probe_id", blocks=b, lexicons=lexicons))
    data.frame(feature=fs, block=b, tier=unname(BLOCK_TIER[b]), stringsAsFactors=FALSE)
  })
  m <- do.call(rbind, rows)
  m[!duplicated(m$feature), ]
}

#' @export
fx_blocks_for_features <- function(features, manifest = fx_feature_manifest()){
  b <- unique(manifest$block[manifest$feature %in% features])
  unique(c("core", b))
}
