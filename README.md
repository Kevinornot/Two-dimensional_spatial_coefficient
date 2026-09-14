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
