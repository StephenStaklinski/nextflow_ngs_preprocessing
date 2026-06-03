#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { FASTQC as FASTQC_RAW } from './modules/local/fastqc/main'
include { FASTQC as FASTQC_TRIMMED } from './modules/local/fastqc/main'
include { FASTP } from './modules/local/fastp/main'
include { BWA_INDEX } from './modules/local/bwa_index/main'
include { BWA_MEM } from './modules/local/bwa_mem/main'
include { SAMTOOLS_FAIDX } from './modules/local/samtools_faidx/main'
include { SAMTOOLS_SORT } from './modules/local/samtools_sort/main'
include { SAMTOOLS_FLAGSTAT } from './modules/local/samtools_flagstat/main'
include { BCFTOOLS_CALL } from './modules/local/bcftools_call/main'
include { FREEBAYES_CALL } from './modules/local/freebayes_call/main'
include { VARIANT_COMPARE } from './modules/local/variant_compare/main'
include { VARIANT_MULTIQC } from './modules/local/variant_multiqc/main'
include { MULTIQC } from './modules/local/multiqc/main'

workflow {
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

    MULTIQC(ch_multiqc_files)
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
