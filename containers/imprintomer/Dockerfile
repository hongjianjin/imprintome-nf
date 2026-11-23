# Container for the imprintome-nf pipeline: R + Bioconductor + imprintomeR
#
# Build and push (from this folder):
#   docker build --build-arg IMPRINTOMER_REF=v1.6.0 -t ghcr.io/hongjianjin/imprintomer:1.6.0 .
#   docker push ghcr.io/hongjianjin/imprintomer:1.6.0
#
# Or convert to a Singularity image on the St. Jude HPC:
#   module load singularity/4.1.1
#   singularity build imprintomer_1.6.0.sif docker://ghcr.io/hongjianjin/imprintomer:1.6.0
# and run the pipeline with --imprintomer_container /path/to/imprintomer_1.6.0.sif

FROM bioconductor/bioconductor_docker:RELEASE_3_20

ARG IMPRINTOMER_REF=v1.6.0

LABEL org.opencontainers.image.title="imprintomer" \
      org.opencontainers.image.description="R environment with imprintomeR for the imprintome-nf Nextflow pipeline" \
      org.opencontainers.image.source="https://github.com/hongjianjin/imprintome-nf" \
      org.opencontainers.image.licenses="Apache-2.0"

# Use only the container's R libraries. Without this, an R_LIBS/R_LIBS_USER exported on the host
# (e.g. a personal R 4.1 library in $HOME) leaks in through Singularity and R loads packages
# compiled for another R version ("libRlapack.so: cannot open shared object file").
ENV R_LIBS=/usr/local/lib/R/site-library:/usr/local/lib/R/library     R_LIBS_USER=/dev/null     R_LIBS_SITE=/usr/local/lib/R/site-library

# procps provides `ps`, which Nextflow uses to collect task metrics
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*

# Bioconductor dependencies, array manifests/annotations for 450K, EPIC and EPICv2
RUN Rscript -e 'BiocManager::install(c( \
        "minfi", "ComplexHeatmap", "illuminaio", \
        "IlluminaHumanMethylation450kmanifest", "IlluminaHumanMethylation450kanno.ilmn12.hg19", \
        "IlluminaHumanMethylationEPICmanifest", "IlluminaHumanMethylationEPICanno.ilm10b4.hg19", \
        "IlluminaHumanMethylationEPICv2manifest", "IlluminaHumanMethylationEPICv2anno.20a1.hg38", \
        "GenomicRanges", "IRanges", "S4Vectors", "GenomeInfoDb" \
    ), ask = FALSE, update = FALSE)'

# CRAN dependencies used by the CLI scripts and optional plots (pheatmap, Rtsne and cowplot
# moved to Suggests in imprintomeR 1.6.0; installed so all plot types keep working)
RUN Rscript -e 'install.packages(c( \
        "remotes", "optparse", "ragg", "ggridges", "gridBase", "UpSetR", \
        "pheatmap", "Rtsne", "cowplot" \
    ), repos = "https://cloud.r-project.org")'

# imprintomeR at the requested git ref (since 1.6.0 it no longer needs ewastools)
RUN Rscript -e "remotes::install_github('hongjianjin/imprintomeR@${IMPRINTOMER_REF}', dependencies = c('Depends', 'Imports', 'LinkingTo'), upgrade = 'never')" \
    && Rscript -e 'library(imprintomeR); stopifnot(file.exists(system.file("scripts/run_meth_QC.R", package = "imprintomeR")), file.exists(system.file("scripts/run_imprintomeR.R", package = "imprintomeR")))'

CMD ["R"]
