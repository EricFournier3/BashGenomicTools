#!/bin/bash

#Path to fastq directory
PathToFastq=""

#Output directory
OutDir=""

#Boolean to determine if the user want to compute those statistics
bCountReads="False"
bDoFastqc="False"
bComputeCoverage="False"

#Array to old average reads et reference length
aDnaLength=()

#Average reads length
readsAvgLength=0

#Average reference length
refAvgLength=0


helpme(){
<<com
Function to display help message
com

#If this function has been called from an error
if [[ ! -z $1 ]]
	then

		echo -e  "ERROR: "$1
fi


usage="
Program to compute quantitative and qualitative statistics from fastq files\n\n
Usage:\n
$(basename "$0") [-h] [-i arg1] [-o arg2] [-q] [-n] [-c \"arg3 arg4\"]\n\n

where:\n
    -h  show this help text\n
    -i  set the path to the input fastq files directory\n
    -o  set the path to the output directory\n
    -q  Count Reads for each isolate\n
    -n  Execute Fastqc on each fastq file\n
    -c  Compute coverage according to a reference genome: arg3 is the average reads length and arg4 the reference genome length\n"

echo -e $usage

}


CountReads(){
<<com
Function to compute number of reads in each paired end 
fastq files
com
	echo -e  ">>>>>>>>>>> Count Reads <<<<<<<<<<<\n\n"
	
<<com
Use only the R1 fastq.gz files for calculation
Formula is :
(Number of lines in the file) / 4 * 2
com
	for i in $(ls $PathToFastq*_R1*.gz)
		do
			mybasename=$(basename $i)
			isolate=${mybasename%%_*}
			echo "Count for $isolate"
			count=$(zcat -f $i | expr $(wc -l) / 4 \* 2)
			echo -e  $isolate"\t"$count >> $OutDir"ReadsCount.txt"
       done	           		
}

DoFastqc(){
<<com
Function to execute fastqc on each fastq file
com
	echo -e  ">>>>>>>>>>> Fastqc <<<<<<<<<<<\n\n"

	#Create the output directory
	mkdir $OutDir"FASTQC/"
 
        #Execute fastqc
        fastqc $PathToFastq*.gz -o $OutDir"FASTQC"

	#Remove zip files
        rm $OutDir"FASTQC/"*.zip
}

ComputeCoverage(){
<<com
Function to compute coverage according to a reference genome
com
	echo -e ">>>>>>>>>>> Compute Coverage <<<<<<<<<<<\n\n"

	#Header
	echo -e "Isolate\tAvgCoverage">>$OutDir"Coverage.txt"

<<com
Use only the R1 file for the calculation
Formula is:
((Number of lines in the fastq file) / 4 * 2) * (Average reads length) / (Average reference length)
com
	for i in $(basename -a $(ls $PathToFastq*.gz))
		do
			if [[ $i =~ "_R1" ]]
				then
					isolate=${i%%_*}
					echo "Compute coverage for $isolate"
					nbReads=$(zcat -f $PathToFastq$i | expr $(wc -l) / 4 \* 2)
					cov=$((($nbReads*$readsAvgLength)/$refAvgLength))
					echo -e $isolate"\t"$cov >> $OutDir"Coverage.txt"
			fi
        done
}

#Read command line options
while getopts ":hqnc:i:o:" myopt;do

	case $myopt in
		h) 
			helpme ""
			exit 1
		;;
		
		q)
			bCountReads="True"
		;;
		n)
			bDoFastqc="True"
		;;
		c) 
                        #Parenthesis needed to convert in array
			aDnaLength=( $OPTARG )

			#echo  "aDnaLength is ${#aDnaLength[@]}"
			#echo  "aDnaLength[0] is ${aDnaLength[0]}"
			#echo  "aDnaLength[1] is ${aDnaLength[1]}"

			if [ ${#aDnaLength[@]} != 2 ]
			   then  helpme "Option -c needs average reads and reference length\n"
			fi
			readsAvgLength=${aDnaLength[0]}
          		refAvgLength=${aDnaLength[1]}
			bComputeCoverage="True"
		;;
		i)
			      #echo "In -i => $OPTIND"

			      PathToFastq=$OPTARG
				
			      #Exit if input directory is not a directory
			      if [ ! -d $PathToFastq ]
				then echo $PathToFastq" is not a directory"
				exit 1
			      fi

			      #Add suffix /
			      if [[ ! $PathToFastq == */ ]]
				then
					PathToFastq=$PathToFastq"/"
			      fi

		;;
		o)

			     #echo "In -o => $OPTIND"
		             
			     OutDir=$OPTARG	

		             #Exit if output directory is not a directory
		             if [ ! -d $OutDir ]
			       then echo $OutDir" is not a directory"
			       exit 1
		             fi

		             #Add suffix /
		      	     if [[ ! $OutDir == */ ]]
			        then
				OutDir=$OutDir"/"
		             fi

		;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
		;;
		:)
			if [ $OPTARG == "i" ]
				then echo "Option i need a path to fastq files"
			elif [ $OPTARG == "o" ]
				then echo "Option o need a output directory"
		
			elif [ $OPTARG == "c" ]
				then echo "Option c need average reads and genome length"
			fi
			
			exit 1
		;;
	esac
done

#Error if the user didn't enter input or output directory
if [[ -z "$PathToFastq"  ]] || [[ -z "$OutDir" ]]

	then  helpme "Options -i and -o are needed\n"
fi

<<com
According to the user choice, execute the following functions
com

if [ $bCountReads == "True" ]
   then
      CountReads 
fi

if [ $bDoFastqc == "True" ]
   then
      DoFastqc
fi

if [ $bComputeCoverage == "True" ]
   then
      ComputeCoverage
fi


