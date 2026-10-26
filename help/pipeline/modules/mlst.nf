process MLST {
    tag "${meta.id}"
    label 'process_single'
    container 'quay.io/biocontainers/mlst:2.35.0--hdfd78af_1'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta.id}.mlst.tsv"), emit: tsv
    tuple val("${task.process}"), val('mlst'), eval("mlst --version | sed 's/mlst //'"), topic: versions

    script:
    // --label replaces the file name in column 1 with the sample ID
    """
    mlst --label ${meta.id} --threads ${task.cpus} ${fasta} > ${meta.id}.mlst.tsv
    """

    stub:
    """
    printf '${meta.id}\\tsaureus\\t22\\n' > ${meta.id}.mlst.tsv
    """
}
