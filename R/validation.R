.validate_dgt_matrix <- function(x, name) {
  if (!is.matrix(x) || !is.numeric(x)) {
    stop("`", name, "` must be a numeric matrix.", call. = FALSE)
  }
  if (any(dim(x) < 1L)) {
    stop("`", name, "` must have non-zero dimensions.", call. = FALSE)
  }
  x
}

.normalize_crop <- function(crop) {
  if (!is.numeric(crop) || !(length(crop) %in% c(1L, 4L)) ||
      any(!is.finite(crop)) || any(crop < 0) || any(crop >= 0.5)) {
    stop("`crop` must contain one or four finite fractions from 0 to less than 0.5.", call. = FALSE)
  }
  if (length(crop) == 1L) rep(crop, 4L) else crop
}

.crop_dgt_matrix <- function(x, crop) {
  crop <- .normalize_crop(crop)
  nr <- nrow(x)
  nc <- ncol(x)
  removed <- floor(c(nr, nc, nr, nc) * crop)
  rows <- seq.int(removed[1] + 1L, nr - removed[3])
  cols <- seq.int(removed[4] + 1L, nc - removed[2])
  if (length(rows) < 1L || length(cols) < 1L) {
    stop("`crop` removes the entire matrix.", call. = FALSE)
  }
  x[rows, cols, drop = FALSE]
}

.paired_dgt_pixels <- function(x, y, crop, use) {
  x <- .validate_dgt_matrix(x, "x")
  y <- .validate_dgt_matrix(y, "y")
  if (!identical(dim(x), dim(y))) {
    stop("`x` and `y` must have identical dimensions.", call. = FALSE)
  }
  if (!is.character(use) || length(use) != 1L || is.na(use) ||
      !(use %in% c("complete.obs", "everything"))) {
    stop("`use` must be either `complete.obs` or `everything`.", call. = FALSE)
  }
  x <- as.vector(.crop_dgt_matrix(x, crop))
  y <- as.vector(.crop_dgt_matrix(y, crop))
  valid <- is.finite(x) & is.finite(y)
  if (sum(valid) < 2L) {
    stop("At least two valid paired pixels are required.", call. = FALSE)
  }
  if (use == "everything" && !all(valid)) {
    return(list(x = x[valid], y = y[valid], n_pixels = sum(valid), return_na = TRUE))
  }
  x <- x[valid]
  y <- y[valid]
  if (stats::sd(x) == 0 || stats::sd(y) == 0) {
    stop("Pearson correlation is undefined for zero variance.", call. = FALSE)
  }
  list(x = x, y = y, n_pixels = length(x), return_na = FALSE)
}
