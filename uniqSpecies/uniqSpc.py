__author__ = 'Remi Maglione'

import argparse
import sys

parser = argparse.ArgumentParser(description=
                                 "Keep only one species in a multiple fasta file")
parser.add_argument('-i', '--input-fasta', type=str, required=True,
                    help='Name of the input .fasta file.\nMust contain: seq name and sequence')

parser.add_argument('-o', '--output-fasta', type=str, required=False,
                    help='Name of the output .fasta file\nDefault: add "_uniq" as input suffix')

try:
    args = parser.parse_args()
except:
    sys.exit()


if not args.output_fasta:
    outFile=args.input_fasta+"_uniqSpc"
else:
    outFile=args.output_fasta


if __name__ == '__main__':
    spcDict={}
    spcDictSensor=False
    blankLine=False
    with open(args.input_fasta, "r") as fastaFile:
        with open(outFile, "w") as outFile:
            while True:
                line = fastaFile.readline().strip()
                if not line:
                    if blankLine is True:
                        break
                    blankLine=True
                    outFile.write(line+"\n")
                elif line:
                    if line[0]==">":
                        if not line.split()[2] in spcDict:
                            spcDictSensor=False
                            d={line.split()[2]:line.split()[1]}
                            spcDict.update(d)
                            outFile.write(line+"\n")

                        else:
                            spcDictSensor=True

                    elif not spcDictSensor:
                        outFile.write(line+"\n")
blankLine=False
