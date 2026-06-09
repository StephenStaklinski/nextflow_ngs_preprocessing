process FREEBAYES_CALL {
    tag "${meta.id}"
    label 'process_low'

    input:
    tuple val(meta), path(bam), path(bai), path(fasta), path(fai)

    output:
    tuple val(meta), path("*.freebayes.vcf"), emit: vcf
    tuple val(meta), path("*.freebayes.variants.tsv"), emit: table
    path "*.freebayes.summary.tsv", emit: summary
    path "*.freebayes.variants.html", emit: report
    path "*.freebayes_call.versions.yml", emit: versions

    script:
    def prefix = meta.id
    """
    freebayes \\
        --fasta-reference ${fasta} \\
        --ploidy 1 \\
        --min-alternate-count 2 \\
        --min-alternate-fraction 0.20 \\
        ${bam} \\
        > ${prefix}.freebayes.vcf

    {
        printf 'chrom\\tpos\\tref\\talt\\tqual\\tfilter\\tdepth\\n'
        awk -F '\\t' 'BEGIN { OFS = "\\t" }
            /^#/ { next }
            {
                depth = "."
                n = split(\$8, info, ";")
                for (i = 1; i <= n; i++) {
                    if (info[i] ~ /^DP=/) {
                        sub(/^DP=/, "", info[i])
                        depth = info[i]
                    }
                }
                print \$1, \$2, \$4, \$5, \$6, \$7, depth
            }' ${prefix}.freebayes.vcf
    } > ${prefix}.freebayes.variants.tsv

    total_variants=\$(awk 'NR > 1 { count++ } END { print count + 0 }' ${prefix}.freebayes.variants.tsv)
    snvs=\$(awk 'NR > 1 && length(\$3) == 1 && length(\$4) == 1 { count++ } END { print count + 0 }' ${prefix}.freebayes.variants.tsv)
    indels=\$(awk 'NR > 1 && (length(\$3) != 1 || length(\$4) != 1) { count++ } END { print count + 0 }' ${prefix}.freebayes.variants.tsv)
    transitions=\$(awk 'NR > 1 && ((\$3 == "A" && \$4 == "G") || (\$3 == "G" && \$4 == "A") || (\$3 == "C" && \$4 == "T") || (\$3 == "T" && \$4 == "C")) { count++ } END { print count + 0 }' ${prefix}.freebayes.variants.tsv)
    transversions=\$(awk 'NR > 1 && length(\$3) == 1 && length(\$4) == 1 && !((\$3 == "A" && \$4 == "G") || (\$3 == "G" && \$4 == "A") || (\$3 == "C" && \$4 == "T") || (\$3 == "T" && \$4 == "C")) { count++ } END { print count + 0 }' ${prefix}.freebayes.variants.tsv)
    tstv=\$(awk -v ts="\${transitions}" -v tv="\${transversions}" 'BEGIN { if (tv == 0) print "NA"; else printf "%.2f", ts / tv }')

    {
        printf 'sample\\ttotal_variants\\tsnvs\\tindels_complex\\ttransitions\\ttransversions\\ttstv\\n'
        printf '${prefix}\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' "\${total_variants}" "\${snvs}" "\${indels}" "\${transitions}" "\${transversions}" "\${tstv}"
    } > ${prefix}.freebayes.summary.tsv

    cat > ${prefix}.freebayes.variants.html <<-HTML
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>${prefix} FreeBayes variant summary</title>
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
      </style>
    </head>
    <body>
      <h1>${prefix} FreeBayes variant summary</h1>
      <div class="meta">Called with FreeBayes from sorted BWA-MEM alignments.</div>
      <div class="summary">
        <div class="metric"><span>Total variants</span><strong>\${total_variants}</strong></div>
        <div class="metric"><span>SNVs</span><strong>\${snvs}</strong></div>
        <div class="metric"><span>Indels/complex</span><strong>\${indels}</strong></div>
      </div>
      <table>
        <thead>
          <tr><th>Chrom</th><th>Position</th><th>Ref</th><th>Alt</th><th>QUAL</th><th>Depth</th></tr>
        </thead>
        <tbody>
    HTML

    awk -F '\\t' 'NR > 1 {
        printf "          <tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%.2f</td><td>%s</td></tr>\\n", \$1, \$2, \$3, \$4, \$5, \$7
    }' ${prefix}.freebayes.variants.tsv >> ${prefix}.freebayes.variants.html

    if [ "\${total_variants}" -eq 0 ]; then
        echo '          <tr><td colspan="6">No variants passed the caller settings.</td></tr>' >> ${prefix}.freebayes.variants.html
    fi

    cat >> ${prefix}.freebayes.variants.html <<-HTML
        </tbody>
      </table>
    </body>
    </html>
    HTML

    cat <<-END_VERSIONS > ${prefix}.freebayes_call.versions.yml
    "${task.process}":
        freebayes: \$(freebayes --version | sed 's/version:  //; s/version: //')
    END_VERSIONS
    """
}
