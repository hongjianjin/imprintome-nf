# imprintome-nf: Changelog

## v1.6.0dev - [unreleased]

Runs imprintomeR 1.6.0. Sample-level scores and per-ICR calls with default settings are
unchanged from 1.5.3 (see the imprintomeR 1.6.0 release notes for its bug fixes).

### Pipeline

- New uncertainty options for `RUN_IMPRINTOMER`: `--n_boot`, `--resample`, `--conf_level`,
  `--resample_reference`, `--n_perm`, `--permute`, `--seed` (off by default). Invalid
  combinations (`--resample_reference` without `--reference_group`, `--n_perm` without a
  control reference) stop the run before QC.
- `--skip_ewastools` is deprecated and ignored (no longer passed to `run_meth_QC.R`); the
  control-probe and SNP checks are built into imprintomeR 1.6.0 and always run.

### Container

- `ghcr.io/hongjianjin/imprintomer:1.6.0`: imprintomeR v1.6.0; ewastools removed, illuminaio
  added; pheatmap, Rtsne and cowplot installed explicitly (now Suggests in imprintomeR).

### Outputs

- `methqc/<platform>/` contamination table is now one long table (`donor1`, `sample1`,
  `donor2`, `sample2`, `agreement`, `group`), as written by imprintomeR 1.6.0.

## v1.5.3 - 2026-11-16

First release. Versioned to match the imprintomeR release it runs (1.5.3).

### Pipeline

- `RUN_METHQC`: cohort-level array QC from raw IDATs with imprintomeR `run_meth_QC.R`
  (detection p-value, intensity, probe coverage, beta densities, ewastools checks,
  normalization); mixed-platform cohorts are split into one MethQcSet per platform
- `RUN_IMPRINTOMER`: imprinting analysis per platform and ICR probeset with
  `run_imprintomeR.R`; in-cohort (`--reference_group`) or external (`--reference_file`)
  control references, per-ICR scoring on by default
- nf-schema validation of parameters and the samplesheet
  (`sample,idat_grn,idat_red,sample_group`)
- nf-core institutional profiles, including `-profile stjude` (LSF + Singularity)
- `-profile test -stub` wiring test on placeholder IDATs, runnable from any folder

### Container

- `ghcr.io/hongjianjin/imprintomer:1.5.3`: Bioconductor 3.20, minfi, 450K/EPIC/EPICv2
  manifests and annotations, ewastools, imprintomeR v1.5.3; built by GitHub Actions
- Host `R_LIBS` / `R_LIBS_USER` are kept out of the container (image and pipeline `env`)

### Tested

- Stub test and a 10-sample GSE74738 (450K) run with `--reference_group control` on the
  St. Jude HPC (Nextflow 24.10.5, Singularity 4.1.1)
