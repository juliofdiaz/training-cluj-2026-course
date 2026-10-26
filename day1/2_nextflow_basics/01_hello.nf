#!/usr/bin/env nextflow
/*
 * 01_hello.nf — the smallest useful Nextflow pipeline
 *
 *   nextflow run 01_hello.nf
 *   nextflow run 01_hello.nf -resume
 *   nextflow run 01_hello.nf --greeting 'Salut' -resume
 */

params.greeting = 'Hello'

process SAY_HELLO {
    tag "${name}"

    input:
    val name

    output:
    path "${name}.txt"

    script:
    """
    echo "${params.greeting}, ${name}! I ran on \$(hostname) at \$(date +%T)" > ${name}.txt
    """
}

workflow {
    names = channel.of('Cluj', 'Napoca', 'Transilvania')
    SAY_HELLO(names)
    SAY_HELLO.out.view { f -> "${f.name}: ${f.text.trim()}" }
}
