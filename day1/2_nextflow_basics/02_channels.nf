#!/usr/bin/env nextflow
/*
 * 02_channels.nf — from a samplesheet to the channel shape every
 * nf-core pipeline uses:  [ meta, [ R1, R2 ] ]
 *
 *   cd ~/course/day1/2_nextflow_basics
 *   nextflow run 02_channels.nf --input ~/course/data/reads/samplesheet.csv
 *
 * Work through the TODOs one at a time. Re-run after each one.
 */

params.input = "${projectDir}/../../data/reads/samplesheet.csv"

workflow {
    // Step A: read the CSV. Each row becomes a map: [sample:..., fastq_1:..., fastq_2:...]
    rows = channel.fromPath(params.input).splitCsv(header: true)
    rows.view { row -> "row: ${row}" }

    // Step B: build [ meta, [R1, R2] ] tuples
    reads = rows.map { row ->
        def meta = [id: row.sample]
        tuple(meta, [file(row.fastq_1), file(row.fastq_2)])
    }
    reads.view { meta, files -> "${meta.id} -> ${files*.name}" }

    // TODO 1: edit the Step B map above: add a 'group' to meta.
    //         SA01-SA04 are 'ward_A', the rest 'ward_B'.
    //         Hint: def n = row.sample.replace('SA', '') as Integer
    //         Then, in the reads.view line, print ${meta} instead of ${meta.id}.

    // TODO 2: count the samples. Use .count() and .view()

    // TODO 3: gather ALL sample IDs into a single list. Use .map + .collect().
    //         How many items does the resulting channel emit?

    // TODO 4 (stretch): after TODO 1, group sample IDs by ward with
    //         .map { meta, files -> tuple(meta.group, meta.id) }.groupTuple()
}
