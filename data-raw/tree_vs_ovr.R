## data-raw/tree_vs_ovr.R
## ---------------------------------------------------------------------------
## Compare, on the full 40-class semantic_type target: (a) a single decision
## tree predicting all classes at once, vs (b) 40 one-vs-rest binary logistic
## models (argmax of per-class probabilities). Reports overall accuracy,
## macro-recall, and macro-recall split by class support. Run from the package
## root: Rscript data-raw/tree_vs_ovr.R
## ---------------------------------------------------------------------------
set.seed(514)
has_glmnet <- requireNamespace("glmnet", quietly = TRUE)
has_rpart  <- requireNamespace("rpart",  quietly = TRUE)
cat("glmnet:", has_glmnet, " rpart:", has_rpart, "\n")

d    <- readRDS("data-raw/type_features_dataset.rds")
spec <- utils::read.csv("data-raw/type_features_imputation.csv", stringsAsFactors = FALSE)
meta <- c("corpus","source_label","vector_length","sample_values")
outc <- c("data_type","semantic_family","semantic_type","format_label","format_style","unit_type")
feat <- setdiff(names(d), c(meta, outc))
dropf <- spec$feature[spec$na_rule=="drop"]; numf <- spec$feature[spec$na_rule=="numeric_med"]
zerof <- spec$feature[spec$na_rule=="zero"]
X <- d[, setdiff(feat, dropf), drop=FALSE]
for (f in intersect(zerof,names(X))) X[[f]][is.na(X[[f]])] <- 0
for (f in intersect(numf, names(X))) { m<-median(X[[f]],na.rm=TRUE); if(is.na(m))m<-0; X[[f]][is.na(X[[f]])]<-m }
X <- as.matrix(X); X <- X[, apply(X,2,sd)>0, drop=FALSE]
y <- factor(d$semantic_type)

tr <- sample(nrow(X), floor(.7*nrow(X))); te <- setdiff(seq_len(nrow(X)), tr)
Xtr <- scale(X[tr,]); ctr <- attr(Xtr,"scaled:center"); scl <- attr(Xtr,"scaled:scale")
Xte <- scale(X[te,], center=ctr, scale=scl)
ytr <- y[tr]; yte <- y[te]

macro_recall <- function(truth, pred){
  cm <- table(truth, pred); r <- diag(cm)/rowSums(cm); mean(r[rowSums(cm)>0]) }

## --- single decision tree (all classes at once) ----------------------------
fit_tree <- rpart::rpart(ytr ~ ., data=data.frame(ytr=ytr, X[tr,]), method="class",
                         control=rpart::rpart.control(cp=0.002, minbucket=5))
pt <- predict(fit_tree, data.frame(X[te,]), type="class")
cat("\n[TREE]  accuracy:", round(mean(pt==yte),3),
    " macro-recall:", round(macro_recall(yte,pt),3),
    " leaves:", sum(fit_tree$frame$var=="<leaf>"), "\n")

## --- one-vs-rest logistic: one binary glm per class, on that class's top-25
## discriminating features (per-class feature selection = light regularization,
## and avoids separation / p>>n without needing glmnet) -----------------------
cls <- levels(ytr)
prob <- matrix(NA_real_, length(te), length(cls), dimnames=list(NULL, cls))
for (c in cls){
  yb <- ytr==c
  if (sum(yb) < 8){ prob[,c] <- mean(yb); next }   # too rare to fit; use prior
  md   <- abs(colMeans(Xtr[yb,,drop=FALSE]) - colMeans(Xtr[!yb,,drop=FALSE]))
  topf <- order(md, decreasing=TRUE)[1:25]
  dfl  <- data.frame(y=as.integer(yb), Xtr[,topf,drop=FALSE])
  m    <- suppressWarnings(glm(y~., dfl, family=binomial()))
  prob[,c] <- suppressWarnings(predict(m, data.frame(Xte[,topf,drop=FALSE]), type="response"))
}
pl <- factor(cls[max.col(prob, ties.method="first")], levels=cls)
cat("[OvR logistic] accuracy:", round(mean(pl==yte),3),
    " macro-recall:", round(macro_recall(yte,pl),3),
    " models:", length(cls), "\n")

## --- where they differ: per-class recall on rare vs common ------------------
rec <- function(p){ cm <- table(yte, p); r <- diag(cm)/rowSums(cm); r }
rt <- rec(pt); rl <- rec(pl); sup <- as.integer(table(yte))
cmp <- data.frame(semantic_type=levels(yte), support=sup,
                  tree_recall=round(rt,2), ovr_recall=round(rl,2))
cmp <- cmp[order(cmp$support), ]
cat("\n=== per-class recall, rarest 14 classes ===\n")
print(head(cmp, 14), row.names=FALSE)
cat("\n=== macro-recall by support bucket (evaluable classes only) ===\n")
for (bk in list(c(1,9,"rare 1-9"), c(10,49,"mid 10-49"), c(50,1e9,"common 50+"))){
  lo <- as.numeric(bk[1]); hi <- as.numeric(bk[2])
  sel <- cmp$support >= lo & cmp$support <= hi
  cat(sprintf("  %-12s n=%2d  tree=%.3f  OvR=%.3f\n", bk[3], sum(sel),
              mean(cmp$tree_recall[sel], na.rm=TRUE),
              mean(cmp$ovr_recall[sel],  na.rm=TRUE)))
}
cat(sprintf("\nclasses with 0 test rows (untrainable long tail): %d of %d\n",
            sum(cmp$support==0), length(cls)))
