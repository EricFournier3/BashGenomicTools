#!/bin/bash

helpme(){
<<com
Function to display help message
com

usage="
Program to create one directory per fasta files found in the input directory\n\n
Usage:\n
$(basename "$0") [-h] [-f arg1] [-o arg2]\n\n

where:\n
    -h  show this help text\n
    -s  set the path to the input fasta files directory\n
    -o  set the path to the output directory\n"	

echo -e $usage

}

#Path to the input directory with fasta files
PathToFasta=""

#Path to the output directory
DirOut=""
 
#Read command line options
while getopts ":hf:o:" opt; do
  case $opt in
    h)
      helpme
      exit 1
    ;;
    f)
      PathToFasta=$OPTARG
      
      #Exit if input directory is not a directory
      if [ ! -d $PathToFasta ]
	then echo $PathToFasta" is not a directory"
	exit 1
      fi

      #Add suffix /
      if [[ ! $PathToFasta == */ ]]
	then
        	PathToFasta=$PathToFasta"/"
      fi
	
      
      ;;
    o)
      DirOut=$OPTARG

      #Exit if output directory is nor a directory
      if [ ! -d $DirOut ]
	then echo $DirOut" is not a directory"
	exit 1
      fi
      
      #Add suffix /
      if [[ ! $DirOut == */ ]]
	then
        	DirOut=$DirOut"/"
      fi

      ;;

    #Invalid option in the command line
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    #Argument is missing for one option
    :)
	if [ $OPTARG == "f" ]

		then echo "Option -f requires a path to fasta assemblies"
	else
		echo "Option -o requires an output directory" 
        fi
        exit 1
      ;;
	
  esac
done

#Number of fasta files in the input directory
NbFasta=$(ls -1 FASTADIR/*.fasta  2>/dev/null | wc -l)

#Need a minimum of one fasta file
if [[ $NbFasta -gt 0 ]]
	then
        
        #Create one directory for every single fasta file
	for i in $(basename  -a $(ls $PathToFasta/*.fasta))
		do 
			
			dir=${i%.fasta}
	  
			if [[ ! -d $DirOut$dir ]]
				then    
					echo "Create directory for $i"
					mkdir $DirOut$dir
			fi
                    
                        #Move the fasta file in this new directory
			mv $PathToFasta$i $DirOut$dir
	done
else
	echo "No fasta files in the input directory"

fi
