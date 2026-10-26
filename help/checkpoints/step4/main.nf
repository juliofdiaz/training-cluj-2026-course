#!/usr/bin/env nextflow
/*
 * bactflow — a small, teachable bacterial WGS pipeline
 *
 *   reads ─► FASTP ─► SHOVILL ─┬─► QUAST (all samples) ──┐
 *                │             ├─► MLST ──► mlst.tsv     ├─► MULTIQC
 *                │             └─► ABRICATE ─► AMR_SUMMARY
 *                └──────────── fastp JSON ──────────────┘
 *   trimmed reads ─► MASH_SCREEN ─► species/   (nf-core module: which genomes are in the reads?)
 *
 * Day 2 checkpoint: the same pipeline plus the nf-core MASH_SCREEN module (species check),
 *   installed with:  nextflow module install nf-core/mash/screen
 *
 * Course: Reproducible Genomics using Containers, Workflow Managers and
 *         Cloud Computing. Written for Nextflow >= 26.04 (strict syntax).
 */

include { FASTP            } from './modules/fastp'
include { SHOVILL          } from './modules/shovill'
include { QUAST            } from './modules/quast'
include { MLST             } from './modules/mlst'
include { ABRICATE         } from './modules/abricate'
include { ABRICATE_SUMMARY } from './modules/abricate'
include { MULTIQC          } from './modules/multiqc'
include { MASH_SCREEN      } from './modules/nf-core/mash/screen'

workflow {
    main:
    // 1. Samplesheet (CSV: sample,fastq_1,fastq_2) -> [ meta, [R1, R2] ]
    ch_reads = channel.fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample]
            tuple(meta, [file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true)])
        }

    // 2. Per-sample steps
    FASTP(ch_reads)
    SHOVILL(FASTP.out.reads)
    MASH_SCREEN(FASTP.out.reads, channel.value([[id: 'refseq'], file(params.mash_db, checkIfExists: true)]))
    MLST(SHOVILL.out.contigs)
    ABRICATE(SHOVILL.out.contigs, params.amr_db)

    // 3. Cohort-level steps: gather per-sample results into single files
    QUAST(SHOVILL.out.contigs.map { _meta, fasta -> fasta }.collect())

    ch_mlst = MLST.out.tsv
        .map { _meta, tsv -> tsv }
        .collectFile(name: 'mlst_summary.tsv', sort: { f -> f.name })

    ABRICATE_SUMMARY(ABRICATE.out.tsv.map { _meta, tsv -> tsv }.collect())

    ch_multiqc_files = FASTP.out.json.map { _meta, json -> json }
        .mix(QUAST.out.tsv)
        .collect()
    MULTIQC(ch_multiqc_files, file("${projectDir}/assets/multiqc_config.yml"))

    // 4. Provenance: every process reports its tool version to the 'versions' topic
    ch_versions = channel.topic('versions')
        .unique()
        .map { process, tool, version -> "${process}\t${tool}\t${version}" }
        .collectFile(name: 'software_versions.tsv', sort: true, newLine: true,
                     seed: "process\ttool\tversion")

    publish:
    trimmed     = FASTP.out.reads
    fastp       = FASTP.out.json.join(FASTP.out.html)
    assemblies  = SHOVILL.out.contigs.map { meta, fasta -> [id: meta.id, assembly: fasta] }
    quast       = QUAST.out.dir
    mlst        = ch_mlst
    amr         = ABRICATE.out.tsv
    amr_summary = ABRICATE_SUMMARY.out.tsv
    multiqc     = MULTIQC.out.report
    species     = MASH_SCREEN.out.screen
    versions    = ch_versions
}

output {
    trimmed {
        path 'trimmed'
        enabled params.save_trimmed
    }
    fastp {
        path 'qc/fastp'
    }
    assemblies {
        path 'assemblies'
        index {
            path 'assemblies/assemblies.csv'
            header true
        }
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
    amr_summary {
        path 'amr'
    }
    multiqc {
        path 'multiqc'
    }
    species {
        path 'species'
    }
    versions {
        path 'pipeline_info'
    }
}
