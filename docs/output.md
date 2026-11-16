# imprintome-nf: Output

```
<outdir>/
├── methqc/                              # run_meth_QC.R output for the cohort
│   ├── <cohort>_metadata.tsv            # metadata generated from the samplesheet
│   ├── run_meth_QC.log
│   └── <platform>/                      # one folder per platform (450k, epic, epicv2)
│       ├── data/<platform>_qcset.rds    # MethQcSet with betas, QC metrics and metadata
│       ├── *_qc_table_*.xlsx            # colour-coded per-sample QC table (Final.QC)
│       ├── *_summary.txt                # QC summary report
│       └── plots/                       # intensity, detection p-value, coverage, beta density PDFs/PNGs
├── imprintomer/                         # run_imprintomeR.R output
│   └── <cohort>_<platform>_<probeset>/
│       ├── *_imprintomeSet.rds          # ImprintomeSet object
│       ├── *_AnalysisResults.xlsx       # sample-level IDS/IDI and per-ICR summaries
│       ├── *_results_*.tsv              # per-ICR tables (with --icr)
│       ├── metadata.tsv
│       ├── run_imprintomeR.log
│       └── plots
└── pipeline_info/
    ├── imprintome_software_versions.yml
    ├── execution_report_*.html
    ├── execution_timeline_*.html
    ├── execution_trace_*.txt
    └── pipeline_dag_*.html
```

The `methqc/<platform>/data/<platform>_qcset.rds` file can be passed straight to
`run_imprintomeR.R -r` or loaded in R for custom analyses. The `imprintomer/` folders are the
input of the `imprintomer-report` slide-deck skill.
