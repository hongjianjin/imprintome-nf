# imprintome-nf: Usage

## Samplesheet

`--input` takes a CSV (or TSV) with a header row:

| Column         | Required | Description                                                                 |
| -------------- | -------- | --------------------------------------------------------------------------- |
| `sample`       | yes      | Unique sample name (letters, digits, `.`, `_`, `-`). Becomes `Sample_Name`. |
| `idat_grn`     | yes      | Path to the `*_Grn.idat` or `*_Grn.idat.gz` file.                           |
| `idat_red`     | yes      | Path to the matching `*_Red.idat` or `*_Red.idat.gz` file.                  |
| `sample_group` | no       | Group label (e.g. `control`, `case`). Becomes `Sample_Group`.               |

The Grn and Red files of a sample must share the same prefix (e.g. `207000000001_R01C01`),
and prefixes must be unique across the cohort, because all IDATs are staged into one folder.

The pipeline converts the samplesheet into the metadata TSV that `run_meth_QC.R` expects
(`Sample_Name`, absolute `Basename`, `Sample_Group`); a copy is kept in `<outdir>/methqc/`.

## Running on the St. Jude HPC

The HPC `nextflow/*` modules (up to 23.10) and default Java (1.8) are too old; the pipeline needs
Nextflow >= 24.10 with Java 17+. Create a conda environment once:

```bash
module load conda3/202402
conda create -y -n nextflow -c conda-forge -c bioconda nextflow=24.10.5
```

Then, in each session:

```bash
module load conda3/202402
conda activate nextflow
nextflow run hongjianjin/imprintome-nf -r v1.6.0 -profile stjude --input samplesheet.csv --outdir results
```

The `stjude` profile from nf-core/configs submits each process as an LSF job, picks the queue
from the requested resources, and runs tasks in Singularity. Launch Nextflow itself from a
long-running job, not on a login node, e.g.

```bash
bsub -q standard -n 1 -M 8000 -W 72:00 -J imprintome -oo imprintome.log \
    "source \$(conda info --base)/etc/profile.d/conda.sh; conda activate nextflow; \
     nextflow run hongjianjin/imprintome-nf -r v1.6.0 -profile stjude --input samplesheet.csv --outdir results -resume"
```

Singularity images are cached under `NXF_SINGULARITY_CACHEDIR`; set it to a shared folder so the
imprintomeR image is pulled once.

## Main parameters

### Array QC (`run_meth_QC.R`)

| Parameter          | Default                                                 | Script option      |
| ------------------ | ------------------------------------------------------- | ------------------ |
| `--platform`       | auto-detect                                             | `--platform`       |
| `--pcutoff`        | `0.05`                                                  | `--pcutoff`        |
| `--icutoff`        | `11`                                                    | `--icutoff`        |
| `--normalization`  | `noob`                                                  | `--normalization`  |
| `--qc_plot_types`  | `intensity,detection_pval,probe_coverage,beta_density`  | `--plot-types`     |
| `--skip_qc_plots`  | `false`                                                 | `--no-qc-plots`    |
| `--skip_qc_report` | `false`                                                 | `--no-qc-report`   |

### Imprinting analysis (`run_imprintomeR.R`)

Runs once per platform found by QC and per probeset in `--probesets`.

| Parameter              | Default    | Script option       |
| ---------------------- | ---------- | ------------------- |
| `--skip_imprintomer`   | `false`    | (skip the step)     |
| `--probesets`          | `selected` | `--probeset`        |
| `--genome_build`       | `hg38`     | `--genome`          |
| `--ids_cutoff`         | `0.2`      | `--ids-cutoff`      |
| `--reference_group`    | none       | `--reference-group` |
| `--reference_file`     | none       | `--reference-file`  |
| `--dmr_type`           | panel      | `--dmr-type`        |
| `--balance`            | `probe`    | `--balance`         |
| `--icr`                | `true`     | `--icr`             |
| `--infinium_type`      | `all`      | `--infinium-type`   |
| `--imprint_plot_types` | `default`  | `--plot-types`      |
| `--skip_imprint_plots` | `false`    | `--skip-plots`      |

Control-probe metrics, SNP genotype calls, the sample-swap/contamination check and predicted
donors always run (built into imprintomeR since 1.6.0). `--skip_ewastools` is deprecated and
ignored; the pipeline prints a warning if it is set.

### Uncertainty (`run_imprintomeR.R`, imprintomeR >= 1.6.0)

Off by default. Bootstrap intervals add `Status_interval` (IDS interval above, below or across
the cutoff) and `Mechanism_support`; the permutation test adds `origin_perm_p`.

| Parameter              | Default | Script option          | Notes |
| ---------------------- | ------- | ---------------------- | ----- |
| `--n_boot`             | `0`     | `--n-boot`             | 1000-2000 for reporting |
| `--resample`           | `icr`   | `--resample`           | `icr` or `probe`; used with `--n_boot` |
| `--conf_level`         | `0.95`  | `--conf-level`         | used with `--n_boot` |
| `--resample_reference` | `false` | `--resample-reference` | also resample the controls; needs `--reference_group` |
| `--n_perm`             | `0`     | `--n-perm`             | origin permutation test; needs `--reference_group` or `--reference_file` |
| `--permute`            | `icr`   | `--permute`            | `icr` or `probe` |
| `--seed`               | random  | `--seed`               | written to `run_imprintomeR.log`; set it to reproduce a run |

Example with intervals and the origin test against in-cohort controls:

```bash
nextflow run hongjianjin/imprintome-nf -r v1.6.0 -profile stjude --input samplesheet.csv --outdir results \
    --reference_group control --n_boot 1000 --n_perm 1000 --seed 20261123 -resume
```

Script options without a pipeline parameter (for example `--radar-all TRUE`) can be appended in a
custom config passed with `-c`:

```groovy
process {
    withName: 'RUN_IMPRINTOMER' {
        ext.args = { "--genome ${params.genome_build} --icr --radar-all TRUE --verbose" }
    }
}
```

## Resources

`RUN_METHQC` requests 2 CPUs, 80 GB and 24 h (label `process_high_memory`), doubling on a retry
after an out-of-memory or time-limit kill. `RUN_IMPRINTOMER` requests 2 CPUs, 32 GB and 8 h.
Override them in a custom config:

```groovy
process {
    withName: 'RUN_METHQC' { memory = 160.GB }
}
```

## Container

`--imprintomer_container` accepts a registry image or a local Singularity image:

```bash
--imprintomer_container /research/.../containers/imprintomer_1.6.0.sif
```

See `containers/imprintomer/Dockerfile` for how to build it.

## Re-running

Add `-resume` to reuse finished tasks. Changing only imprinting parameters re-runs only
`RUN_IMPRINTOMER`.

## Troubleshooting

**`unable to load shared object '/home/<user>/R/.../*.so'` or `libRlapack.so: cannot open shared object file`**

R inside the container picked up a personal R library exported on the host (`R_LIBS`), which
Singularity passes into containers. The pipeline overrides `R_LIBS` for its tasks, and images
built after 2026-11-16 set it too. When running the image by hand, add `--cleanenv`:

```bash
singularity exec --cleanenv docker://ghcr.io/hongjianjin/imprintomer:1.6.0 Rscript -e 'library(imprintomeR)'
```
