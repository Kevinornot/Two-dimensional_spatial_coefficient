test_that("read_dgt_image reads grayscale PNG and supports inversion", {
  x <- matrix(seq(0, 1, length.out = 16), 4, 4)
  file <- tempfile(fileext = ".png")
  png::writePNG(x, file)

  observed <- read_dgt_image(file)
  inverted <- read_dgt_image(file, invert = TRUE)

  expect_equal(dim(observed), c(4L, 4L))
  expect_equal(observed, x, tolerance = 1 / 255)
  expect_equal(inverted, 1 - observed)
})

test_that("read_dgt_image reads grayscale JPEG", {
  x <- matrix(seq(0.1, 0.9, length.out = 64), 8, 8)
  rgb <- array(rep(x, 3), dim = c(8, 8, 3))
  file <- tempfile(fileext = ".jpg")
  jpeg::writeJPEG(rgb, file, quality = 1)

  observed <- read_dgt_image(file)

  expect_equal(dim(observed), c(8L, 8L))
  expect_true(all(observed >= 0 & observed <= 1))
})

test_that("read_dgt_image rejects pseudocolor unless explicitly allowed", {
  color <- array(0, dim = c(3, 3, 3))
  color[, , 1] <- 1
  file <- tempfile(fileext = ".png")
  png::writePNG(color, file)

  expect_error(read_dgt_image(file), "colored RGB image")
  expect_warning(
    observed <- read_dgt_image(file, allow_color = TRUE),
    "luminance is not concentration"
  )
  expect_equal(dim(observed), c(3L, 3L))
})

test_that("read_dgt_image validates arguments and extensions", {
  file <- tempfile(fileext = ".bmp")
  writeBin(as.raw(1:4), file)

  expect_error(read_dgt_image(file), "Unsupported image extension")
  expect_error(read_dgt_image("missing.png"), "does not exist")
  expect_error(read_dgt_image(file, rgb_tolerance = -1), "rgb_tolerance")
})

test_that("RGB grayscale conversion preserves singleton image axes", {
  for (shape in list(c(1L, 4L), c(4L, 1L))) {
    x <- matrix(c(0, 1 / 3, 2 / 3, 1), nrow = shape[1], ncol = shape[2])
    file <- tempfile(fileext = ".png")
    png::writePNG(array(rep(x, 3), dim = c(shape, 3L)), file)

    observed <- read_dgt_image(file)

    expect_identical(dim(observed), shape)
    expect_equal(as.vector(observed), as.vector(x), tolerance = 1 / 255)
    inverted <- read_dgt_image(file, invert = TRUE)
    expect_identical(dim(inverted), shape)
    expect_equal(as.vector(inverted), as.vector(1 - x), tolerance = 1 / 255)
  }
})

test_that("explicit RGB luminance conversion preserves singleton image axes", {
  for (shape in list(c(1L, 4L), c(4L, 1L))) {
    x <- matrix(c(0, 1 / 3, 2 / 3, 1), nrow = shape[1], ncol = shape[2])
    color <- array(0, dim = c(shape, 3L))
    color[, , 1] <- x
    file <- tempfile(fileext = ".png")
    png::writePNG(color, file)

    expect_warning(
      observed <- read_dgt_image(file, allow_color = TRUE),
      "luminance is not concentration"
    )
    expect_identical(dim(observed), shape)
    expect_equal(as.vector(observed), as.vector(0.299 * x), tolerance = 1 / 255)
  }
})
