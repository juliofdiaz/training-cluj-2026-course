#!/usr/bin/env nextflow
/*
 * 02_channels.nf — from a samplesheet to the channel shape every
 * nf-core pipeline uses:  [ meta, [ R1, R2 ] ]
 *
 * Instructions: Day 1 handbook section 2.2. Change only the lines marked TODO.
 */

params.input = "${projectDir}/../../data/reads/samplesheet.csv"

workflow {
    // Step A: read the CSV. Each row becomes a map: [sample:..., fastq_1:..., fastq_2:...]
    rows = channel.fromPath(params.input).splitCsv(header: true)
    rows.view { row -> "row: ${row}" }

    // Step B: build [ meta, [R1, R2] ] tuples
    reads = rows.map { row ->
        // TODO 1: replace the next line (handbook section 2.2)
        def meta = [id: row.sample]
        tuple(meta, [file(row.fastq_1), file(row.fastq_2)])
    }
    // TODO 1: then print ${meta} instead of ${meta.id} here
    reads.view { meta, files -> "${meta.id} -> ${files*.name}" }

    // TODO 2, 3 and 4 (optional, handbook section 2.2): below this line

}
