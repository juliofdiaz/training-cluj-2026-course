process QUAST {
    label 'process_medium'
    container 'quay.io/biocontainers/quast:5.3.0--py313pl5321h5ca1c30_2'

    input:
    path assemblies          // all assemblies at once: one QUAST report for the cohort

    output:
    path 'quast',            emit: dir
    path 'quast/report.tsv', emit: tsv
    tuple val("${task.process}"), val('quast'), eval("quast.py --version 2>&1 | grep -o 'v[0-9.]*' | head -1"), topic: versions

    script:
    """
    quast.py \\
        --output-dir quast \\
        --threads ${task.cpus} \\
        --min-contig 500 \\
        ${assemblies}
    """

    stub:
    """
    mkdir quast && touch quast/report.tsv
    """
}
