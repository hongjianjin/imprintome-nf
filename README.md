# imprintome-nf

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A524.10.0-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**imprintome-nf** is a Nextflow pipeline, laid out following nf-core conventions, that runs
quality control and genomic imprinting analysis on Illumina DNA methylation arrays
(450K, EPIC, EPICv2) with the [imprintomeR](https://github.com/hongjianjin/imprintomeR) R package.

1. Array QC of the whole cohort from raw IDATs: detection p-values, intensity, probe coverage,
   beta densities, control-probe metrics, SNP-based sample-swap and donor checks, normalization
   (`run_meth_QC.R`). Mixed-platform
   cohorts are split into one MethQcSet per platform.
2. Imprinting analysis for each platform and each requested ICR probeset: Imprinting Deviation
   Scores, per-ICR status, plots and summary workbooks (`run_imprintomeR.R`), optionally with
   bootstrap intervals and an origin permutation test.

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
nextflow run hongjianjin/imprintome-nf \
    -r v1.6.0 \
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

Nextflow 24.10 or newer (with Java 17+) is required. If the cluster's `nextflow` modules are
older, use a conda environment, which bundles its own Java:

```bash
conda create -n nextflow -c conda-forge -c bioconda nextflow=24.10.5
conda activate nextflow
```

`-r v1.6.0` pins this release; use `-r main -latest` for the development version.

Bootstrap intervals and the origin permutation test (imprintomeR >= 1.6.0) are off by default;
turn them on with, for example, `--n_boot 1000 --n_perm 1000 --seed 20261124` (see
[docs/usage.md](docs/usage.md#uncertainty-run_imprintomerr-imprintomer--160)).

Other profiles: `docker`, `singularity`, `apptainer`, `test`, `debug`.

See [docs/usage.md](docs/usage.md) for all options and [docs/output.md](docs/output.md) for the
output layout. `nextflow run . --help` lists every parameter.

## Container

Both processes run in one container holding R, imprintomeR and its Bioconductor dependencies,
set with `--imprintomer_container` (default `ghcr.io/hongjianjin/imprintomer:1.6.0`).
The image is built from [containers/imprintomer/Dockerfile](containers/imprintomer/Dockerfile) by the
[Build imprintomeR container](.github/workflows/build-container.yml) GitHub Actions workflow, on pushes
that change the Dockerfile or manually for another imprintomeR tag:

```bash
gh workflow run build-container.yml -R hongjianjin/imprintome-nf -f imprintomer_ref=v1.6.0
```

You can also point the parameter at a local `.sif` file.

## Testing

A wiring test on placeholder IDATs (downloaded from this repo, so it runs from any folder):

```bash
nextflow run hongjianjin/imprintome-nf -r main -profile test -stub --outdir results_test
```

`-profile test` uses no container; add `stjude` (`-profile stjude,test`) to also check the
Singularity image and LSF submission.

## Credits

imprintome-nf was written by Hongjian Jin (St. Jude Children's Research Hospital) on top of imprintomeR
by Hongjian Jin and Gang Wu.

## License

imprintome-nf is released under the [Apache License 2.0](LICENSE).

## Citations

If you use imprintome-nf, please cite imprintomeR (Zenodo DOI [10.5281/zenodo.23741652](https://doi.org/10.5281/zenodo.23741652))
and the tools it builds on: minfi, ewastools (whose control-probe and SNP checks imprintomeR
reimplements; Heiss and Just 2018) and [Nextflow](https://pubmed.ncbi.nlm.nih.gov/28398311/).
The pipeline structure follows the [nf-core](https://nf-co.re) framework
([Ewels et al. 2020](https://doi.org/10.1038/s41587-020-0439-x)).
