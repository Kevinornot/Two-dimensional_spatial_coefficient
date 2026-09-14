# DGT2Dpearsonr Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, verify and privately publish an anonymized R package for pixel-wise Pearson correlation of aligned two-dimensional DGT intensity maps.

**Architecture:** Keep image input, matrix correlation and multi-element orchestration in separate R files. Public functions accept generic paths or matrices, return base R data structures and reject pseudocolor images by default. Tests use only temporary synthetic images and matrices.

**Tech Stack:** R >= 4.1.0, base `stats`, `png`, `jpeg`, `testthat` edition 3, `roxygen2`, Git and GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-14-dgt2dpearsonr-design.md`

## Global Constraints

- The GitHub repository is named `Two-dimensional_DGT_spatial_coefficient` and is private by default.
- The R package name is `DGT2Dpearsonr`.
- Package metadata uses `DGT2Dpearsonr Contributors <maintainer@example.org>`.
- Runtime dependencies are limited to `png` and `jpeg`; `testthat` is a suggested dependency.
- Do not commit local absolute paths, personal names, personal email addresses, credentials, real sample labels, research images, PPTX files or experimental data.
- Do not calculate conventional pixel-level Pearson p-values.
- Do not decode pseudocolor maps or perform image registration in version 0.1.0.
- Every exported function needs a failing test before production code is added.

## File Structure

```text
Two-dimensional_DGT_spatial_coefficient/
├── .Rbuildignore
├── .gitignore
├── .github/workflows/R-CMD-check.yaml
├── DESCRIPTION
├── LICENSE
├── LICENSE.md
├── NAMESPACE
├── README.md
├── R/
│   ├── batch_dgt_cor.R
│   ├── pairwise_dgt_cor.R
│   ├── pearson_2d.R
│   ├── read_dgt_image.R
│   └── validation.R
├── man/
├── tests/testthat.R
└── tests/testthat/
    ├── test-batch_dgt_cor.R
    ├── test-pairwise_dgt_cor.R
    ├── test-pearson_2d.R
    └── test-read_dgt_image.R
```

---

### Task 1: Package scaffold and safe image reader

**Files:**
- Create: `DESCRIPTION`
- Create: `LICENSE`
- Create: `LICENSE.md`
- Create: `.Rbuildignore`
- Create: `.gitignore`
- Create: `tests/testthat.R`
- Create: `tests/testthat/test-read_dgt_image.R`
- Create: `R/read_dgt_image.R`
- Generated: `NAMESPACE`
- Generated: `man/read_dgt_image.Rd`

**Interfaces:**
- Consumes: PNG or JPEG paths.
- Produces: `read_dgt_image(path, invert = FALSE, allow_color = FALSE, rgb_tolerance = 0.02)`, returning a numeric matrix in `[0, 1]`.

- [ ] **Step 1: Create package metadata and the test runner**

Create `DESCRIPTION` with this content:

```text
Package: DGT2Dpearsonr
Title: Pixel-Wise Pearson Correlation for Two-Dimensional DGT Maps
Version: 0.1.0
Authors@R: person("DGT2Dpearsonr", "Contributors", email = "maintainer@example.org", role = c("aut", "cre"))
Description: Computes descriptive pixel-wise Pearson correlation coefficients
    for aligned two-dimensional diffusive gradients in thin films intensity
    maps. Includes strict image validation, optional edge cropping, three-element
    pairwise analysis, and batch processing from a manifest table.
License: MIT + file LICENSE
Encoding: UTF-8
Roxygen: list(markdown = TRUE)
RoxygenNote: 7.3.3
Depends: R (>= 4.1.0)
Imports:
    jpeg,
    png,
    stats
Suggests:
    testthat (>= 3.0.0)
Config/testthat/edition: 3
```

Create `LICENSE`:

```text
YEAR: 2026
COPYRIGHT HOLDER: DGT2Dpearsonr Contributors
```

Create `LICENSE.md`:

```text
MIT License

Copyright (c) 2026 DGT2Dpearsonr Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Create `.Rbuildignore`:

```text
^.*\.Rproj$
^\.Rproj\.user$
^\.github$
^docs/superpowers$
^LICENSE\.md$
```

Create `.gitignore`:

```text
.Rproj.user
.Rhistory
.RData
.Ruserdata
*.Rcheck/
*.tar.gz
```

Create `tests/testthat.R`:

```r
library(testthat)
library(DGT2Dpearsonr)

test_check("DGT2Dpearsonr")
```

- [ ] **Step 2: Write failing image-reader tests**

Create `tests/testthat/test-read_dgt_image.R`:

```r
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
```

- [ ] **Step 3: Run the reader tests and confirm the RED state**

Run:

```powershell
Rscript -e "devtools::test(filter = 'read_dgt_image')"
```

Expected: tests fail because `read_dgt_image()` does not exist.

- [ ] **Step 4: Implement the minimal image reader**

Create `R/read_dgt_image.R`:

```r
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
  } else {
    stop("The image must be two-dimensional grayscale or RGB.", call. = FALSE)
  }

  intensity <- pmin(1, pmax(0, as.matrix(intensity)))
  if (invert) intensity <- 1 - intensity
  intensity
}
```

- [ ] **Step 5: Verify GREEN and generate documentation**

Run:

```powershell
Rscript -e "roxygen2::roxygenise(); devtools::test(filter = 'read_dgt_image')"
```

Expected: all reader tests pass and `NAMESPACE` exports `read_dgt_image`.

- [ ] **Step 6: Commit the reader feature**

```powershell
git add DESCRIPTION LICENSE LICENSE.md .Rbuildignore .gitignore NAMESPACE R/read_dgt_image.R man/read_dgt_image.Rd tests/testthat.R tests/testthat/test-read_dgt_image.R
git commit -m "feat: add safe DGT image reader"
```

---

### Task 2: Pixel-wise Pearson correlation

**Files:**
- Create: `tests/testthat/test-pearson_2d.R`
- Create: `R/validation.R`
- Create: `R/pearson_2d.R`
- Generated: `man/pearson_2d.Rd`
- Modify: `NAMESPACE`

**Interfaces:**
- Consumes: two aligned numeric matrices.
- Produces: `pearson_2d(x, y, crop = 0, use = "complete.obs")`, returning one numeric coefficient.
- Internal: `.paired_dgt_pixels(x, y, crop, use)` returns `list(x, y, n_pixels, return_na)`.

- [ ] **Step 1: Write failing correlation tests**

Create `tests/testthat/test-pearson_2d.R`:

```r
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
```

- [ ] **Step 2: Run the correlation tests and confirm the RED state**

Run:

```powershell
Rscript -e "devtools::test(filter = 'pearson_2d')"
```

Expected: tests fail because `pearson_2d()` does not exist.

- [ ] **Step 3: Implement matrix validation, cropping and correlation**

Create `R/validation.R`:

```r
.validate_dgt_matrix <- function(x, name) {
  if (!is.matrix(x) || !is.numeric(x)) {
    stop("`", name, "` must be a numeric matrix.", call. = FALSE)
  }
  if (any(dim(x) < 1L)) {
    stop("`", name, "` must have non-zero dimensions.", call. = FALSE)
  }
  x
}

.normalize_crop <- function(crop) {
  if (!is.numeric(crop) || !(length(crop) %in% c(1L, 4L)) ||
      any(!is.finite(crop)) || any(crop < 0) || any(crop >= 0.5)) {
    stop("`crop` must contain one or four finite fractions from 0 to less than 0.5.", call. = FALSE)
  }
  if (length(crop) == 1L) rep(crop, 4L) else crop
}

.crop_dgt_matrix <- function(x, crop) {
  crop <- .normalize_crop(crop)
  nr <- nrow(x)
  nc <- ncol(x)
  removed <- floor(c(nr, nc, nr, nc) * crop)
  rows <- seq.int(removed[1] + 1L, nr - removed[3])
  cols <- seq.int(removed[4] + 1L, nc - removed[2])
  if (length(rows) < 1L || length(cols) < 1L) {
    stop("`crop` removes the entire matrix.", call. = FALSE)
  }
  x[rows, cols, drop = FALSE]
}

.paired_dgt_pixels <- function(x, y, crop, use) {
  x <- .validate_dgt_matrix(x, "x")
  y <- .validate_dgt_matrix(y, "y")
  if (!identical(dim(x), dim(y))) {
    stop("`x` and `y` must have identical dimensions.", call. = FALSE)
  }
  use <- match.arg(use, c("complete.obs", "everything"))
  x <- as.vector(.crop_dgt_matrix(x, crop))
  y <- as.vector(.crop_dgt_matrix(y, crop))
  valid <- is.finite(x) & is.finite(y)
  if (sum(valid) < 2L) {
    stop("At least two valid paired pixels are required.", call. = FALSE)
  }
  if (use == "everything" && !all(valid)) {
    return(list(x = x[valid], y = y[valid], n_pixels = sum(valid), return_na = TRUE))
  }
  x <- x[valid]
  y <- y[valid]
  if (stats::sd(x) == 0 || stats::sd(y) == 0) {
    stop("Pearson correlation is undefined for zero variance.", call. = FALSE)
  }
  list(x = x, y = y, n_pixels = length(x), return_na = FALSE)
}
```

Create `R/pearson_2d.R`:

```r
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
```

- [ ] **Step 4: Verify GREEN and regenerate documentation**

Run:

```powershell
Rscript -e "roxygen2::roxygenise(); devtools::test(filter = 'pearson_2d')"
```

Expected: all correlation tests pass.

- [ ] **Step 5: Commit the correlation feature**

```powershell
git add NAMESPACE R/validation.R R/pearson_2d.R man/pearson_2d.Rd tests/testthat/test-pearson_2d.R
git commit -m "feat: calculate pixel-wise Pearson correlation"
```

---

### Task 3: Three-element pairwise analysis

**Files:**
- Create: `tests/testthat/test-pairwise_dgt_cor.R`
- Create: `R/pairwise_dgt_cor.R`
- Generated: `man/pairwise_dgt_cor.Rd`
- Modify: `NAMESPACE`

**Interfaces:**
- Consumes: aligned `fe`, `s` and `p` numeric matrices.
- Produces: `pairwise_dgt_cor(fe, s, p, crop = 0, use = "complete.obs")`, returning columns `pair`, `n_pixels`, `pearson_r` in Fe–S, S–P, Fe–P order.

- [ ] **Step 1: Write the failing pairwise test**

Create `tests/testthat/test-pairwise_dgt_cor.R`:

```r
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
```

- [ ] **Step 2: Run the pairwise tests and confirm the RED state**

Run:

```powershell
Rscript -e "devtools::test(filter = 'pairwise_dgt_cor')"
```

Expected: tests fail because `pairwise_dgt_cor()` does not exist.

- [ ] **Step 3: Implement the pairwise function**

Create `R/pairwise_dgt_cor.R`:

```r
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
```

- [ ] **Step 4: Verify GREEN and regenerate documentation**

Run:

```powershell
Rscript -e "roxygen2::roxygenise(); devtools::test(filter = 'pairwise_dgt_cor')"
```

Expected: all pairwise tests pass.

- [ ] **Step 5: Commit the pairwise feature**

```powershell
git add NAMESPACE R/pairwise_dgt_cor.R man/pairwise_dgt_cor.Rd tests/testthat/test-pairwise_dgt_cor.R
git commit -m "feat: compare Fe S and P maps"
```

---

### Task 4: Batch manifest processing

**Files:**
- Create: `tests/testthat/test-batch_dgt_cor.R`
- Create: `R/batch_dgt_cor.R`
- Generated: `man/batch_dgt_cor.Rd`
- Modify: `NAMESPACE`

**Interfaces:**
- Consumes: a data frame with `sample`, `Fe`, `S`, `P` file columns.
- Produces: `batch_dgt_cor()` returning `sample`, `pair`, `n_pixels`, `pearson_r`.

- [ ] **Step 1: Write failing batch tests**

Create `tests/testthat/test-batch_dgt_cor.R`:

```r
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
```

- [ ] **Step 2: Run the batch tests and confirm the RED state**

Run:

```powershell
Rscript -e "devtools::test(filter = 'batch_dgt_cor')"
```

Expected: tests fail because `batch_dgt_cor()` does not exist.

- [ ] **Step 3: Implement batch processing**

Create `R/batch_dgt_cor.R`:

```r
.normalize_invert <- function(invert) {
  if (!is.logical(invert) || anyNA(invert)) {
    stop("`invert` must be logical.", call. = FALSE)
  }
  if (length(invert) == 1L) {
    return(base::setNames(rep(invert, 3L), c("Fe", "S", "P")))
  }
  if (length(invert) == 3L && setequal(names(invert), c("Fe", "S", "P"))) {
    return(invert[c("Fe", "S", "P")])
  }
  stop("`invert` must be one logical value or a named Fe, S and P vector.", call. = FALSE)
}

#' Batch Fe-S-P correlation from an image manifest
#'
#' @param manifest Data frame with sample, Fe, S and P columns.
#' @param crop Edge crop passed to [pairwise_dgt_cor()].
#' @param invert One logical value or a named Fe, S and P logical vector.
#' @param allow_color Whether to permit luminance conversion of colored images.
#' @param rgb_tolerance Maximum channel difference treated as grayscale.
#' @param use Missing-value behavior passed to [pearson_2d()].
#'
#' @return A long data frame with sample, pair, valid-pixel count and Pearson r.
#' @export
batch_dgt_cor <- function(manifest, crop = 0, invert = FALSE,
                          allow_color = FALSE, rgb_tolerance = 0.02,
                          use = "complete.obs") {
  required <- c("sample", "Fe", "S", "P")
  if (!is.data.frame(manifest) || !all(required %in% names(manifest))) {
    stop("`manifest` must contain required columns: sample, Fe, S and P.", call. = FALSE)
  }
  if (anyDuplicated(manifest$sample)) {
    stop("`manifest` contains a duplicate sample identifier.", call. = FALSE)
  }
  directions <- .normalize_invert(invert)
  rows <- lapply(seq_len(nrow(manifest)), function(index) {
    maps <- lapply(c("Fe", "S", "P"), function(element) {
      read_dgt_image(
        manifest[[element]][index],
        invert = directions[[element]],
        allow_color = allow_color,
        rgb_tolerance = rgb_tolerance
      )
    })
    names(maps) <- c("Fe", "S", "P")
    result <- pairwise_dgt_cor(maps$Fe, maps$S, maps$P, crop = crop, use = use)
    result$sample <- as.character(manifest$sample[index])
    result[c("sample", "pair", "n_pixels", "pearson_r")]
  })
  do.call(rbind, rows)
}
```

- [ ] **Step 4: Verify GREEN and regenerate documentation**

Run:

```powershell
Rscript -e "roxygen2::roxygenise(); devtools::test(filter = 'batch_dgt_cor')"
```

Expected: all batch tests pass.

- [ ] **Step 5: Commit the batch feature**

```powershell
git add NAMESPACE R/batch_dgt_cor.R man/batch_dgt_cor.Rd tests/testthat/test-batch_dgt_cor.R
git commit -m "feat: add manifest-based batch analysis"
```

---

### Task 5: Documentation, continuous integration and release verification

**Files:**
- Create: `README.md`
- Create: `.github/workflows/R-CMD-check.yaml`
- Modify: generated documentation when required.

**Interfaces:**
- Consumes: the complete package API from Tasks 1–4.
- Produces: documented installation and usage examples, automated checks and a verified private GitHub repository.

- [ ] **Step 1: Write README examples that exercise the public API**

Create `README.md` with this content:

````markdown
# DGT2Dpearsonr

`DGT2Dpearsonr` calculates descriptive pixel-wise Pearson correlation coefficients for spatially aligned two-dimensional DGT intensity maps. It supports direct matrix analysis and batch Fe-S-P comparison from PNG or JPEG images.

## Installation

From the package checkout, run:

```r
install.packages(".", repos = NULL, type = "source")
```

## Matrix input

```r
library(DGT2Dpearsonr)

set.seed(1)
fe <- matrix(seq(0, 1, length.out = 100), 10, 10)
s <- fe + matrix(rnorm(100, sd = 0.05), 10, 10)
p <- 1 - fe

pearson_2d(fe, s)
pairwise_dgt_cor(fe, s, p, crop = 0.05)
```

`pairwise_dgt_cor()` returns one row for each of Fe-S, S-P and Fe-P. `pearson_r` is the descriptive Pearson coefficient and `n_pixels` is the number of finite paired pixels used after cropping.

## Batch image input

The manifest must contain `sample`, `Fe`, `S` and `P` columns. Image columns contain file paths.

```r
directory <- tempdir()
base_map <- matrix(seq(0, 1, length.out = 100), 10, 10)

write_map <- function(x, name) {
  path <- file.path(directory, paste0(name, ".png"))
  png::writePNG(x, path)
  path
}

manifest <- data.frame(
  sample = c("sample-A", "sample-B"),
  Fe = c(write_map(base_map, "a-fe"), write_map(base_map, "b-fe")),
  S = c(write_map(base_map, "a-s"), write_map(base_map * 0.8, "b-s")),
  P = c(write_map(1 - base_map, "a-p"), write_map(base_map, "b-p")),
  stringsAsFactors = FALSE
)

batch_dgt_cor(manifest, crop = 0.05)
```

Use `invert = c(Fe = FALSE, S = TRUE, P = FALSE)` when one element's grayscale direction is reversed.

## Input requirements

- Maps compared with each other must already be spatially registered and have identical pixel dimensions.
- `crop` is either one edge fraction or four fractions in top, right, bottom, left order. Every value must be at least 0 and less than 0.5.
- PNG and JPEG grayscale intensity maps are supported. Colored pseudocolor maps are rejected by default because RGB luminance is not a concentration value.
- `allow_color = TRUE` enables luminance conversion with a warning. Use this only when that approximation is scientifically justified.

## Interpretation

Pearson `r` ranges from -1 to 1 and describes linear pixel-wise co-variation. Spatial autocorrelation means ordinary pixel-level significance tests are not valid, so this package does not report conventional p-values. Treat the coefficient as descriptive unless uncertainty is assessed using a spatially appropriate method.
````

- [ ] **Step 2: Add GitHub Actions R CMD check**

Create `.github/workflows/R-CMD-check.yaml`:

```yaml
name: R-CMD-check

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  R-CMD-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true
      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::rcmdcheck
          needs: check
      - uses: r-lib/actions/check-r-package@v2
```

- [ ] **Step 3: Run the full local verification suite**

Run:

```powershell
Rscript -e "roxygen2::roxygenise(); devtools::test(); devtools::check(document = FALSE, cran = TRUE, error_on = 'warning')"
```

Expected: all tests pass and package check reports 0 errors and 0 warnings. Resolve any note caused by package content when possible; record unavoidable environment-only notes exactly.

- [ ] **Step 4: Build and check the source archive**

Run:

```powershell
R CMD build .
R CMD check --as-cran DGT2Dpearsonr_0.1.0.tar.gz
```

Expected: the archive builds and the check reports 0 errors and 0 warnings.

- [ ] **Step 5: Run privacy and repository-boundary scans**

Run:

```powershell
git status --short
git ls-files
git grep -nEI "(C:|D:|/Users/|/home/|P_immobilization|钝化试验|CK|LMB|NLMB|password|api[_-]?key|access[_-]?token|secret)" -- DESCRIPTION NAMESPACE R tests man README.md .github LICENSE LICENSE.md .Rbuildignore .gitignore
git grep -nEI "[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}" -- DESCRIPTION NAMESPACE R tests man README.md .github LICENSE LICENSE.md .Rbuildignore .gitignore
git ls-files | rg -i "\.(pptx|ppt|tif|tiff|png|jpe?g|csv|xlsx?|rds|rdata)$"
```

Expected: the sensitive-text scan returns no matches; the email scan returns only `maintainer@example.org`; the data-file extension scan returns no matches. Confirm that `git ls-files` contains only package source, documentation, tests, CI configuration and the two approved design documents.

- [ ] **Step 6: Commit release documentation**

```powershell
git add README.md .github/workflows/R-CMD-check.yaml DESCRIPTION NAMESPACE R man tests LICENSE LICENSE.md .Rbuildignore .gitignore
git commit -m "docs: prepare anonymized package release"
git status --short
```

Expected: the working tree is clean.

- [ ] **Step 7: Create the private GitHub repository**

Open GitHub in the authenticated browser session, read the signed-in account identifier from the account menu, and create a private repository named exactly `Two-dimensional_DGT_spatial_coefficient`. Do not initialize it with a README, license or `.gitignore` because those files already exist locally.

- [ ] **Step 8: Add the discovered remote and push**

After recording the account identifier as `$github_owner`, run:

```powershell
$remote_url = "https://github.com/$github_owner/Two-dimensional_DGT_spatial_coefficient.git"
git remote add origin $remote_url
git push -u origin main
git remote -v
git status --short
```

Expected: `main` tracks `origin/main`, push exits successfully and the working tree remains clean. Do not print or store authentication tokens.

- [ ] **Step 9: Verify the published repository**

Open the repository page and confirm that it is marked Private, displays package files, excludes research data and shows the R CMD check workflow. Report the repository URL, package version, test count and exact local check status.
