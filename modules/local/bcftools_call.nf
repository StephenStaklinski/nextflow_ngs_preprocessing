process BCFTOOLS_CALL {
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(bam), path(bai), path(fasta), path(fai)

    output:
    tuple val(meta), path("*.vcf.gz"), path("*.vcf.gz.tbi"), emit: vcf
    path "*.bcftools.stats.txt", emit: stats
    tuple val(meta), path("*.bcftools.variants.tsv"), emit: table
    path "*.bcftools.variants.html", emit: report
    path "*.bcftools_call.versions.yml", emit: versions

    script:
    def prefix = meta.id
    """
    bcftools mpileup \\
        --threads ${task.cpus} \\
        --fasta-ref ${fasta} \\
        --annotate FORMAT/DP,FORMAT/AD \\
        --output-type u \\
        ${bam} \\
        | bcftools call \\
            --threads ${task.cpus} \\
            --multiallelic-caller \\
            --variants-only \\
            --ploidy 1 \\
            --output-type z \\
            --output ${prefix}.bcftools.vcf.gz

    bcftools index --threads ${task.cpus} --tbi ${prefix}.bcftools.vcf.gz
    bcftools stats ${prefix}.bcftools.vcf.gz > ${prefix}.bcftools.stats.txt

    {
        printf 'chrom\\tpos\\tref\\talt\\tqual\\tfilter\\tdepth\\n'
        bcftools query -f '%CHROM\\t%POS\\t%REF\\t%ALT\\t%QUAL\\t%FILTER\\t%INFO/DP\\n' ${prefix}.bcftools.vcf.gz
    } > ${prefix}.bcftools.variants.tsv

    total_variants=\$(awk 'NR > 1 { count++ } END { print count + 0 }' ${prefix}.bcftools.variants.tsv)
    snvs=\$(awk 'NR > 1 && length(\$3) == 1 && length(\$4) == 1 { count++ } END { print count + 0 }' ${prefix}.bcftools.variants.tsv)
    indels=\$(awk 'NR > 1 && (length(\$3) != 1 || length(\$4) != 1) { count++ } END { print count + 0 }' ${prefix}.bcftools.variants.tsv)

    cat > ${prefix}.bcftools.variants.html <<-HTML
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>${prefix} variant summary</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 32px; color: #17202a; }
        h1 { font-size: 24px; margin-bottom: 4px; }
        .meta { color: #566573; margin-bottom: 24px; }
        .summary { display: flex; gap: 12px; margin-bottom: 28px; flex-wrap: wrap; }
        .metric { border: 1px solid #d5d8dc; border-radius: 6px; padding: 12px 16px; min-width: 120px; }
        .metric strong { display: block; font-size: 24px; }
        table { border-collapse: collapse; width: 100%; font-size: 14px; }
        th, td { border-bottom: 1px solid #e5e8e8; padding: 8px; text-align: left; }
        th { background: #f4f6f7; }
        .barbox { width: 160px; background: #eef2f3; height: 10px; border-radius: 999px; overflow: hidden; }
        .bar { background: #2874a6; height: 10px; }
      </style>
    </head>
    <body>
      <h1>${prefix} variant summary</h1>
      <div class="meta">Called with bcftools from sorted BWA-MEM alignments.</div>
      <div class="summary">
        <div class="metric"><span>Total variants</span><strong>\${total_variants}</strong></div>
        <div class="metric"><span>SNVs</span><strong>\${snvs}</strong></div>
        <div class="metric"><span>Indels/complex</span><strong>\${indels}</strong></div>
      </div>
      <table>
        <thead>
          <tr><th>Chrom</th><th>Position</th><th>Ref</th><th>Alt</th><th>QUAL</th><th>Depth</th><th>Depth bar</th></tr>
        </thead>
        <tbody>
    HTML

    awk -F '\\t' 'NR > 1 {
        depth = (\$7 == "." || \$7 == "" ? 0 : \$7)
        width = depth
        if (width > 160) width = 160
        printf "          <tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%.2f</td><td>%s</td><td><div class=\\"barbox\\"><div class=\\"bar\\" style=\\"width:%dpx\\"></div></div></td></tr>\\n", \$1, \$2, \$3, \$4, \$5, depth, width
    }' ${prefix}.bcftools.variants.tsv >> ${prefix}.bcftools.variants.html

    if [ "\${total_variants}" -eq 0 ]; then
        echo '          <tr><td colspan="7">No variants passed the caller settings.</td></tr>' >> ${prefix}.bcftools.variants.html
    fi

    cat >> ${prefix}.bcftools.variants.html <<-HTML
        </tbody>
      </table>
    </body>
    </html>
    HTML

    cat <<-END_VERSIONS > ${prefix}.bcftools_call.versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -n 1 | sed 's/bcftools //')
    END_VERSIONS
    """
}
