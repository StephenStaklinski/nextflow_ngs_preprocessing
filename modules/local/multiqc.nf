process MULTIQC {
    tag "multiqc"
    label 'process_single'

    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path multiqc_files

    output:
    path "multiqc_report.html", emit: report
    path "multiqc*_data", emit: data
    path "versions.yml", emit: versions

    script:
    """
    multiqc \\
        --title "${params.multiqc_title}" \\
        --config "${projectDir}/assets/multiqc_config.yml" \\
        --outdir . \\
        --filename multiqc_report.html \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/multiqc, version //')
    END_VERSIONS
    """
}
