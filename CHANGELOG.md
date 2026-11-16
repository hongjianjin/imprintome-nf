# imprintome-nf: Changelog

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
