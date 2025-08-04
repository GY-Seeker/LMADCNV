#!/bin/bash
# make cnv baseline (gatk)

source activate gatk

gatk=/data/tool/gatk-4.1.6.0/gatk
ref=/data/WES/database/ref/human/ucsc.hg19.fasta
ref_dict=/data/WES/database/ref/human/ucsc.hg19.dict
interval=Exome_Target_hg19_ucsc.interval_list

# make cnv interval
$gatk PreprocessIntervals -R $ref -L $interval --bin-length 5000 -imr OVERLAPPING_ONLY -O targets.preprocessed.5000.interval_list

# get sample reads counts
for num in 1 2 3 4 5 6 7 8 9
do
input_bam=/data/WES/TestPath/sample${num}/realign/sample${num}.bam
$gatk CollectReadCounts -L targets.preprocessed.interval_list -R $ref -imr OVERLAPPING_ONLY -I $input_bam --format TSV -O sample${num}.tsv
done

# anno gc content in  interval
$gatk AnnotateIntervals -L targets.preprocessed.5000.interval_list -R $ref -imr OVERLAPPING_ONLY -O targets.preprocessed.5000.annotated.tsv

# interval filter
sample_rc=''
for num in 1 2 3 4 5 6 7 8 9
do
sample_rc=${sample_rc}' -I 'sample${num}.tsv
done
$gatk FilterIntervals -L targets.preprocessed.5000.interval_list --annotated-intervals targets.preprocessed.5000.annotated.tsv $sample_rc -imr OVERLAPPING_ONLY -O gc.filtered.bin5000.interval_list

# make ploidy priors
$gatk DetermineGermlineContigPloidy -L gc.filtered.bin5000.interval_list --interval-merging-rule OVERLAPPING_ONLY $sample_rc --contig-ploidy-priors contig_ploidy_priors.tsv --output ploidy-calls --output-prefix ploidy --verbosity DEBUG

# make baseline
$gatk GermlineCNVCaller --run-mode COHORT -L gc.filtered.bin5000.interval_list $sample_rc --contig-ploidy-calls ploidy-calls/ploidy-calls --annotated-intervals targets.preprocessed.5000.annotated.tsv --interval-merging-rule OVERLAPPING_ONLY --output baseline --output-prefix baseline --verbosity DEBUG

# call cnv
$gatk DetermineGermlineContigPloidy --model ploidy-calls/ploidy-model -I sample.tsv -O sample --output-prefix sample --verbosity DEBUG
$gatk GermlineCNVCaller --run-mode CASE -I sample.tsv --contig-ploidy-calls sample/sample-calls --model baseline/baseline-model --output sample_call --output-prefix sample --verbosity DEBUG
$gatk PostprocessGermlineCNVCalls --model-shard-path baseline/baseline-model --calls-shard-path sample_call/sample-calls --allosomal-contig chrX --allosomal-contig chrY --contig-ploidy-calls sample/sample-calls --sample-index 0 --output-genotyped-intervals sample-intervals.vcf --output-genotyped-segments sample-segments.vcf --output-denoised-copy-ratios sample-ratio.vcf --sequence-dictionary $ref_dict
