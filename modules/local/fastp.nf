process FASTP {
    tag "${meta.id}"
    label 'process_low'

    publishDir "${params.outdir}/fastp", mode: 'copy', pattern: "*.json"
    publishDir "${params.outdir}/fastp", mode: 'copy', pattern: "*.html"
    publishDir "${params.outdir}/trimmed", mode: 'copy', pattern: "*.trim.fastq.gz"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.trim.fastq.gz"), emit: reads
    path "*.fastp.{html,json}", emit: reports
    path "*.fastp.versions.yml", emit: versions

    script:
    def prefix = meta.id
    def is_paired = reads.size() == 2
    def fastp_cmd = is_paired
        ? "fastp --thread ${task.cpus} --in1 ${reads[0]} --in2 ${reads[1]} --out1 ${prefix}_R1.trim.fastq.gz --out2 ${prefix}_R2.trim.fastq.gz --html ${prefix}.fastp.html --json ${prefix}.fastp.json --detect_adapter_for_pe"
        : "fastp --thread ${task.cpus} --in1 ${reads[0]} --out1 ${prefix}.trim.fastq.gz --html ${prefix}.fastp.html --json ${prefix}.fastp.json"
    """
    ${fastp_cmd}

    cat <<-END_VERSIONS > ${prefix}.fastp.versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed 's/fastp //')
    END_VERSIONS
    """
}
