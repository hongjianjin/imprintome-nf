# Container for the imprintome-nf pipeline: R + Bioconductor + imprintomeR
#
# Build and push (from this folder):
#   docker build --build-arg IMPRINTOMER_REF=v1.5.3 -t ghcr.io/hongjianjin/imprintomer:1.5.3 .
#   docker push ghcr.io/hongjianjin/imprintomer:1.5.3
#
# Or convert to a Singularity image on the St. Jude HPC:
#   module load singularity/4.1.1
#   singularity build imprintomer_1.5.3.sif docker://ghcr.io/hongjianjin/imprintomer:1.5.3
# and run the pipeline with --imprintomer_container /path/to/imprintomer_1.5.3.sif

FROM bioconductor/bioconductor_docker:RELEASE_3_20

ARG IMPRINTOMER_REF=v1.5.3

LABEL org.opencontainers.image.title="imprintomer" \
      org.opencontainers.image.description="R environment with imprintomeR for the imprintome-nf Nextflow pipeline" \
      org.opencontainers.image.source="https://github.com/hongjianjin/imprintomeR" \
      org.opencontainers.image.licenses="Apache-2.0"

# procps provides `ps`, which Nextflow uses to collect task metrics
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*

# Bioconductor dependencies, array manifests/annotations for 450K, EPIC and EPICv2
RUN Rscript -e 'BiocManager::install(c( \
        "minfi", "ComplexHeatmap", \
        "IlluminaHumanMethylation450kmanifest", "IlluminaHumanMethylation450kanno.ilmn12.hg19", \
        "IlluminaHumanMethylationEPICmanifest", "IlluminaHumanMethylationEPICanno.ilm10b4.hg19", \
        "IlluminaHumanMethylationEPICv2manifest", "IlluminaHumanMethylationEPICv2anno.20a1.hg38", \
        "GenomicRanges", "IRanges", "S4Vectors", "GenomeInfoDb" \
    ), ask = FALSE, update = FALSE)'

# CRAN dependencies used by the CLI scripts and optional plots
RUN Rscript -e 'install.packages(c( \
        "remotes", "optparse", "ragg", "ggridges", "gridBase", "UpSetR" \
    ), repos = "https://cloud.r-project.org")'

# ewastools (GitHub) and imprintomeR at the requested git ref
RUN Rscript -e 'remotes::install_github("hhhh5/ewastools", upgrade = "never")' \
    && Rscript -e "remotes::install_github('hongjianjin/imprintomeR@${IMPRINTOMER_REF}', dependencies = c('Depends', 'Imports', 'LinkingTo'), upgrade = 'never')" \
    && Rscript -e 'library(imprintomeR); stopifnot(file.exists(system.file("scripts/run_meth_QC.R", package = "imprintomeR")), file.exists(system.file("scripts/run_imprintomeR.R", package = "imprintomeR")))'

CMD ["R"]
