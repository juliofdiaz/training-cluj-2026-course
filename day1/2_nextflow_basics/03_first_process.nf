#!/usr/bin/env nextflow
/*
 * 03_first_process.nf — a real tool, in a real container, on real data
 *
 *   cd ~/course/day1/2_nextflow_basics
 *   nextflow run 03_first_process.nf -with-docker --input ~/course/data/reads/samplesheet_test.csv
 *
 * TODO 1: complete the output block so Nextflow captures the JSON report.
 *         Then change the last line to FASTP.out.json.view() to print the reports.
 * TODO 2: change --thread 2 to use the number of CPUs Nextflow gives the task.
 * TODO 3: run it on all 8 samples (--input ~/course/data/reads/samplesheet.csv). What changes in the console output?
 * TODO 4: run it again with -resume. What changes?
 */

params.input = "${projectDir}/../../data/reads/samplesheet_test.csv"

process FASTP {
    tag "${meta.id}"
    container 'quay.io/biocontainers/fastp:1.4.0--h43da1c4_0'
    cpus 2

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}_trimmed_R{1,2}.fastq.gz"), emit: reads
    // TODO 1: add a second output, emitted as 'json', for ${meta.id}.fastp.json

    script:
    """
    fastp \\
        --in1 ${reads[0]} --in2 ${reads[1]} \\
        --out1 ${meta.id}_trimmed_R1.fastq.gz --out2 ${meta.id}_trimmed_R2.fastq.gz \\
        --json ${meta.id}.fastp.json --html ${meta.id}.fastp.html \\
        --thread 2
    """
}

workflow {
    reads = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> tuple([id: row.sample], [file(row.fastq_1), file(row.fastq_2)]) }

    FASTP(reads)
    FASTP.out.reads.view()
}
