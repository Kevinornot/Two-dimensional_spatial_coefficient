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
