#!/usr/bin/env nextflow
/*
 * bactflow — start of step 2: SHOVILL is written but not connected yet.
 * Your job: the three TODO lines below (D1 handbook section 3.2).
 *
 *   nextflow run main.nf -profile docker --input ~/course/data/reads/samplesheet_test.csv
 */

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

process SHOVILL {
    tag "${meta.id}"
    label 'process_high'
    container 'quay.io/biocontainers/shovill:1.4.2--hdfd78af_1'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.fasta"), emit: contigs
    tuple val(meta), path("${meta.id}.shovill.log"), emit: log
    tuple val("${task.process}"), val('shovill'), eval("shovill --version | sed 's/shovill //'"), topic: versions

    // --ram is only a ceiling for the assembler (these small genomes use about 2 GB),
    // but shovill refuses anything below 8, so small machines still pass 8
    script:
    """
    shovill \\
        --R1 ${reads[0]} --R2 ${reads[1]} \\
        --outdir shovill_out \\
        --gsize ${params.genome_size} \\
        --cpus ${task.cpus} \\
        --ram ${Math.max(8, task.memory.toGiga())} \\
        --tmpdir . \\
        ${params.shovill_args}

    # Prefix contig names with the sample ID so they stay unique downstream
    sed "s/^>/>${meta.id}_/" shovill_out/contigs.fa > ${meta.id}.fasta
    cp shovill_out/shovill.log ${meta.id}.shovill.log
    """

    stub:
    """
    printf '>${meta.id}_contig00001\\nACGT\\n' > ${meta.id}.fasta
    touch ${meta.id}.shovill.log
    """
}

workflow {
    main:
    ch_reads = channel.fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample]
            tuple(meta, [file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true)])
        }

    FASTP(ch_reads)
    // TODO 1: run SHOVILL on FASTP's trimmed reads (one line)

    publish:
    fastp      = FASTP.out.json.join(FASTP.out.html)
    // TODO 2: publish SHOVILL's contigs under the name 'assemblies' (one line)
}

output {
    fastp {
        path 'qc/fastp'
    }
    // TODO 3: put 'assemblies' in a folder called assemblies (three lines, like fastp above)
}
