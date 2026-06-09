process BWA_MEM {
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(reads), path(fasta), path(index_files)

    output:
    tuple val(meta), path("*.sam"), emit: sam
    path "*.bwa_mem.versions.yml", emit: versions

    script:
    def prefix = meta.id
    def read_args = reads.collect { it.toString() }.join(' ')
    """
    bwa mem \\
        -t ${task.cpus} \\
        -R '@RG\\tID:${prefix}\\tSM:${prefix}\\tPL:ILLUMINA' \\
        ${fasta} \\
        ${read_args} \\
        > ${prefix}.sam

    cat <<-END_VERSIONS > ${prefix}.bwa_mem.versions.yml
    "${task.process}":
        bwa: \$(bwa 2>&1 | sed -n 's/^Version: //p')
    END_VERSIONS
    """
}
