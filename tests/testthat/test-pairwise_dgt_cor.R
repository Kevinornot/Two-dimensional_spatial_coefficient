test_that("pairwise_dgt_cor returns Fe-S, S-P and Fe-P in order", {
  fe <- matrix(1:16, 4, 4)
  s <- fe * 2
  p <- -fe

  observed <- pairwise_dgt_cor(fe, s, p)

  expect_identical(observed$pair, c("Fe-S", "S-P", "Fe-P"))
  expect_equal(observed$n_pixels, rep(16L, 3))
  expect_equal(observed$pearson_r, c(1, -1, -1))
})

test_that("pairwise_dgt_cor applies the same crop to every pair", {
  fe <- matrix(1:36, 6, 6)
  s <- fe
  p <- fe
  observed <- pairwise_dgt_cor(fe, s, p, crop = 1 / 6)
  expect_equal(observed$n_pixels, rep(16L, 3))
})

test_that("pairwise_dgt_cor reports pair-specific valid-pixel counts", {
  fe <- matrix(1:16, 4, 4)
  s <- fe
  p <- -fe
  s[1, 1] <- NA_real_
  p[2, 2] <- Inf

  observed <- pairwise_dgt_cor(fe, s, p)

  expect_equal(observed$n_pixels, c(15L, 14L, 15L))
  expect_equal(observed$pearson_r, c(1, -1, -1))
})
