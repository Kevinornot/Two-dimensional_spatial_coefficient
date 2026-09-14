test_that("pearson_2d returns perfect positive and negative correlation", {
  x <- matrix(1:16, 4, 4)
  expect_equal(pearson_2d(x, x), 1)
  expect_equal(pearson_2d(x, -x), -1)
})

test_that("pearson_2d removes non-finite pairs for complete observations", {
  x <- matrix(1:9, 3, 3)
  y <- x
  x[1, 1] <- NA_real_
  y[2, 2] <- Inf

  expect_equal(pearson_2d(x, y), 1)
  expect_true(is.na(pearson_2d(x, y, use = "everything")))
})

test_that("pearson_2d applies scalar and four-edge crop fractions", {
  x <- matrix(1:36, 6, 6)
  y <- x
  y[c(1, 6), ] <- -y[c(1, 6), ]
  y[, c(1, 6)] <- -y[, c(1, 6)]

  expect_equal(pearson_2d(x, y, crop = 1 / 6), 1)
  expect_equal(pearson_2d(x, y, crop = c(1 / 6, 1 / 6, 1 / 6, 1 / 6)), 1)
})

test_that("pearson_2d rejects invalid inputs", {
  expect_error(pearson_2d(matrix(letters[1:4], 2), matrix(1:4, 2)), "numeric matrix")
  expect_error(pearson_2d(matrix(1:4, 2), matrix(1:6, 2)), "identical dimensions")
  expect_error(pearson_2d(matrix(1, 2, 2), matrix(1, 2, 2)), "zero variance")
  expect_error(pearson_2d(matrix(1:4, 2), matrix(1:4, 2), crop = 0.5), "less than 0.5")
  expect_error(pearson_2d(matrix(1:4, 2), matrix(1:4, 2), use = "bad"), "use")
})
