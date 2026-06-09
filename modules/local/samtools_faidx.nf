process SAMTOOLS_FAIDX {
    tag "reference"
    label 'process_single'

    publishDir "${params.outdir}/reference", mode: 'copy'

    input:
    path fasta

    output:
    tuple path("reference.fa"), path("reference.fa.fai"), emit: fai
    path "samtools_faidx.versions.yml", emit: versions

    script:
    """
    ln -s ${fasta} reference.fa
    samtools faidx reference.fa

    cat <<-END_VERSIONS > samtools_faidx.versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -n 1 | sed 's/samtools //')
    END_VERSIONS
    """
}
