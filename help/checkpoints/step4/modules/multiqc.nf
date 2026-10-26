process MULTIQC {
    label 'process_single'
    container 'quay.io/biocontainers/multiqc:1.35--pyhdfd78af_2'

    input:
    path qc_files
    path config

    output:
    path 'multiqc_report.html', emit: report
    path 'multiqc*_data',       emit: data
    tuple val("${task.process}"), val('multiqc'), eval("multiqc --version | sed 's/.*version //'"), topic: versions

    script:
    """
    multiqc --config ${config} --filename multiqc_report.html --force .
    """

    stub:
    """
    mkdir multiqc_data && touch multiqc_report.html
    """
}
