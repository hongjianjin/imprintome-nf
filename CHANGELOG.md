# imprintome-nf: Changelog

## v0.1.0dev - [unreleased]

Initial pipeline structure following nf-core conventions:

- `RUN_METHQC`: cohort-level array QC with imprintomeR `run_meth_QC.R`
- `RUN_IMPRINTOMER`: imprinting analysis per platform and probeset with `run_imprintomeR.R`
- nf-schema samplesheet and parameter validation
- Support for nf-core institutional profiles, including `-profile stjude`
- Dockerfile for the imprintomeR container
