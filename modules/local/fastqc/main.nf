process FASTQC {
    tag "${meta.id}:${stage}"
    label 'process_low'

    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(meta), path(reads), val(stage)

    output:
    path "*_fastqc.{html,zip}", emit: reports
    path "*.fastqc.${stage}.versions.yml", emit: versions

    script:
    def read_args = reads.collect { it.toString() }.join(' ')
    """
    fastqc \\
        --threads ${task.cpus} \\
        --outdir . \\
        ${read_args}

    cat <<-END_VERSIONS > ${meta.id}.fastqc.${stage}.versions.yml
    "${task.process}":
        fastqc: \$(fastqc --version | sed 's/FastQC v//')
    END_VERSIONS
    """
}
