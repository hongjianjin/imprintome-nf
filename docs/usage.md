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

```bash
module load nextflow
nextflow run hongjianjin/imprintome-nf -profile stjude --input samplesheet.csv --outdir results
```

The `stjude` profile from nf-core/configs submits each process as an LSF job, picks the queue
from the requested resources, and runs tasks in Singularity. Launch Nextflow itself from an
interactive or long-running job, not on a login node, e.g.

```bash
bsub -q standard -n 1 -M 8000 -J methqc -oo methqc.log \
    "nextflow run hongjianjin/imprintome-nf -profile stjude --input samplesheet.csv --outdir results -resume"
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
| `--skip_ewastools` | `false`                                                 | `--skip-ewastools` |

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
--imprintomer_container /research/.../containers/imprintomer_1.5.3.sif
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
singularity exec --cleanenv docker://ghcr.io/hongjianjin/imprintomer:1.5.3 Rscript -e 'library(imprintomeR)'
```
