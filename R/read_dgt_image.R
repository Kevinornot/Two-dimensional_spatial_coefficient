#' Read a two-dimensional DGT intensity image
#'
#' @param path Path to a PNG or JPEG image.
#' @param invert Whether to replace intensity `x` with `1 - x`.
#' @param allow_color Whether to permit luminance conversion of a colored RGB image.
#' @param rgb_tolerance Maximum channel difference treated as grayscale.
#'
#' @return A numeric intensity matrix with values in `[0, 1]`.
#' @export
read_dgt_image <- function(path, invert = FALSE, allow_color = FALSE,
                           rgb_tolerance = 0.02) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    stop("`path` must be one non-empty character string.", call. = FALSE)
  }
  if (!file.exists(path)) {
    stop("Image file does not exist: ", path, call. = FALSE)
  }
  if (!is.logical(invert) || length(invert) != 1L || is.na(invert)) {
    stop("`invert` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.logical(allow_color) || length(allow_color) != 1L || is.na(allow_color)) {
    stop("`allow_color` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.numeric(rgb_tolerance) || length(rgb_tolerance) != 1L ||
      !is.finite(rgb_tolerance) || rgb_tolerance < 0) {
    stop("`rgb_tolerance` must be one finite non-negative number.", call. = FALSE)
  }

  extension <- tolower(tools::file_ext(path))
  image <- switch(
    extension,
    png = png::readPNG(path),
    jpg = jpeg::readJPEG(path),
    jpeg = jpeg::readJPEG(path),
    stop("Unsupported image extension: ", extension, call. = FALSE)
  )

  if (length(dim(image)) == 2L) {
    intensity <- image
  } else if (length(dim(image)) == 3L && dim(image)[3L] >= 3L) {
    rgb <- image[, , 1:3, drop = FALSE]
    channel_difference <- max(
      abs(rgb[, , 1] - rgb[, , 2]),
      abs(rgb[, , 1] - rgb[, , 3]),
      abs(rgb[, , 2] - rgb[, , 3]),
      na.rm = TRUE
    )
    if (channel_difference > rgb_tolerance && !allow_color) {
      stop(
        "The file is a colored RGB image. Use an original grayscale or concentration map.",
        call. = FALSE
      )
    }
    if (channel_difference > rgb_tolerance) {
      warning(
        "Converting color to luminance; luminance is not concentration.",
        call. = FALSE
      )
      intensity <- 0.299 * rgb[, , 1] + 0.587 * rgb[, , 2] + 0.114 * rgb[, , 3]
    } else {
      intensity <- (rgb[, , 1] + rgb[, , 2] + rgb[, , 3]) / 3
    }
    dim(intensity) <- dim(image)[1:2]
  } else {
    stop("The image must be two-dimensional grayscale or RGB.", call. = FALSE)
  }

  intensity <- as.matrix(intensity)
  intensity[] <- pmin(1, pmax(0, intensity))
  if (invert) intensity <- 1 - intensity
  intensity
}
