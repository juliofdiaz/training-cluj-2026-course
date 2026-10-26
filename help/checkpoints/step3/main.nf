#!/usr/bin/env nextflow
/*
 * bactflow — checkpoint 3: modules + QUAST, MLST, ABRICATE
 *
 *   nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet.csv -resume
 */

include { FASTP    } from './modules/fastp'
include { SHOVILL  } from './modules/shovill'
include { QUAST    } from './modules/quast'
include { MLST     } from './modules/mlst'
include { ABRICATE } from './modules/abricate'

workflow {
    main:
    ch_reads = channel.fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample]
            tuple(meta, [file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true)])
        }

    FASTP(ch_reads)
    SHOVILL(FASTP.out.reads)
    MLST(SHOVILL.out.contigs)
    ABRICATE(SHOVILL.out.contigs, params.amr_db)

    // One QUAST run over ALL assemblies: collect() turns N emissions into 1 list
    QUAST(SHOVILL.out.contigs.map { _meta, fasta -> fasta }.collect())

    // collectFile concatenates the per-sample MLST lines into one table
    ch_mlst = MLST.out.tsv
        .map { _meta, tsv -> tsv }
        .collectFile(name: 'mlst_summary.tsv', sort: { f -> f.name })

    publish:
    fastp      = FASTP.out.json.join(FASTP.out.html)
    assemblies = SHOVILL.out.contigs
    quast      = QUAST.out.dir
    mlst       = ch_mlst
    amr        = ABRICATE.out.tsv
}

output {
    fastp {
        path 'qc/fastp'
    }
    assemblies {
        path 'assemblies'
    }
    quast {
        path 'qc'
    }
    mlst {
        path 'typing'
    }
    amr {
        path 'amr/per_sample'
    }
}
