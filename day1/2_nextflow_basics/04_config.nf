#!/usr/bin/env nextflow
/*
 * 04_config.nf (stretch) — same process, settings moved OUT of the code.
 * Run with the config file next to it:
 *
 *   nextflow run 04_config.nf -c 04.config -profile docker
 *   nextflow run 04_config.nf -c 04.config -profile docker,big
 *
 * Question: the process below has no 'container' and no 'cpus'. Where do they come from?
 */

params.input = "${projectDir}/../../data/reads/samplesheet_test.csv"

process FASTP {
    tag "${meta.id}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.fastp.json")

    script:
    """
    fastp --in1 ${reads[0]} --in2 ${reads[1]} --json ${meta.id}.fastp.json --thread ${task.cpus}
    echo "Ran with ${task.cpus} CPUs and ${task.memory}" >&2
    """
}

workflow {
    channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> tuple([id: row.sample], [file(row.fastq_1), file(row.fastq_2)]) }
        | FASTP
        | view
}
