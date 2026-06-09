process MULTIQC {
    tag "multiqc"
    label 'process_single'

    input:
    path multiqc_files
    path multiqc_config

    output:
    path "multiqc_report.html", emit: report
    path "multiqc*_data", emit: data
    path "versions.yml", emit: versions

    script:
    """
    multiqc \\
        --title "${params.multiqc_title}" \\
        --config "${multiqc_config}" \\
        --outdir . \\
        --filename multiqc_report.html \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed 's/multiqc, version //')
    END_VERSIONS
    """
}
