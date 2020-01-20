#!/bin/bash
__author__ = 'Remi Maglione'

###Export some usefull PATH
export BLASTMAT=/usr/local/blast-data/
export RDP_JAR_PATH=/data/apps/rdp_classifier_2.2/rdp_classifier-2.2.jar

###Create .biom file (v1) from an otu file with Uclust taxonomic algorithm
clear
###Input control
if [ $# -eq 0 ] || [ "$1" = "-h" ]
then
    echo "usage: autoTaxo.sh input_file.fasta taxo_algo_name(optional) -ns(optional)"
    echo "input_file.fasta must be the .fasta file used to generate the otu file"
    echo "(optional) taxo_algo_name may be the name of the algorythme for taxonomic annotation"
    echo "taxo_algo_name: uclust, blast, RDP [default:uclust]"
    echo "-ns: remove singleton from otu_table [default: deactivate]"
    exit 1
fi

###Input file
file=$1

###For future Dev###
if [ -n "$2" ] && [ "$2" = "blast" ]
 then
    taxoAlgo=$2
elif [ -n "$2" ] && [ "$2" = "RDP" ]
 then
    taxoAlgo=$2
else
    taxoAlgo="Uclust"
fi

###Input control
if [ "${file##*.}" = "fasta" ]
 then
    filename=$(basename $file .fasta)
elif [ "${file##*.}" = "fna" ]
 then
    filename=$(basename $file .fna)
else
    echo "Error : Input file is not a .fasta or .fna file"
    echo "Check usage with autoTaxo.sh -h"
    exit 1
fi

###Functions###
#SpinerBar adapted from
#https://stackoverflow.com/questions/12498304/using-bash-to-display-a-progress-working-indicator#12498305
spinner()
{
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r %c  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
}

###Take representative sequence (most abundant) from the otu file
OTUfile="./""$filename""_otu_def/""$filename""_otus.txt"


echo ""
echo "#####################################"
echo "Sample name = $filename"
echo "OTU file = $OTUfile"
echo "Taxo Algo = $taxoAlgo"
echo ""
echo "#######pick_rep_set.py:START#########"

pick_rep_set.py -i $OTUfile -f $file -m most_abundant & spinner

###Assign the taxonomy from the representative otu file
repSet="$file""_rep_set.fasta"

echo ""
echo "#######pick_rep_set.py:DONE#########"
echo "rep Set = $repSet"
echo "Taxo Algo = Uclust"
echo ""
echo "#####assign_taxonomy.py:START#######"


if [ -n "$2" ] && [ "$2" = "blast" ]
 then
    assign_taxonomy.py -i $repSet -r /data/users/remi/SILVA_128_QIIME_release/rep_set/rep_set_16S_only/97/97_otus_16S.fasta -t /data/users/remi/SILVA_128_QIIME_release/taxonomy/16S_only/97/consensus_taxonomy_all_levels.txt -m blast & spinner
    taxoFile="./blast_assigned_taxonomy/""$file""_rep_set_tax_assignments.txt"
elif [ -n "$2" ] && [ "$2" = "RDP" ]
 then
    assign_taxonomy.py -i $repSet -r /data/users/remi/SILVA_128_QIIME_release/rep_set/rep_set_16S_only/97/97_otus_16S.fasta -t /data/users/remi/SILVA_128_QIIME_release/taxonomy/16S_only/97/consensus_taxonomy_all_levels.txt -m rdp --rdp_max_memory=60000 & spinner
    taxoFile="./rdp_assigned_taxonomy/""$file""_rep_set_tax_assignments.txt"
elif [ -n "$4" ] && [ "$4" = "99" ]
 then
    echo "99% similarity"
    assign_taxonomy.py -i $repSet -r /data/users/remi/SILVA_132_QIIME_release/rep_set/rep_set_16S_only/99/silva_132_99_16S.fna -t /data/users/remi/SILVA_132_QIIME_release/taxonomy/16S_only/99/consensus_taxonomy_all_levels.txt & spinner 
    taxoFile="./uclust_assigned_taxonomy/""$file""_rep_set_tax_assignments.txt"
else
    echo "97% similarity"
    assign_taxonomy.py -i $repSet -r /data/users/remi/SILVA_132_QIIME_release/rep_set/rep_set_16S_only/97/silva_132_97_16S.fna -t /data/users/remi/SILVA_132_QIIME_release/taxonomy/16S_only/97/consensus_taxonomy_all_levels.txt & spinner
    taxoFile="./uclust_assigned_taxonomy/""$file""_rep_set_tax_assignments.txt"
fi

###Create the .biom file from the otu and taxo file
biom="$filename""_SILVA.biom"

echo ""
echo "######assign_taxonomy.py:DONE#######"
echo "biom = $biom"
echo "taxo File = $taxoFile"
echo ""
echo "######make_otu_table.py:START#######"


make_otu_table.py -i $OTUfile -t $taxoFile -o $biom & spinner

###Control singleton filtering
if [ -n "$3" ] && [ "$3" = "-ns" ]
 then
    ###Filter singleton from .biom file
    filteredBiom="$filename""-ns.biom"

    echo ""
    echo "######make_otu_table.py:DONE#######"
    echo "biom = $biom"
    echo "Filtered biom = $filteredBiom"
    echo ""
    echo "######filter_otus_from_otu_table.py:START#######"


    filter_otus_from_otu_table.py -i $biom -o $filteredBiom -n 2 & spinner
fi

###Convert the .biom file from v2 to v1
if [ -n "$3" ] && [ "$3" = "-ns" ]
 then
    fixedBiom="$filename""-ns-fixed.biom" 
    echo ""
    echo "#######filter_otus_from_otu_table.py:DONE#######"
    biom=$filteredBiom
else
    fixedBiom="$filename""-ns-fixed.biom" 
    echo ""
    echo "#######make_otu_table.py:DONE#######"
fi

echo "Fixed biom = $fixedBiom"
echo ""
echo "########biom convert:START##########"


biom convert -i $biom -o $fixedBiom --table-type="OTU table" --to-json & spinner

echo ""
echo "########biom convert:DONE##########"
echo ""
echo "Scripted by Remi Maglione For Kembel Lab"
