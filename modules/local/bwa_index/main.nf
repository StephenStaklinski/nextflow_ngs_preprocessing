process BWA_INDEX {
    tag "reference"
    label 'process_single'

    publishDir "${params.outdir}/reference", mode: 'copy'

    input:
    path fasta

    output:
    tuple path("reference.fa"), path("reference.fa.*"), emit: index
    path "versions.yml", emit: versions

    script:
    """
    ln -s ${fasta} reference.fa
    bwa index reference.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa: \$(bwa 2>&1 | sed -n 's/^Version: //p')
    END_VERSIONS
    """
}
