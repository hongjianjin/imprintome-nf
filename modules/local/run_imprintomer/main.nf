process RUN_IMPRINTOMER {
    tag "${meta.id}:${probeset}"
    label 'process_medium'

    container "${params.imprintomer_container}"

    input:
    tuple val(meta), path(qcset)
    each  probeset
    path  reference, stageAs: 'reference/*'

    output:
    tuple val(meta), val(probeset), path("${prefix}"), emit: results
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args ?: ''
    prefix      = task.ext.prefix ?: "${meta.id}_${probeset}"
    def ref_arg = reference ? "--reference-file ${reference}" : ''
    """
    IR_SCRIPT=\$(Rscript -e 'cat(system.file("scripts/run_imprintomeR.R", package = "imprintomeR"))' 2> /dev/null | tail -n 1)
    if [ ! -f "\$IR_SCRIPT" ]; then
        echo "ERROR: run_imprintomeR.R not found; is imprintomeR installed in the container?" >&2
        exit 1
    fi

    Rscript "\$IR_SCRIPT" \\
        --rds ${qcset} \\
        --outdir ${prefix} \\
        --prefix ${prefix} \\
        --probeset ${probeset} \\
        ${ref_arg} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$(Rscript -e 'cat(paste(R.version\$major, R.version\$minor, sep = "."))' 2> /dev/null | tail -n 1)
        imprintomer: \$(Rscript -e 'cat(as.character(packageVersion("imprintomeR")))' 2> /dev/null | tail -n 1)
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}_${probeset}"
    """
    mkdir -p ${prefix}
    touch ${prefix}/${prefix}_imprintomeSet.rds
    touch ${prefix}/${prefix}_AnalysisResults.xlsx
    touch ${prefix}/run_imprintomeR.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: stub
        imprintomer: stub
    END_VERSIONS
    """
}
