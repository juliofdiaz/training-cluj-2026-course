#!/usr/bin/env nextflow
/*
 * 04_config.nf (optional) — same process, settings moved OUT of the code.
 * Instructions: README.md in this folder.
 */

params.input = "${projectDir}/../../data/reads/samplesheet_test.csv"

process FASTP {
    tag "${meta.id}"
    debug true          // show what the task prints

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.fastp.json")

    script:
    """
    fastp --in1 ${reads[0]} --in2 ${reads[1]} --json ${meta.id}.fastp.json --thread ${task.cpus}
    echo "${meta.id}: ran with ${task.cpus} CPUs and ${task.memory}"
    """
}

workflow {
    channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> tuple([id: row.sample], [file(row.fastq_1), file(row.fastq_2)]) }
        | FASTP
        | view
}
