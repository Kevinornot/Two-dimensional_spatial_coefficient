#' Pixel-wise Pearson correlation for aligned DGT maps
#'
#' @param x,y Aligned numeric intensity matrices with identical dimensions.
#' @param crop One edge fraction or four fractions in top, right, bottom, left order.
#' @param use Missing-value behavior, either `"complete.obs"` or `"everything"`.
#'
#' @details
#' Each crop fraction is multiplied by the corresponding row or column count
#' and rounded down to the number of pixels removed from that edge. A scalar
#' applies to all edges; four fractions specify top, right, bottom and left.
#'
#' After cropping, `use = "complete.obs"` excludes any paired pixel for which
#' either value is non-finite (`NA`, `NaN`, `Inf` or `-Inf`). At least two finite
#' pairs are required for either setting. With `use = "everything"`, any
#' non-finite value in the cropped maps returns `NA` once that minimum is met.
#' Otherwise, zero variance in either retained input raises an error.
#'
#' Maps must be spatially registered and aligned before analysis. Identical
#' dimensions alone do not establish alignment, and independently resized or
#' unregistered maps can produce misleading results. The coefficient describes
#' pixel-wise association, not a distance-weighted spatial statistic. Adjacent
#' pixels can be spatially autocorrelated, so conventional pixel-level p-values
#' that treat pixels as independent replicates are not supplied.
#'
#' @return One numeric Pearson correlation coefficient, or `NA` as described above.
#' @export
pearson_2d <- function(x, y, crop = 0, use = "complete.obs") {
  paired <- .paired_dgt_pixels(x, y, crop, use)
  if (paired$return_na) return(NA_real_)
  unname(stats::cor(paired$x, paired$y, method = "pearson"))
}
