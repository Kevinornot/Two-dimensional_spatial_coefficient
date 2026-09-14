# DGT2Dpearsonr Design Specification

## Purpose

`DGT2Dpearsonr` is an R package for reproducible pixel-wise Pearson correlation analysis of aligned two-dimensional DGT intensity maps. It supports a single image pair, the three element pairs Fe–S, S–P and Fe–P, and batch processing through a manifest table.

The GitHub repository is named `Two-dimensional_DGT_spatial_coefficient`. The repository will be private by default.

## Scope

The first release provides:

- reading PNG and JPEG grayscale intensity images;
- accepting numeric matrices directly;
- optional intensity inversion;
- configurable fractional edge cropping;
- strict dimension and data validation;
- pixel-wise Pearson correlation without an ordinary pixel-level significance test;
- pairwise Fe–S, S–P and Fe–P analysis;
- batch analysis from a manifest data frame;
- CSV-compatible tidy output;
- documentation, tests, an anonymous synthetic example and GitHub Actions checks.

The first release does not provide:

- PPTX extraction;
- pseudocolor or colorbar inversion;
- image registration or automatic geometric alignment;
- Moran’s I, Lee’s L or other distance-weighted spatial statistics;
- inferential p-values that treat spatially autocorrelated pixels as independent replicates.

## Package identity

- Repository: `Two-dimensional_DGT_spatial_coefficient`
- Package: `DGT2Dpearsonr`
- Minimum R version: 4.1.0
- License: MIT
- Runtime dependencies: `png`, `jpeg`
- Test dependency: `testthat` edition 3

Package metadata uses a generic contributor identity and the reserved `example.org` domain. It contains no personal name, personal email address, username or workstation path.

## Public API

### `read_dgt_image()`

```r
read_dgt_image(
  path,
  invert = FALSE,
  allow_color = FALSE,
  rgb_tolerance = 0.02
)
```

Reads a PNG or JPEG file and returns a numeric matrix scaled to the interval `[0, 1]`.

- A two-dimensional image is returned directly.
- An RGB image whose channels differ by no more than `rgb_tolerance` is treated as grayscale and converted by channel averaging.
- A genuinely colored RGB image raises an error by default because luminance from a pseudocolor image is not concentration.
- `allow_color = TRUE` permits luminance conversion using weights `0.299`, `0.587` and `0.114` and emits a warning.
- `invert = TRUE` returns `1 - x`.

### `pearson_2d()`

```r
pearson_2d(x, y, crop = 0, use = "complete.obs")
```

Calculates the Pearson correlation coefficient between corresponding pixels in two numeric matrices.

- `x` and `y` must have identical dimensions.
- `crop` accepts one fraction applied to all edges or four fractions in `c(top, right, bottom, left)` order.
- Each crop fraction must be finite, non-negative and less than `0.5`.
- Cropping must leave at least two valid paired pixels.
- Constant matrices raise an error because Pearson correlation is undefined.
- The return value is one numeric scalar in `[-1, 1]`.

### `pairwise_dgt_cor()`

```r
pairwise_dgt_cor(fe, s, p, crop = 0, use = "complete.obs")
```

Calculates Fe–S, S–P and Fe–P correlations from three aligned matrices. It returns a three-row data frame with columns `pair`, `n_pixels` and `pearson_r`.

### `batch_dgt_cor()`

```r
batch_dgt_cor(
  manifest,
  crop = 0,
  invert = FALSE,
  allow_color = FALSE,
  rgb_tolerance = 0.02,
  use = "complete.obs"
)
```

Processes a manifest with required columns `sample`, `Fe`, `S` and `P`. File columns contain PNG or JPEG paths. The output is a long data frame with columns `sample`, `pair`, `n_pixels` and `pearson_r`.

`invert` may be one logical value for all elements or a named logical vector with names `Fe`, `S` and `P`.

## Validation and errors

Functions reject:

- missing or unsupported image files;
- non-numeric matrices;
- matrices with different dimensions;
- invalid crop specifications;
- fewer than two valid paired pixels;
- zero-variance inputs;
- manifests with missing required columns or duplicate sample identifiers;
- pseudocolor images unless the caller explicitly enables luminance conversion.

Errors identify the affected file, sample or argument without printing unrelated environment information.

## Statistical interpretation

The package reports a descriptive pixel-wise Pearson coefficient. It does not label the coefficient as a distance-weighted spatial statistic. Because adjacent pixels are spatially autocorrelated, the package does not calculate the conventional Pearson p-value by treating all pixels as independent observations.

Users must align and register maps before analysis. The README and function documentation state that results from independently resized or unregistered maps can be misleading.

## Documentation

The repository contains:

- a concise README with installation, matrix and batch examples;
- roxygen2-generated help for every exported function;
- a synthetic Fe/S/P example with generic sample names;
- a section explaining why pseudocolor images are rejected by default;
- a reproducibility note describing alignment, crop settings and pixel counts.

No documentation contains actual experimental values, sample identifiers, image files or local paths.

## Testing

Tests cover:

- perfect positive and negative correlation;
- missing-value handling and valid-pixel counts;
- mismatched dimensions;
- constant matrices;
- scalar and four-edge cropping;
- PNG and JPEG grayscale reading;
- pseudocolor rejection and explicit opt-in warning;
- inversion;
- Fe–S, S–P and Fe–P output order;
- batch manifest validation and output shape.

The release gate requires:

- all `testthat` tests passing;
- `R CMD check --as-cran` completing without errors or warnings;
- no personal names, private paths, credentials, tokens, PPTX files or real data found by repository scans;
- a clean Git status before pushing;
- successful push to the private GitHub repository.

## Repository privacy boundary

Only package source, documentation, synthetic fixtures, tests, license files and CI configuration may be committed. Parent directories and existing research materials remain outside the repository and must never be staged.

The final pre-push scan checks tracked content and filenames for:

- workstation usernames and home-directory patterns;
- Windows drive paths and Unix home paths;
- email addresses other than the reserved package contact;
- credential terms and token-like strings;
- PPTX, TIFF and real experimental-data file extensions;
- known treatment and sample labels from the source project.

## Release workflow

1. Build functionality with test-driven development.
2. Generate documentation.
3. Run unit tests and package checks.
4. Run privacy and secret scans against the Git index.
5. Create a private GitHub repository named `Two-dimensional_DGT_spatial_coefficient`.
6. Push the verified default branch.
7. Report the repository URL and the exact package check result.
