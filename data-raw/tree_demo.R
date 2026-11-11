## data-raw/tree_demo.R
## ---------------------------------------------------------------------------
## (1) Decision tree over the FULL semantic_type label set (40 classes).
## (2) A curated ~12-type teaching subset -- most types cleanly separable, one
##     pair (first_name / last_name) deliberately conflated -- written to
##     data-raw/type_features_teaching.{csv,rds}.
## ---------------------------------------------------------------------------
suppressMessages(pkgload::load_all(".", quiet = TRUE))
stopifnot(requireNamespace("rpart", quietly = TRUE))
set.seed(514)

d    <- readRDS("data-raw/type_features_dataset.rds")
spec <- utils::read.csv("data-raw/type_features_imputation.csv", stringsAsFactors = FALSE)
meta <- c("corpus","source_label","vector_length","sample_values")
outc <- c("data_type","semantic_family","semantic_type","format_label","format_style","unit_type")
feat <- setdiff(names(d), c(meta, outc))

dropf <- spec$feature[spec$na_rule=="drop"]
numf  <- spec$feature[spec$na_rule=="numeric_med"]
zerof <- spec$feature[spec$na_rule=="zero"]
impute_mat <- function(df){
  df <- df[, setdiff(feat, dropf), drop=FALSE]
  for (f in intersect(zerof, names(df))) df[[f]][is.na(df[[f]])] <- 0
  for (f in intersect(numf,  names(df))) { m <- median(df[[f]], na.rm=TRUE); if(is.na(m)) m<-0; df[[f]][is.na(df[[f]])] <- m }
  df
}

## ===========================================================================
## (1) full semantic_type tree
## ===========================================================================
Xall <- impute_mat(d)
y <- factor(d$semantic_type)
tr <- sample(nrow(d), floor(.7*nrow(d)))
fit <- rpart::rpart(y ~ ., data = cbind(y=y, Xall)[tr,], method="class",
                    control = rpart::rpart.control(cp = 0.002, minbucket = 5))
pred <- predict(fit, Xall[-tr,], type="class")
acc  <- mean(pred == y[-tr])
base <- max(prop.table(table(y[tr])))
cat(sprintf("=== FULL semantic_type tree: %d classes ===\n", nlevels(y)))
cat(sprintf("test accuracy: %.3f   (majority-class baseline %.3f)\n", acc, base))
cat(sprintf("tree leaves: %d\n", sum(fit$frame$var == "<leaf>")))
## per-class recall for the better-supported classes
tabc <- table(truth=y[-tr], pred=pred)
rec  <- diag(tabc)/rowSums(tabc); sup <- rowSums(tabc)
pc   <- data.frame(semantic_type=names(rec), support=as.integer(sup), recall=round(rec,2))
pc   <- pc[sup >= 15, ]; pc <- pc[order(-pc$recall), ]
cat("\nper-class recall (support >= 15 in test):\n"); print(pc, row.names=FALSE)

## ===========================================================================
## (2) curated teaching subset: 12 types, one deliberately conflated pair
##   - 10 rigid-format types, bootstrapped from the formex canonical examples,
##     are each cleanly separable;
##   - artist / director are BOTH human-name columns (semantic_type = person):
##     value-identical, so no feature distinguishes them -> they conflate.
## ===========================================================================
crisp    <- c("email","ein","ipv4","iso_date","hex_color","guid","isbn",
              "zip_code","phone","currency_code")
conflate <- c("artist","director")
env <- new.env()
for (f in list.files("data-raw/datatypes", pattern="\\.R$", full.names=TRUE)) sys.source(f, envir=env)

boot_rows <- function(type, B=45, nmin=15, nmax=50){
  v <- as.character(get(type, envir=env)); v <- v[!is.na(v) & nzchar(trimws(v))]
  lab <- d[d$source_label==type, outc, drop=FALSE][1, ]     # the 6 ontology labels
  do.call(rbind, lapply(seq_len(B), function(i){
    k  <- sample(nmin:nmax, 1); vv <- sample(v, k, replace=TRUE)
    fx <- fx_extract_features(vv, col_name=NULL)
    s5 <- paste(head(unique(vv),5), collapse=";;")
    cbind(data.frame(corpus="formex_boot", source_label=type, vector_length=k,
                     sample_values=s5, stringsAsFactors=FALSE), lab, fx)
  }))
}
cols_all  <- c(meta, outc, feat)
sub_crisp <- do.call(rbind, lapply(crisp, boot_rows))[, cols_all]
real      <- d[d$source_label %in% conflate, cols_all, drop=FALSE]
real      <- do.call(rbind, lapply(split(real, real$source_label),
                 function(g) g[sample(nrow(g), min(45, nrow(g))), , drop=FALSE]))
sub <- rbind(sub_crisp, real)
utils::write.csv(sub, "data-raw/type_features_teaching.csv", row.names=FALSE, na="")
saveRDS(sub, "data-raw/type_features_teaching.rds")
cat(sprintf("\n=== teaching subset: %d rows x %d cols, %d types ===\n",
            nrow(sub), ncol(sub), length(c(crisp, conflate))))
print(table(sub$source_label))

## fit a tree on the subset and show the confusion
Xs <- impute_mat(sub); ys <- factor(sub$source_label)
trs <- sample(nrow(sub), floor(.7*nrow(sub)))
fts <- rpart::rpart(ys ~ ., data=cbind(ys=ys, Xs)[trs,], method="class",
                    control=rpart::rpart.control(cp=0.004, minbucket=4))
ps  <- predict(fts, Xs[-trs,], type="class")
cat(sprintf("\nsubset tree test accuracy: %.3f\n", mean(ps==ys[-trs])))
cat("\nconfusion (truth rows x predicted cols):\n")
print(table(truth=ys[-trs], pred=ps))
cat("\nper-type recall:\n")
cm <- table(ys[-trs], ps); print(round(diag(cm)/rowSums(cm), 2))
