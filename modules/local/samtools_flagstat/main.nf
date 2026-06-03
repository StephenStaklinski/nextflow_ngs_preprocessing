process SAMTOOLS_FLAGSTAT {
    tag "${meta.id}"
    label 'process_single'

    publishDir "${params.outdir}/alignment/qc", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    path "*.flagstat", emit: stats
    path "*.samtools_flagstat.versions.yml", emit: versions

    script:
    def prefix = meta.id
    """
    samtools flagstat \\
        ${bam} \\
        > ${prefix}.flagstat

    cat <<-END_VERSIONS > ${prefix}.samtools_flagstat.versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n 1 | sed 's/samtools //')
    END_VERSIONS
    """
}
