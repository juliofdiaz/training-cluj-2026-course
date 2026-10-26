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

    script:
    """
    shovill \\
        --R1 ${reads[0]} --R2 ${reads[1]} \\
        --outdir shovill_out \\
        --gsize ${params.genome_size} \\
        --cpus ${task.cpus} \\
        --ram ${task.memory.toGiga()} \\
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
