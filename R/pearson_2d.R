#' Pixel-wise Pearson correlation for aligned DGT maps
#'
#' @param x,y Aligned numeric intensity matrices with identical dimensions.
#' @param crop One edge fraction or four fractions in top, right, bottom, left order.
#' @param use Missing-value behavior, either `"complete.obs"` or `"everything"`.
#'
#' @return One numeric Pearson correlation coefficient.
#' @export
pearson_2d <- function(x, y, crop = 0, use = "complete.obs") {
  paired <- .paired_dgt_pixels(x, y, crop, use)
  if (paired$return_na) return(NA_real_)
  unname(stats::cor(paired$x, paired$y, method = "pearson"))
}
