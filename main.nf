#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { FASTQC as FASTQC_RAW } from './modules/local/fastqc'
include { FASTQC as FASTQC_TRIMMED } from './modules/local/fastqc'
include { FASTP } from './modules/local/fastp'
include { BWA_INDEX } from './modules/local/bwa_index'
include { BWA_MEM } from './modules/local/bwa_mem'
include { SAMTOOLS_FAIDX } from './modules/local/samtools_faidx'
include { SAMTOOLS_SORT } from './modules/local/samtools_sort'
include { SAMTOOLS_FLAGSTAT } from './modules/local/samtools_flagstat'
include { BCFTOOLS_CALL } from './modules/local/bcftools_call'
include { FREEBAYES_CALL } from './modules/local/freebayes_call'
include { VARIANT_COMPARE } from './modules/local/variant_compare'
include { VARIANT_MULTIQC } from './modules/local/variant_multiqc'
include { MULTIQC } from './modules/local/multiqc'

workflow {
    main:
    print_header()

    Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row -> samplesheet_row_to_tuple(row) }
        .set { ch_reads }

    FASTQC_RAW(ch_reads.map { meta, reads -> tuple(meta, reads, 'raw') })
    FASTP(ch_reads)
    FASTQC_TRIMMED(FASTP.out.reads.map { meta, reads -> tuple(meta, reads, 'trimmed') })
    BWA_INDEX(file(params.fasta, checkIfExists: true))
    SAMTOOLS_FAIDX(file(params.fasta, checkIfExists: true))
    BWA_MEM(FASTP.out.reads.combine(BWA_INDEX.out.index))
    SAMTOOLS_SORT(BWA_MEM.out.sam)
    SAMTOOLS_FLAGSTAT(SAMTOOLS_SORT.out.bam)
    BCFTOOLS_CALL(SAMTOOLS_SORT.out.bam.combine(SAMTOOLS_FAIDX.out.fai))
    FREEBAYES_CALL(SAMTOOLS_SORT.out.bam.combine(SAMTOOLS_FAIDX.out.fai))
    VARIANT_COMPARE(BCFTOOLS_CALL.out.table.join(FREEBAYES_CALL.out.table))
    VARIANT_MULTIQC(FREEBAYES_CALL.out.summary.collect(), VARIANT_COMPARE.out.summary.collect())

    ch_multiqc_files = Channel.empty()
        .mix(FASTQC_RAW.out.reports)
        .mix(FASTQC_RAW.out.versions)
        .mix(FASTP.out.reports)
        .mix(FASTP.out.versions)
        .mix(FASTQC_TRIMMED.out.reports)
        .mix(FASTQC_TRIMMED.out.versions)
        .mix(BWA_INDEX.out.versions)
        .mix(BWA_MEM.out.versions)
        .mix(SAMTOOLS_FAIDX.out.versions)
        .mix(SAMTOOLS_SORT.out.versions)
        .mix(SAMTOOLS_FLAGSTAT.out.stats)
        .mix(SAMTOOLS_FLAGSTAT.out.versions)
        .mix(BCFTOOLS_CALL.out.stats)
        .mix(BCFTOOLS_CALL.out.versions)
        .mix(FREEBAYES_CALL.out.summary)
        .mix(FREEBAYES_CALL.out.versions)
        .mix(VARIANT_COMPARE.out.summary)
        .mix(VARIANT_COMPARE.out.report)
        .mix(VARIANT_COMPARE.out.versions)
        .mix(VARIANT_MULTIQC.out.freebayes_qc)
        .mix(VARIANT_MULTIQC.out.comparison)
        .mix(VARIANT_MULTIQC.out.versions)
        .collect()

    MULTIQC(ch_multiqc_files, file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true))

    publish:
    fastqc_raw_reports = FASTQC_RAW.out.reports
    fastqc_raw_versions = FASTQC_RAW.out.versions
    fastp_reports = FASTP.out.reports
    trimmed_reads = FASTP.out.reads
    fastqc_trimmed_reports = FASTQC_TRIMMED.out.reports
    fastqc_trimmed_versions = FASTQC_TRIMMED.out.versions
    bwa_index = BWA_INDEX.out.index
    bwa_index_versions = BWA_INDEX.out.versions
    samtools_faidx = SAMTOOLS_FAIDX.out.fai
    samtools_faidx_versions = SAMTOOLS_FAIDX.out.versions
    bwa_mem_sam = BWA_MEM.out.sam
    samtools_sort_bam = SAMTOOLS_SORT.out.bam
    samtools_sort_versions = SAMTOOLS_SORT.out.versions
    samtools_flagstat = SAMTOOLS_FLAGSTAT.out.stats
    samtools_flagstat_versions = SAMTOOLS_FLAGSTAT.out.versions
    bcftools_vcf = BCFTOOLS_CALL.out.vcf
    bcftools_stats = BCFTOOLS_CALL.out.stats
    bcftools_tables = BCFTOOLS_CALL.out.table
    bcftools_reports = BCFTOOLS_CALL.out.report
    freebayes_vcf = FREEBAYES_CALL.out.vcf
    freebayes_tables = FREEBAYES_CALL.out.table
    freebayes_summaries = FREEBAYES_CALL.out.summary
    freebayes_reports = FREEBAYES_CALL.out.report
    variant_comparison_tables = VARIANT_COMPARE.out.table
    variant_comparison_summaries = VARIANT_COMPARE.out.summary
    variant_comparison_reports = VARIANT_COMPARE.out.report
    variant_comparison_versions = VARIANT_COMPARE.out.versions
    multiqc_report = MULTIQC.out.report
    multiqc_data = MULTIQC.out.data
    multiqc_versions = MULTIQC.out.versions
}

output {
    fastqc_raw_reports {
        path 'fastqc/raw'
    }

    fastqc_raw_versions {
        path 'fastqc/raw'
    }

    fastp_reports {
        path 'fastp'
    }

    trimmed_reads {
        path 'trimmed'
    }

    fastqc_trimmed_reports {
        path 'fastqc/trimmed'
    }

    fastqc_trimmed_versions {
        path 'fastqc/trimmed'
    }

    bwa_index {
        path 'reference'
    }

    bwa_index_versions {
        path 'reference'
    }

    samtools_faidx {
        path 'reference'
    }

    samtools_faidx_versions {
        path 'reference'
    }

    bwa_mem_sam {
        path 'alignment/sam'
    }

    samtools_sort_bam {
        path 'alignment/bam'
    }

    samtools_sort_versions {
        path 'alignment/bam'
    }

    samtools_flagstat {
        path 'alignment/qc'
    }

    samtools_flagstat_versions {
        path 'alignment/qc'
    }

    bcftools_vcf {
        path 'variants/vcf/bcftools'
    }

    bcftools_stats {
        path 'variants/qc'
    }

    bcftools_tables {
        path 'variants/tables/bcftools'
    }

    bcftools_reports {
        path 'variants/reports/bcftools'
    }

    freebayes_vcf {
        path 'variants/vcf/freebayes'
    }

    freebayes_tables {
        path 'variants/tables/freebayes'
    }

    freebayes_summaries {
        path 'variants/qc/freebayes'
    }

    freebayes_reports {
        path 'variants/reports/freebayes'
    }

    variant_comparison_tables {
        path 'variants/comparison'
    }

    variant_comparison_summaries {
        path 'variants/comparison'
    }

    variant_comparison_reports {
        path 'variants/comparison'
    }

    variant_comparison_versions {
        path 'variants/comparison'
    }

    multiqc_report {
        path 'multiqc'
    }

    multiqc_data {
        path 'multiqc'
    }

    multiqc_versions {
        path 'multiqc'
    }
}

def print_header() {
    log.info """
    =====================================================
      nf-training/dna-fastq-preprocess ${workflow.manifest.version}
    =====================================================
      input  : ${params.input}
      fasta  : ${params.fasta}
      outdir : ${params.outdir}
    =====================================================
    """.stripIndent()
}

def samplesheet_row_to_tuple(row) {
    def required = ['sample', 'fastq_1']
    required.each { field ->
        if (!row[field]) {
            throw new IllegalArgumentException("Samplesheet row is missing required column '${field}': ${row}")
        }
    }

    def sample = row.sample.toString().trim()
    def fastq1 = file(row.fastq_1.toString().trim(), checkIfExists: true)
    def fastq2 = row.fastq_2 ? file(row.fastq_2.toString().trim(), checkIfExists: true) : null

    if (!sample) {
        throw new IllegalArgumentException("Sample name cannot be empty: ${row}")
    }

    def meta = [
        id: sample,
        single_end: fastq2 == null
    ]
    def reads = fastq2 == null ? [fastq1] : [fastq1, fastq2]

    tuple(meta, reads)
}
