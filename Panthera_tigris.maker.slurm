#!/bin/bash

#SBATCH --partition=macmanes
#SBATCH -J Panthera_tigris.maker
#SBATCH --ntasks=80
#SBATCH --mem 310Gb
#SBATCH --output %x.log
#SBATCH --dependency=afterany:274581
#SBATCh --exclude node117
source ~/.bash_profile

module purge
module load anaconda/colsa
source activate maker-3.01.02

species="Panthera_tigris"
genome="PanTig1.0_HiC.fasta"
PREFIX="Panthera_tigris"
ANNOT_VERSION="v2"
base="$species"__"$genome"_"$ANNOT_VERSION"

cd $HOME/dnazoo/"$species"/genome/maker

mpiexec -n 80 $HOME/test/maker/bin/maker \
-fix_nucleotides -base "$base" -quiet \
-genome $HOME/dnazoo/"$species"/genome/"$genome" \
/mnt/lustre/macmaneslab/macmanes/maker_control_files/maker_opts_swissprotmammals_plus_others_plus_ncrna.ctl \
/mnt/lustre/macmaneslab/macmanes/maker_control_files/maker_bopts.ctl \
/mnt/lustre/macmaneslab/macmanes/maker_control_files/maker_exe.ctl


fasta_merge -d "$base".maker.output/"$base"_master_datastore_index.log -o "$base"
gff3_merge -d "$base".maker.output/"$base"_master_datastore_index.log -o "$base".gff3 -n
lastal -P22 $HOME/transporters/swissprot "$base".all.maker.proteins.fasta -f BlastTab > blast.out
maker_functional_fasta $HOME/transporters/uniprot_sprot.fasta blast.out "$base".all.maker.proteins.fasta > "$base".functional.proteins.fasta
maker_functional_fasta $HOME/transporters/uniprot_sprot.fasta blast.out "$base".all.maker.transcripts.fasta > "$base".functional.transcripts.fasta
maker_functional_gff $HOME/transporters/uniprot_sprot.fasta blast.out "$base".gff3 > "$base".functional.gff3
maker_map_ids --prefix "$PREFIX" --justify 6 "$base".gff3 > "$base".genome.all.id.map
map_fasta_ids "$base".genome.all.id.map  "$base".functional.proteins.fasta
map_gff_ids "$base".genome.all.id.map  "$base".functional.gff3
map_fasta_ids "$base".genome.all.id.map  "$base".functional.transcripts.fasta
#rm -fr $base.maker.output/
rm -f blast.out
gzip *functional.gff3 *functional.*.fasta
rm -f *map
rm -f *all.maker.*.fasta
rm -f *gff3
