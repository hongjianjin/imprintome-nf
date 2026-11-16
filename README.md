# imprintome-nf

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A524.10.0-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**imprintome-nf** is a Nextflow pipeline, laid out following nf-core conventions, that runs
quality control and genomic imprinting analysis on Illumina DNA methylation arrays
(450K, EPIC, EPICv2) with the [imprintomeR](https://github.com/hongjianjin/imprintomeR) R package.

1. Array QC of the whole cohort from raw IDATs: detection p-values, intensity, probe coverage,
   beta densities, ewastools control metrics, normalization (`run_meth_QC.R`). Mixed-platform
   cohorts are split into one MethQcSet per platform.
2. Imprinting analysis for each platform and each requested ICR probeset: Imprinting Deviation
   Scores, per-ICR status, plots and summary workbooks (`run_imprintomeR.R`).

## Usage

Prepare a samplesheet with one row per array:

```csv
sample,idat_grn,idat_red,sample_group
SAMPLE_1,/path/to/idats/207000000001_R01C01_Grn.idat,/path/to/idats/207000000001_R01C01_Red.idat,control
SAMPLE_2,/path/to/idats/207000000001_R02C01_Grn.idat.gz,/path/to/idats/207000000001_R02C01_Red.idat.gz,case
```

`sample_group` is optional; it becomes the `Sample_Group` metadata column and can be used as the
in-cohort reference with `--reference_group`.

Run on the St. Jude HPC with the [nf-core `stjude` institutional profile](https://nf-co.re/configs/stjude/)
(LSF executor + Singularity):

```bash
module load nextflow
nextflow run hongjianjin/imprintome-nf \
    -profile stjude \
    --input samplesheet.csv \
    --outdir results \
    --cohort GSE74738 \
    --platform 450K \
    --probesets selected \
    --reference_group control
```

`-profile stjude` is pulled from [nf-core/configs](https://github.com/nf-core/configs) at runtime.
On nodes without internet access, clone nf-core/configs and pass `--custom_config_base /path/to/configs`.

Other profiles: `docker`, `singularity`, `apptainer`, `test`, `debug`.

See [docs/usage.md](docs/usage.md) for all options and [docs/output.md](docs/output.md) for the
output layout. `nextflow run . --help` lists every parameter.

## Container

Both processes run in one container holding R, imprintomeR and its Bioconductor dependencies,
set with `--imprintomer_container` (default `ghcr.io/hongjianjin/imprintomer:1.5.3`).
The image is built from [containers/imprintomer/Dockerfile](containers/imprintomer/Dockerfile) by the
[Build imprintomeR container](.github/workflows/build-container.yml) GitHub Actions workflow, on pushes
that change the Dockerfile or manually for another imprintomeR tag:

```bash
gh workflow run build-container.yml -R hongjianjin/imprintome-nf -f imprintomer_ref=v1.5.3
```

You can also point the parameter at a local `.sif` file.

## Testing

A wiring test on placeholder IDATs, run from the pipeline folder:

```bash
nextflow run . -profile test -stub --outdir results_test
```

## Credits

imprintome-nf was written by Hongjian Jin (St. Jude Children's Research Hospital) on top of imprintomeR
by Hongjian Jin and Gang Wu.

## License

imprintome-nf is released under the [Apache License 2.0](LICENSE).

## Citations

If you use imprintome-nf, please cite imprintomeR (Zenodo DOI [10.5281/zenodo.23741652](https://doi.org/10.5281/zenodo.23741652))
and the tools it builds on: minfi, ewastools and [Nextflow](https://pubmed.ncbi.nlm.nih.gov/28398311/).
The pipeline structure follows the [nf-core](https://nf-co.re) framework
([Ewels et al. 2020](https://doi.org/10.1038/s41587-020-0439-x)).
