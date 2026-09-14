test_that("batch_dgt_cor processes samples in manifest order", {
  directory <- tempfile()
  dir.create(directory)
  base <- matrix(seq(0, 1, length.out = 25), 5, 5)
  paths <- file.path(directory, paste0(c("a_fe", "a_s", "a_p", "b_fe", "b_s", "b_p"), ".png"))
  images <- list(base, base, 1 - base, base, base * 0.5, base)
  Map(png::writePNG, images, paths)
  manifest <- data.frame(
    sample = c("sample-A", "sample-B"),
    Fe = paths[c(1, 4)],
    S = paths[c(2, 5)],
    P = paths[c(3, 6)],
    stringsAsFactors = FALSE
  )

  observed <- batch_dgt_cor(manifest)

  expect_identical(observed$sample, rep(manifest$sample, each = 3))
  expect_identical(observed$pair, rep(c("Fe-S", "S-P", "Fe-P"), 2))
  expect_equal(nrow(observed), 6L)
})

test_that("batch_dgt_cor supports element-specific inversion", {
  directory <- tempfile()
  dir.create(directory)
  x <- matrix(seq(0, 1, length.out = 25), 5, 5)
  files <- file.path(directory, paste0(c("fe", "s", "p"), ".png"))
  png::writePNG(x, files[1])
  png::writePNG(1 - x, files[2])
  png::writePNG(x, files[3])
  manifest <- data.frame(sample = "sample-A", Fe = files[1], S = files[2], P = files[3])

  observed <- batch_dgt_cor(manifest, invert = c(Fe = FALSE, S = TRUE, P = FALSE))

  expect_equal(observed$pearson_r, rep(1, 3), tolerance = 1 / 255)
})

test_that("batch_dgt_cor validates the manifest and invert argument", {
  expect_error(batch_dgt_cor(data.frame(sample = "a")), "required columns")
  duplicate <- data.frame(sample = c("a", "a"), Fe = "x", S = "x", P = "x")
  expect_error(batch_dgt_cor(duplicate), "duplicate sample")
  manifest <- data.frame(sample = "a", Fe = "x", S = "x", P = "x")
  expect_error(batch_dgt_cor(manifest, invert = c(TRUE, FALSE)), "invert")
})

test_that("batch_dgt_cor returns a typed empty result for an empty manifest", {
  manifest <- data.frame(
    sample = character(),
    Fe = character(),
    S = character(),
    P = character(),
    stringsAsFactors = FALSE
  )

  observed <- batch_dgt_cor(manifest)

  expect_s3_class(observed, "data.frame")
  expect_identical(names(observed), c("sample", "pair", "n_pixels", "pearson_r"))
  expect_identical(vapply(observed, typeof, character(1)),
                   c(sample = "character", pair = "character", n_pixels = "integer", pearson_r = "double"))
  expect_equal(nrow(observed), 0L)
})
