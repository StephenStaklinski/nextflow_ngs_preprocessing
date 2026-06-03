process VARIANT_COMPARE {
    tag "${meta.id}"
    label 'process_single'

    publishDir "${params.outdir}/variants/comparison", mode: 'copy'

    input:
    tuple val(meta), path(bcftools_table), path(freebayes_table)

    output:
    tuple val(meta), path("*.variant_method_comparison.tsv"), emit: table
    path "*.variant_method_comparison.summary.tsv", emit: summary
    path "*.variant_method_comparison.html", emit: report
    path "*.variant_compare.versions.yml", emit: versions

    script:
    def prefix = meta.id
    """
    awk -F '\\t' 'BEGIN { OFS = "\\t"; print "sample", "chrom", "pos", "ref", "alt", "bcftools_depth", "freebayes_depth", "called_by" }
        FNR == NR {
            if (FNR == 1) {
                next
            }
            key = \$1 SUBSEP \$2 SUBSEP \$3 SUBSEP \$4
            b[key] = \$0
            bd[key] = \$7
            keys[key] = key
            next
        }
        FNR == 1 {
            next
        }
        {
            key = \$1 SUBSEP \$2 SUBSEP \$3 SUBSEP \$4
            f[key] = \$0
            fd[key] = \$7
            keys[key] = key
        }
        END {
            for (key in keys) {
                split(key, fields, SUBSEP)
                if ((key in b) && (key in f)) {
                    called = "shared"
                } else if (key in b) {
                    called = "bcftools_only"
                } else {
                    called = "freebayes_only"
                }
                print "${prefix}", fields[1], fields[2], fields[3], fields[4], (key in bd ? bd[key] : "."), (key in fd ? fd[key] : "."), called
            }
        }' ${bcftools_table} ${freebayes_table} > ${prefix}.variant_method_comparison.unsorted.tsv

    {
        head -n 1 ${prefix}.variant_method_comparison.unsorted.tsv
        tail -n +2 ${prefix}.variant_method_comparison.unsorted.tsv | sort -t \$'\\t' -k2,2 -k3,3n -k4,4 -k5,5
    } > ${prefix}.variant_method_comparison.tsv

    awk -F '\\t' 'BEGIN { OFS = "\\t"; print "sample", "bcftools_total", "freebayes_total", "shared", "bcftools_only", "freebayes_only" }
        NR == 1 { next }
        {
            if (\$8 == "shared") {
                shared++
                bcftools_total++
                freebayes_total++
            } else if (\$8 == "bcftools_only") {
                bcftools_only++
                bcftools_total++
            } else if (\$8 == "freebayes_only") {
                freebayes_only++
                freebayes_total++
            }
        }
        END {
            print "${prefix}", bcftools_total + 0, freebayes_total + 0, shared + 0, bcftools_only + 0, freebayes_only + 0
        }' ${prefix}.variant_method_comparison.tsv > ${prefix}.variant_method_comparison.summary.tsv

    read sample bcftools_total freebayes_total shared bcftools_only freebayes_only <<-COUNTS
    \$(awk -F '\\t' 'NR == 2 { print \$1, \$2, \$3, \$4, \$5, \$6 }' ${prefix}.variant_method_comparison.summary.tsv)
    COUNTS

    cat > ${prefix}.variant_method_comparison.html <<-HTML
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>${prefix} variant caller comparison</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 32px; color: #17202a; }
        h1 { font-size: 24px; margin-bottom: 4px; }
        .meta { color: #566573; margin-bottom: 24px; }
        .summary { display: flex; gap: 12px; margin-bottom: 28px; flex-wrap: wrap; }
        .metric { border: 1px solid #d5d8dc; border-radius: 6px; padding: 12px 16px; min-width: 130px; }
        .metric strong { display: block; font-size: 24px; }
        table { border-collapse: collapse; width: 100%; font-size: 14px; }
        th, td { border-bottom: 1px solid #e5e8e8; padding: 8px; text-align: left; }
        th { background: #f4f6f7; }
        .shared { color: #1e8449; font-weight: 600; }
        .bcftools_only { color: #2874a6; font-weight: 600; }
        .freebayes_only { color: #b03a2e; font-weight: 600; }
      </style>
    </head>
    <body>
      <h1>${prefix} variant caller comparison</h1>
      <div class="meta">Side-by-side comparison of haploid bcftools and FreeBayes calls after BWA-MEM alignment.</div>
      <div class="summary">
        <div class="metric"><span>bcftools total</span><strong>\${bcftools_total}</strong></div>
        <div class="metric"><span>FreeBayes total</span><strong>\${freebayes_total}</strong></div>
        <div class="metric"><span>Shared</span><strong>\${shared}</strong></div>
        <div class="metric"><span>bcftools only</span><strong>\${bcftools_only}</strong></div>
        <div class="metric"><span>FreeBayes only</span><strong>\${freebayes_only}</strong></div>
      </div>
      <table>
        <thead>
          <tr><th>Chrom</th><th>Position</th><th>Ref</th><th>Alt</th><th>bcftools depth</th><th>FreeBayes depth</th><th>Called by</th></tr>
        </thead>
        <tbody>
    HTML

    awk -F '\\t' 'NR > 1 {
        printf "          <tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td class=\\"%s\\">%s</td></tr>\\n", \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$8
    }' ${prefix}.variant_method_comparison.tsv >> ${prefix}.variant_method_comparison.html

    if [ "\$((shared + bcftools_only + freebayes_only))" -eq 0 ]; then
        echo '          <tr><td colspan="7">No variants were called by either method.</td></tr>' >> ${prefix}.variant_method_comparison.html
    fi

    cat >> ${prefix}.variant_method_comparison.html <<-HTML
        </tbody>
      </table>
    </body>
    </html>
    HTML

    cat <<-END_VERSIONS > ${prefix}.variant_compare.versions.yml
    "${task.process}":
        awk: \$(awk -W version 2>&1 | head -n 1)
    END_VERSIONS
    """
}
