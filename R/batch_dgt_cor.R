.normalize_invert <- function(invert) {
  if (!is.logical(invert) || anyNA(invert)) {
    stop("`invert` must be logical.", call. = FALSE)
  }
  if (length(invert) == 1L) {
    return(stats::setNames(rep(invert, 3L), c("Fe", "S", "P")))
  }
  if (length(invert) == 3L && setequal(names(invert), c("Fe", "S", "P"))) {
    return(invert[c("Fe", "S", "P")])
  }
  stop("`invert` must be one logical value or a named Fe, S and P vector.", call. = FALSE)
}

#' Batch Fe-S-P correlation from an image manifest
#'
#' @param manifest Data frame with sample, Fe, S and P columns.
#' @param crop Edge crop passed to [pairwise_dgt_cor()].
#' @param invert One logical value or a named Fe, S and P logical vector.
#' @param allow_color Whether to permit luminance conversion of colored images.
#' @param rgb_tolerance Maximum channel difference treated as grayscale.
#' @param use Missing-value behavior passed to [pearson_2d()].
#'
#' @return A long data frame with sample, pair, valid-pixel count and Pearson r.
#' @export
batch_dgt_cor <- function(manifest, crop = 0, invert = FALSE,
                          allow_color = FALSE, rgb_tolerance = 0.02,
                          use = "complete.obs") {
  required <- c("sample", "Fe", "S", "P")
  if (!is.data.frame(manifest) || !all(required %in% names(manifest))) {
    stop("`manifest` must contain required columns: sample, Fe, S and P.", call. = FALSE)
  }
  if (anyDuplicated(manifest$sample)) {
    stop("`manifest` contains a duplicate sample identifier.", call. = FALSE)
  }
  directions <- .normalize_invert(invert)
  if (nrow(manifest) == 0L) {
    return(data.frame(
      sample = character(),
      pair = character(),
      n_pixels = integer(),
      pearson_r = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  rows <- lapply(seq_len(nrow(manifest)), function(index) {
    sample <- as.character(manifest$sample[index])
    maps <- lapply(c("Fe", "S", "P"), function(element) {
      path <- manifest[[element]][index]
      tryCatch(
        read_dgt_image(
          path,
          invert = directions[[element]],
          allow_color = allow_color,
          rgb_tolerance = rgb_tolerance
        ),
        error = function(error) {
          stop("Sample '", sample, "', element ", element, " (", path, "): ",
               conditionMessage(error), call. = FALSE)
        }
      )
    })
    names(maps) <- c("Fe", "S", "P")
    result <- tryCatch(
      pairwise_dgt_cor(maps$Fe, maps$S, maps$P, crop = crop, use = use),
      error = function(error) {
        stop("Sample '", sample, "': ", conditionMessage(error), call. = FALSE)
      }
    )
    result$sample <- sample
    result[c("sample", "pair", "n_pixels", "pearson_r")]
  })
  do.call(rbind, rows)
}
