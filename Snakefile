configfile: "config.yaml"

with open(config["samples"]) as f:
    SAMPLES = [line.strip() for line in f if line.strip()]

OUTDIR = config["outdir"]
RAW_DATA = config["raw_data"]

rule all:
    input:
        expand(f"{OUTDIR}/qc/fastqc_raw/{{sample}}_1_fastqc.html", sample=SAMPLES),
        f"{OUTDIR}/featurecounts/gene_counts.tsv",
        f"{OUTDIR}/qc/multiqc/multiqc_report.html"

rule fastqc_raw:
    input:
        read1=f"{RAW_DATA}/{{sample}}_1.fq.gz",
        read2=f"{RAW_DATA}/{{sample}}_2.fq.gz"
    output:
        html1=f"{OUTDIR}/qc/fastqc_raw/{{sample}}_1_fastqc.html",
        html2=f"{OUTDIR}/qc/fastqc_raw/{{sample}}_2_fastqc.html"
    threads: config["threads"]["fastqc"]
    resources:
        mem_mb=4000,
        runtime=30
    log: 
        f"{OUTDIR}/logs/qc/fastqc_raw/{{sample}}.log"
    shell:
        """
        fastqc -t {threads} \
        -o {OUTDIR}/qc/fastqc_raw/ \
        {input.read1} {input.read2} \
        > {log} 2>&1
        """

rule fastp:
    input:
        read1=f"{RAW_DATA}/{{sample}}_1.fq.gz",
        read2=f"{RAW_DATA}/{{sample}}_2.fq.gz"
    output:
        read1=f"{OUTDIR}/trimmed_reads/{{sample}}_1.trim.fq.gz",
        read2=f"{OUTDIR}/trimmed_reads/{{sample}}_2.trim.fq.gz",
        json=f"{OUTDIR}/qc/fastp/{{sample}}.fastp.json",
        html=f"{OUTDIR}/qc/fastp/{{sample}}.fastp.html"
    params:
        extra=config["fastp"]["extra"]
    threads: config["threads"]["fastp"]
    resources:
        mem_mb=8000,
        runtime=60
    log: 
        f"{OUTDIR}/logs/fastp/{{sample}}.log"
    shell:
        """
        fastp -w {threads} \
            -i {input.read1} -I {input.read2} \
            -o {output.read1} -O {output.read2} \
            -j {output.json} -h {output.html} \
            {params.extra} \
            > {log} 2>&1
        """

rule star_index:
    input:
        genome=config["genome"],
        gtf=config["gtf"]
    output:
        directory(f"{OUTDIR}/star_index")
    params:
        extra=config["star_index"]["extra"]
    threads: config["threads"]["star_index"]
    resources:
        mem_mb=32000,
        runtime=120
    log: 
        f"{OUTDIR}/logs/star_index/star_index.log"
    shell:
        """
        STAR \
        --runMode genomeGenerate \
        --runThreadN {threads} \
        --genomeFastaFiles {input.genome} \
        --sjdbGTFfile {input.gtf} \
        --genomeDir {output} \
        {params.extra} \
        > {log} 2>&1
        """

rule star_alignment:
    input:
        genome_dir=f"{OUTDIR}/star_index",
        read1=f"{OUTDIR}/trimmed_reads/{{sample}}_1.trim.fq.gz",
        read2=f"{OUTDIR}/trimmed_reads/{{sample}}_2.trim.fq.gz"
    output:
        bam=f"{OUTDIR}/star/{{sample}}.aligned.sorted.bam",
        log_final=f"{OUTDIR}/star/{{sample}}.Log.final.out"
    params:
        prefix=f"{OUTDIR}/star/{{sample}}.",
    threads: config["threads"]["star_align"]
    resources: 
        mem_mb=32000,
        runtime=240
    log:
        f"{OUTDIR}/logs/star/{{sample}}.log" 
    shell:
        """
        STAR \
        --runThreadN {threads} \
        --genomeDir {input.genome_dir} \
        --readFilesIn {input.read1}, {input.read2} \
        --readFilesCommand zcat \
        --outFileNamePrefix {params.prefix} \
        --outSAMtype BAM SortedByCoordinate \
        > {log} 2>&1

        mv {params.prefix}Aligned.sortedByCoord.out.bam {output.bam}
        """

rule featurecounts:
    input:
        bams=expand(f"{OUTDIR}/star/{{sample}}.aligned.sorted.bam", sample=SAMPLES),
        gtf=config["gtf"]
    output:
        counts=f"{OUTDIR}/featurecounts/gene_counts.tsv",
        summary=f"{OUTDIR}/featurecounts/gene_counts.tsv.summary"
    params:
        extra=config["featurecounts"]["extra"]
    threads: config["threads"]["featurecounts"]
    resources:
        mem_mb=16000,
        runtime=60
    log:
        f"{OUTDIR}/logs/featurecounts/featurecounts.log"
    shell:
        """
        featureCounts -T {threads} \
            -a {input.gtf} \
            {params.extra} \
            -o {output.counts} \
            {input.bams} > {log} 2>&1
        """

rule multiqc:
    input:
        expand(f"{OUTDIR}/qc/fastqc_raw/{{sample}}_1_fastqc.html", sample=SAMPLES),
        expand(f"{OUTDIR}/qc/fastp/{{sample}}.fastp.json", sample=SAMPLES),
        expand(f"{OUTDIR}/star/{{sample}}.Log.final.out", sample=SAMPLES),
        f"{OUTDIR}/featurecounts/gene_counts.tsv.summary"
    output:
        f"{OUTDIR}/qc/multiqc/multiqc_report.html"
    params:
        outdir=f"{OUTDIR}/qc/multiqc",
        rootdir=OUTDIR
    log: 
        f"{OUTDIR}/logs/qc/multiqc.log"
    shell:
        "multiqc {params.rootdir} -o {params.outdir} > {log} 2>&1"







	




