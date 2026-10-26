#!/usr/bin/env nextflow
// Solution for 03_first_process.nf

params.input = "${projectDir}/../../../data/reads/samplesheet_test.csv"

process FASTP {
    tag "${meta.id}"
    container 'quay.io/biocontainers/fastp:1.4.0--h43da1c4_0'
    cpus 2

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_trimmed_R{1,2}.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.id}.fastp.json"),               emit: json

    script:
    """
    fastp \\
        --in1 ${reads[0]} --in2 ${reads[1]} \\
        --out1 ${meta.id}_trimmed_R1.fastq.gz --out2 ${meta.id}_trimmed_R2.fastq.gz \\
        --json ${meta.id}.fastp.json --html ${meta.id}.fastp.html \\
        --thread ${task.cpus}
    """
}

workflow {
    reads = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> tuple([id: row.sample], [file(row.fastq_1), file(row.fastq_2)]) }

    FASTP(reads)
    FASTP.out.json.view { meta, json -> "${meta.id}: ${json}" }
}
