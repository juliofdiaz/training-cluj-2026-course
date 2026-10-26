process FASTP {
    tag "${meta.id}"
    label 'process_low'
    container 'quay.io/biocontainers/fastp:1.4.0--h43da1c4_0'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_trimmed_R{1,2}.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.id}.fastp.json"),               emit: json
    tuple val(meta), path("${meta.id}.fastp.html"),               emit: html
    tuple val("${task.process}"), val('fastp'), eval("fastp --version 2>&1 | sed 's/fastp //'"), topic: versions

    script:
    """
    fastp \\
        --in1 ${reads[0]} --in2 ${reads[1]} \\
        --out1 ${meta.id}_trimmed_R1.fastq.gz --out2 ${meta.id}_trimmed_R2.fastq.gz \\
        --json ${meta.id}.fastp.json --html ${meta.id}.fastp.html \\
        --report_title "${meta.id}" \\
        --thread ${task.cpus} \\
        ${params.fastp_args}
    """

    stub:
    """
    touch ${meta.id}_trimmed_R1.fastq.gz ${meta.id}_trimmed_R2.fastq.gz ${meta.id}.fastp.json ${meta.id}.fastp.html
    """
}
