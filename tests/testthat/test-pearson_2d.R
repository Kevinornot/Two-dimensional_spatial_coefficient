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

test_that("asymmetric crops round down in top right bottom left order", {
  x <- matrix(1:120, 10, 12)
  y <- matrix((1:120)^2 %% 97, 10, 12)
  # Remove 1 top row, 3 right columns, 2 bottom rows and 4 left columns.
  expected <- cor(as.vector(x[2:8, 5:9]), as.vector(y[2:8, 5:9]))

  expect_equal(pearson_2d(x, y, crop = c(0.19, 0.26, 0.21, 0.34)), expected)
})
