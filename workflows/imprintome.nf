/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { RUN_METHQC      } from '../modules/local/run_methqc/main'
include { RUN_IMPRINTOMER } from '../modules/local/run_imprintomer/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow IMPRINTOME {

    take:
    ch_samplesheet // channel: [ val(meta), path(idat_grn), path(idat_red) ]

    main:
    ch_versions = Channel.empty()

    //
    // Cohort-level metadata in the layout run_meth_QC.R expects. Basename holds the
    // IDAT prefix relative to the staged idats/ folder; RUN_METHQC makes it absolute.
    //
    ch_metadata = ch_samplesheet
        .map { meta, grn, red ->
            "${meta.id}\t${meta.basename}\t${meta.sample_group ?: ''}"
        }
        .collectFile(
            name    : "${params.cohort}_samples.tsv",
            seed    : "Sample_Name\tBasename\tSample_Group",
            newLine : true,
            sort    : true
        )

    //
    // All IDATs are staged into one folder, so IDAT prefixes must be unique
    //
    ch_idats = ch_samplesheet
        .map { meta, grn, red -> [ meta.basename, meta.id, grn, red ] }
        .toList()
        .map { rows ->
            def dups = rows.groupBy { it[0] }.findAll { k, v -> v.size() > 1 }
            if (dups) {
                error("IDAT prefixes must be unique across samples; repeated: " +
                    dups.collect { k, v -> "${k} (${v.collect { it[1] }.join(', ')})" }.join('; '))
            }
            rows.collectMany { [ it[2], it[3] ] }
        }

    //
    // MODULE: Array QC on the whole cohort (run_meth_QC.R). Mixed platforms are
    // split by the script, giving one MethQcSet RDS per platform.
    //
    RUN_METHQC (
        [ id: params.cohort ],
        ch_metadata,
        ch_idats
    )
    ch_versions = ch_versions.mix(RUN_METHQC.out.versions)

    ch_qcset = RUN_METHQC.out.qcset
        .transpose()
        .map { meta, rds ->
            def platform = rds.name.replaceFirst(/_qcset\.rds$/, '')
            [ meta + [ id: "${meta.id}_${platform}", platform: platform ], rds ]
        }

    //
    // MODULE: Imprinting analysis per platform x probeset (run_imprintomeR.R)
    //
    if (!params.skip_imprintomer) {
        def probesets = params.probesets.tokenize(',')*.trim().findAll { it }
        ch_reference  = params.reference_file ? file(params.reference_file, checkIfExists: true) : []

        RUN_IMPRINTOMER (
            ch_qcset,
            probesets,
            ch_reference
        )
        ch_versions = ch_versions.mix(RUN_IMPRINTOMER.out.versions.first())
    }

    //
    // Collate software versions
    //
    ch_versions
        .unique()
        .collectFile(
            storeDir : "${params.outdir}/pipeline_info",
            name     : 'imprintome_software_versions.yml',
            sort     : true,
            newLine  : true
        )

    emit:
    qcset    = ch_qcset    // channel: [ val(meta), path(rds) ]
    versions = ch_versions // channel: [ path(versions.yml) ]
}
