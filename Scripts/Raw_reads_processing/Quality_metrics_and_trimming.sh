# NB: This page presents the execution steps and parameters. In order to reproduce, the reader needs to adjust the input and output files and directories.
# Load required modules
	module load ngs tools 
	module load perl/5.36.1
	module load java/17-openjdk
	module load fastqc/0.12.1
	module load multiqc/1.12
	module load fastp/0.23.2

#1. QualityControl with -fastqc | v.0.12.1 

	# Obtain the paths to all raw .fastq.gz sequences:
	find . -type f -name '*.gz' > all_paths_gz.txt

	# Use a loop to iterate over all files
	for fq in $(cat all_paths_gz.txt); 
	do
    	fastqc -t 20 "$fq" -o ../processed_data/QC_results/befor_trim
	done

	#Use MultiQC tool to analyse multiple QC reports
	multiqc ../processed_data/QC_results/before_trim -o QC_results/before_trim/multiqc

#2. Trimming with -fastp | v.0.23.2
	# Files in fastq_old directory containing fastq.gz reads look like this: <<LB7_S6_L002_R1_001.fastq.gz>>, major difference is whether they come from lane1 (L001), or lane 2 (L002):
	LB=../../raw_seq/fastq_old #path to directory

	# Get unique sample names in this directory (everything before _S):
	labels=$(ls ${LB}/*.fastq.gz | sed 's/.*\///g' | sed 's/_S.*//g' | sort -u)
	
	# Loop trimming through each sample
	for fq in $labels
	do
	    echo "Processing sample: $fq"
	    # Find R1 and R2 files for this sample
	    read1=$(ls ${LB}/${fq}_*_R1_*.fastq.gz)
	    read2=$(ls ${LB}/${fq}_*_R2_*.fastq.gz)
	    # Run fastp
	    fastp -W 4 -5 20 -3 20 \
	    	  --detect_adapter_for_pe \
	    	  --trim_poly_g \
	            -i "$read1" \
	            -I "$read2" \
	            -o "trimmed_reads/${fq}_R1_trimmed.fastq.gz" \
	            -O "trimmed_reads/${fq}_R2_trimmed.fastq.gz" \
	            --json ./trim_reports/"$fq".json \
	            --html ./trim_reports/"$fq".html \
	        	--thread 6
	        echo "Completed: $fq"  
	done
	echo "All samples processed!"	
	
	#Use MultiQC tool to analyse multiple QC reports
	cd ./processed_data/trimming/trim_reports
	#IMPORTANT! For multiqc to recognise fastp json reports, they must be named *.fastp.json
		#to rename files use: 
		for f in *.json; do
  			mv "$f" "${f%.json}.fastp.json"
		done
	#Run MultiQC:
	multiqc ./ -o ./multiqc

	#MultiQC reports before and after trimming are available in the Documents folder.