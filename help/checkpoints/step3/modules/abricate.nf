process ABRICATE {
    tag "${meta.id}"
    label 'process_single'
    container 'quay.io/biocontainers/abricate:1.4.0--h05cac1d_0'

    input:
    tuple val(meta), path(fasta)
    val db

    output:
    tuple val(meta), path("${meta.id}.${db}.tsv"), emit: tsv
    tuple val("${task.process}"), val('abricate'), eval("abricate --version | sed 's/abricate //'"), topic: versions
    tuple val("${task.process}"), val("abricate_db_${db}"), eval("abricate --list | grep -w '^${db}' | tr -s ' \\t' ' ' | cut -d' ' -f4"), topic: versions

    script:
    """
    abricate \\
        --db ${db} \\
        --minid ${params.amr_minid} \\
        --mincov ${params.amr_mincov} \\
        --threads ${task.cpus} \\
        ${fasta} > ${meta.id}.${db}.tsv
    """

    stub:
    """
    touch ${meta.id}.${db}.tsv
    """
}

process ABRICATE_SUMMARY {
    label 'process_single'
    container 'quay.io/biocontainers/abricate:1.4.0--h05cac1d_0'

    input:
    path tsvs

    output:
    path 'amr_summary.tsv', emit: tsv

    script:
    """
    abricate --summary ${tsvs} > amr_summary.tsv
    """

    stub:
    """
    touch amr_summary.tsv
    """
}
