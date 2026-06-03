process SAMTOOLS_SORT {
    tag "${meta.id}"
    label 'process_low'

    publishDir "${params.outdir}/alignment/bam", mode: 'copy'

    input:
    tuple val(meta), path(sam)

    output:
    tuple val(meta), path("*.sorted.bam"), path("*.sorted.bam.bai"), emit: bam
    path "*.samtools_sort.versions.yml", emit: versions

    script:
    def prefix = meta.id
    """
    samtools sort \\
        -@ ${task.cpus} \\
        -o ${prefix}.sorted.bam \\
        ${sam}

    samtools index ${prefix}.sorted.bam

    cat <<-END_VERSIONS > ${prefix}.samtools_sort.versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n 1 | sed 's/samtools //')
    END_VERSIONS
    """
}
