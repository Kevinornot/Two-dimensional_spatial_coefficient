#' Pairwise Pearson correlations among Fe, S and P maps
#'
#' @param fe,s,p Aligned numeric intensity matrices.
#' @param crop One edge fraction or four fractions in top, right, bottom, left order.
#' @param use Missing-value behavior passed to [pearson_2d()].
#'
#' @return A three-row data frame with pair, valid-pixel count and Pearson r.
#' @export
pairwise_dgt_cor <- function(fe, s, p, crop = 0, use = "complete.obs") {
  inputs <- list(Fe = fe, S = s, P = p)
  pairs <- list(c("Fe", "S"), c("S", "P"), c("Fe", "P"))
  rows <- lapply(pairs, function(pair) {
    paired <- .paired_dgt_pixels(inputs[[pair[1]]], inputs[[pair[2]]], crop, use)
    coefficient <- if (paired$return_na) {
      NA_real_
    } else {
      unname(stats::cor(paired$x, paired$y, method = "pearson"))
    }
    data.frame(
      pair = paste(pair, collapse = "-"),
      n_pixels = as.integer(paired$n_pixels),
      pearson_r = coefficient,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}
