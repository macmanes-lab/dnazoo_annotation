#SBATCH --partition=macmanes,shared
#SBATCH -J Panthera_tigris.maker
#SBATCH --ntasks=48
#SBATCH --mem 110Gb
#SBATCH --output %x.log
#SBATCH --dependency=afterany:262978
source ~/.bash_profile

module purge
module load anaconda/colsa
source activate maker-3.01.02

base="Panthera_tigris"
genome="$HOME/dnazoo/"$base"/genome/PanTig1.0_HiC.fasta"
PREFIX="Panthera_tigris"

mkdir -p $HOME/dnazoo/"$base"/genome/maker
cd $HOME/dnazoo/"$base"/genome/maker

mpiexec -n 48 $HOME/test/maker/bin/maker \
-fix_nucleotides -base "$base" -quiet \
-genome "$genome" \
/mnt/lustre/macmaneslab/macmanes/maker_control_files/maker_opts_swissprotmammals.ctl \
/mnt/lustre/macmaneslab/macmanes/maker_control_files/maker_bopts.ctl \
/mnt/lustre/macmaneslab/macmanes/maker_control_files/maker_exe.ctl


fasta_merge -d "$base".maker.output/"$base"_master_datastore_index.log -o "$base"
gff3_merge -d "$base".maker.output/"$base"_master_datastore_index.log -o "$base".gff3 -n
lastal -P22 $HOME/transporters/swissprot "$base".all.maker.proteins.fasta -f BlastTab > blast.out
maker_functional_fasta $HOME/transporters/uniprot_sprot.fasta blast.out "$base".all.maker.proteins.fasta > "$base".functional.proteins.fasta
maker_functional_fasta $HOME/transporters/uniprot_sprot.fasta blast.out "$base".all.maker.transcripts.fasta > "$base".functional.transcripts.fasta
maker_functional_gff $HOME/transporters/uniprot_sprot.fasta blast.out "$base".gff3 > "$base".functional.gff3
maker_map_ids --prefix "$PREFIX" --justify 6 "$base".functional.gff3 > "$base".genome.all.id.map
map_fasta_ids "$base".genome.all.id.map  "$base".functional.proteins.fasta
map_gff_ids "$base".genome.all.id.map  "$base".functional.gff3
map_fasta_ids "$base".genome.all.id.map  "$base".functional.transcripts.fasta
