##!/bin/bash

r1="/mnt/data1/akmats20/data/finalmalta_1.fq.gz"
r2="/mnt/data1/akmats20/data/finalmalta_2.fq.gz"
genome="/mnt/data1/akmats20/results/pipeline/genome.nextpolish.fasta"
rounds=3
threads=24
log_file="hapog_pipeline.log"

# Redirect all output to log file
exec > >(tee -i "$log_file")
exec 2>&1

PROGRESS_FILE="timestamps.log"
log_progress() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$PROGRESS_FILE"
}

# Adjust this based on whether the initial genome file is compressed
cat $genome | sed -e 's/_.*//g' > hapog-0.fasta
genome=hapog-0.fasta

for ((i=1; i<=${rounds}; i++))
do
    log_progress "Index the genome and do alignment (Round $i)"
    bwa index $genome
    bwa mem -t $threads $genome $r1 $r2 \
        | samtools sort -@ $threads > sorted.bam

    log_progress "Index BAM and genome (Round $i)"
    samtools index -@ $threads sorted.bam

    log_progress "Polish with Hapo-G (Round $i)"
    hapog --genome $genome -b sorted.bam -o ${i} -t $threads -u

    genome=${i}/hapog_results/hapog.fasta
done

#Filter small contigs
log_progress "Filtering contigs < 1000 bp..."
bioawk -c fastx 'length($seq) > 1000{print ">" $name "\n" $seq}' /3/hapog_results/hapog.fasta > sizeFiltered.fasta
