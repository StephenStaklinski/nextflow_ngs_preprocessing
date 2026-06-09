process VARIANT_MULTIQC {
    tag "variant_multiqc"
    label 'process_single'

    input:
    path freebayes_summaries
    path comparison_summaries

    output:
    path "freebayes_variant_qc_mqc.yaml", emit: freebayes_qc
    path "variant_caller_comparison_mqc.yaml", emit: comparison
    path "variant_multiqc.versions.yml", emit: versions

    script:
    """
    cat > freebayes_variant_qc_mqc.yaml <<-YAML
    id: freebayes_variant_qc
    section_name: "FreeBayes variant QC"
    description: "Haploid FreeBayes variant QC summary from sorted BWA-MEM alignments. This mirrors the count-level bcftools QC metrics for demonstration; FreeBayes does not have a native MultiQC module in this pipeline."
    plot_type: "table"
    pconfig:
        id: "freebayes_variant_qc_table"
        title: "FreeBayes variant QC"
    data:
    YAML

    awk -F '\\t' 'FNR == 1 { next }
        {
            printf "        %s:\\n", \$1
            printf "            Total variants: %s\\n", \$2
            printf "            SNVs: %s\\n", \$3
            printf "            Indels/complex: %s\\n", \$4
            printf "            Transitions: %s\\n", \$5
            printf "            Transversions: %s\\n", \$6
            printf "            Ts/Tv: %s\\n", \$7
        }' ${freebayes_summaries} >> freebayes_variant_qc_mqc.yaml

    cat > variant_caller_comparison_mqc.yaml <<-YAML
    id: variant_caller_comparison
    section_name: "Variant caller comparison"
    description: "Per-sample comparison of haploid bcftools and FreeBayes calls."
    plot_type: "table"
    pconfig:
        id: "variant_caller_comparison_table"
        title: "Variant caller comparison"
    data:
    YAML

    awk -F '\\t' 'FNR == 1 { next }
        {
            printf "        %s:\\n", \$1
            printf "            bcftools total: %s\\n", \$2
            printf "            FreeBayes total: %s\\n", \$3
            printf "            Shared: %s\\n", \$4
            printf "            bcftools only: %s\\n", \$5
            printf "            FreeBayes only: %s\\n", \$6
        }' ${comparison_summaries} >> variant_caller_comparison_mqc.yaml

    cat <<-END_VERSIONS > variant_multiqc.versions.yml
    "${task.process}":
        awk: \$(awk -W version 2>&1 | head -n 1)
    END_VERSIONS
    """
}
