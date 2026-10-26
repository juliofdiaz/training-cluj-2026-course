#!/usr/bin/env nextflow
// Solution for 02_channels.nf

params.input = "${projectDir}/../../../data/reads/samplesheet.csv"

workflow {
    reads = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def n = row.sample.replace('SA', '') as Integer
            def meta = [id: row.sample, group: n <= 4 ? 'ward_A' : 'ward_B']
            tuple(meta, [file(row.fastq_1), file(row.fastq_2)])
        }

    reads.view { meta, files -> "${meta} -> ${files*.name}" }

    // TODO 2
    reads.count().view { n -> "Number of samples: ${n}" }

    // TODO 3: one emission, containing a list
    reads.map { meta, _files -> meta.id }.collect().view { ids -> "All IDs: ${ids}" }

    // TODO 4
    reads.map { meta, _files -> tuple(meta.group, meta.id) }
        .groupTuple()
        .view { group, ids -> "${group}: ${ids}" }
}
