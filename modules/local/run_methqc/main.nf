process RUN_METHQC {
    tag "${meta.id}"
    label 'process_high_memory'

    container "${params.imprintomer_container}"

    input:
    val  meta
    path samples, stageAs: 'samples.tsv'
    path idats  , stageAs: 'idats/*'

    output:
    path "methqc"                                      , emit: results
    tuple val(meta), path("methqc/*/data/*_qcset.rds") , emit: qcset
    path "methqc/${meta.id}_metadata.tsv"              , emit: metadata
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p methqc

    # run_meth_QC.R requires absolute IDAT prefixes in the Basename column
    awk -v d="\$PWD/idats" 'BEGIN { FS = OFS = "\\t" } NR > 1 { \$2 = d "/" \$2 } { print }' \\
        samples.tsv > methqc/${meta.id}_metadata.tsv

    QC_SCRIPT=\$(Rscript -e 'cat(system.file("scripts/run_meth_QC.R", package = "imprintomeR"))' 2> /dev/null | tail -n 1)
    if [ ! -f "\$QC_SCRIPT" ]; then
        echo "ERROR: run_meth_QC.R not found; is imprintomeR installed in the container?" >&2
        exit 1
    fi

    Rscript "\$QC_SCRIPT" \\
        --metadata methqc/${meta.id}_metadata.tsv \\
        --outdir methqc \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e 'cat(paste(R.version\$major, R.version\$minor, sep = "."))' 2> /dev/null | tail -n 1)
        imprintomer: \$(Rscript -e 'cat(as.character(packageVersion("imprintomeR")))' 2> /dev/null | tail -n 1)
    END_VERSIONS
    """

    stub:
    def platform = params.platform ? params.platform.toLowerCase() : 'epic'
    """
    mkdir -p methqc/${platform}/data methqc/${platform}/plots
    cp samples.tsv methqc/${meta.id}_metadata.tsv
    touch methqc/${platform}/data/${platform}_qcset.rds
    touch methqc/run_meth_QC.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: stub
        imprintomer: stub
    END_VERSIONS
    """
}
