## Create new population based on the merit Ordered previous population

cwd=$(pwd)


input_population="pop_1"
output_population="pop_2"
no_of_atom_types=9
population_strength_input=12

file_population_properties="population_properties.dat"
file_population_properties_meritted="${file_population_properties}_meritted"

root_input=${cwd}/${input_population}
root_output=${cwd}/${output_population}

meritted_text_file_path="${cwd}/${input_population}/${file_population_properties_meritted}"

population_strength_input=$( wc -l < ${meritted_text_file_path} )


####################################################################################################################################

fittest_1st_rank=$( sed -n '1p' ${meritted_text_file_path} | awk '{print $1}')   # Store simulation number of the first fittest
temp_1st=$( sed -n '1p' ${meritted_text_file_path} | awk '{print $2}')   # Store temperature of the first fittest

fittest_2nd_rank=$( sed -n '2p' ${meritted_text_file_path} | awk '{print $1}')   # Store simulation number of the second fittest
temp_2nd=$( sed -n '2p' ${meritted_text_file_path} | awk '{print $2}')   # Store temperature of the the second fittest

remaining=$(( ${population_strength_input} - 2 ))   # This is coz 1st and 2nd best fit will always be selected

file_crosover_mutate_combinations="crosover_mutate_combinations.txt"


lammps_data_file="data.250N_ethanethiol_liquid_AA"
lammps_imput_file="in.npt_nve"
parameter_file="para.ethanethiol"
runfile="run_lammps_pkm2"
nMolecules=250

mkdir ${output_population}

actual_folder_1=$( ls -d ${root_input}/${temp_1st}.${fittest_1st_rank}.*  )
actual_folder_2=$( ls -d ${root_input}/${temp_2nd}.${fittest_2nd_rank}.*  )

# PAUSE # echo "${root_input}/${actual_folder_1}  JEET"

# Copy the first two best untouched.
cp -r ${actual_folder_1} ${root_output}/${temp_1st}.${population_strength_input}.
echo "${fittest_1st_rank} 1st BEST COPIED"
cp -r ${actual_folder_2} ${root_output}/${temp_2nd}.$(( ${population_strength_input} - 1 )).
echo "${fittest_2nd_rank} 2nd BEST COPIED"

#PAUSE# echo "${root_input}      ${actual_folder_1}"

####################################################################################################################################

cat > merit_rank_teller.py << EOF
import numpy as np
import sys

search_rank = int(sys.argv[1])

meritted_text_file_path = np.loadtxt("${meritted_text_file_path}")

# meritted_text_file_path[:, [1, 0]] = meritted_text_file_path[:, [0, 1]]

temp = meritted_text_file_path[:, 1]
rank = meritted_text_file_path[:, 0]

d = {}
for A, B in zip(rank, temp):
    d[A] = B

print(d[search_rank])

EOF

count=0

str=""
i_new=0
i=0
while [ $i -lt ${remaining} ] 
do
	flag=0
	rand_1=0
	rand_2=0
	while [ $flag -eq 0 ]
	do
		rand_1=$( shuf -i 1-${population_strength_input} -n 1 )
		rand_2=$( shuf -i 1-${population_strength_input} -n 1 )	
		
		if [ $rand_1 -eq $rand_2 ] || [ $rand_1 -gt $rand_2 ]
		then
			flag=0
		else
			flag=1
		fi
		
	done
	str="$str ${rand_1}_${rand_2}_a ${rand_1}_${rand_2}_b"
        
	# echo $(python3 merit_rank_teller.py ${rand_1} ) $(python3 merit_rank_teller.py ${rand_2} )


	str=$( echo "$str" | xargs -n1 | sort -u | xargs  )


	i_new=$( echo "$str" | wc -w )

	if [ $i_new -le $i ]  || [ "$(python3 merit_rank_teller.py ${rand_1} )" != "$(python3 merit_rank_teller.py ${rand_2} )" ]
	then
		continue
	else
		i=$i_new
	fi

	# echo "${rand_1} ${rand_2}" # >> ${crosover_mutate_combinations}
	
	# Now select simulation numbers rand_1 and rand_2 to crossover and mutate


	######################## Crossover ##############################
	
temp=$( python3 merit_rank_teller.py ${rand_1} | cut -d'.' -f 1)

folder_1=$(ls -d ${input_population}/${temp}.${rand_1}.* )
folder_2=$(ls -d ${input_population}/${temp}.${rand_2}.* )


count=$(( $count + 1 ))
fol_c1=$count

fol1="${output_population}/${temp}.${count}.${rand_1}.${rand_2}."
mkdir ${fol1}
echo "CREATED from ${rand_1} ${rand_2} with ${fol_c1} RANK"

cp ${folder_1}/in.npt_nve  ${fol1}/in.npt_nve
# cp ${folder_1}/para.ethanethiol.* ${fol1}/para.ethanethiol.${rand_1}
cp ${folder_1}/data.250N_ethanethiol_liquid_AA ${fol1}
# cp ${folder_2}/para.ethanethiol.* ${fol1}/para.ethanethiol.${rand_2}
cp ${runfile} ${fol1}
sed -i "s/^.*para.*$/include         para.ethanethiol.${fol_c1}/" ${fol1}/in.npt_nve

count=$(( $count + 1 ))
fol_c2=$count

mkdir ${output_population}/${temp}.${count}.${rand_1}.${rand_2}.
fol2="${output_population}/${temp}.${count}.${rand_1}.${rand_2}."
echo "CREATED from ${rand_1} ${rand_2} with ${fol_c2} RANK"

cp ${folder_1}/in.npt_nve  ${fol2}/in.npt_nve
# cp ${folder_1}/para.ethanethiol.* ${fol2}/para.ethanethiol.${rand_1}
cp ${folder_1}/data.250N_ethanethiol_liquid_AA ${fol2}
# cp ${folder_2}/para.ethanethiol.* ${fol2}/para.ethanethiol.${rand_2}
cp ${runfile} ${fol2}
sed -i "s/^.*para.*$/include         para.ethanethiol.${fol_c2}/" ${fol2}/in.npt_nve


line_till_copy_para=$(( $( grep "pair_coeff" ${folder_1}/para.ethanethiol.* -n -m 1 | cut -d: -f 1  ) - 1 ))

IFS=
copy_part1=$( sed -n "1,${line_till_copy_para}p" ${folder_1}/para.ethanethiol.* ) 
echo ${copy_part1} > ${fol1}/para.ethanethiol.${fol_c1}.temp 
copy_part2=$( sed -n "1,${line_till_copy_para}p" ${folder_2}/para.ethanethiol.* )
echo ${copy_part2} > ${fol2}/para.ethanethiol.${fol_c2}.temp

echo "" >> ${fol1}/para.ethanethiol.${fol_c1}.temp
echo "" >> ${fol2}/para.ethanethiol.${fol_c2}.temp

#PAUSE# random_cut_point=0
no_of_atom_types=$(( $no_of_atom_types - 1 ))
#PAUSE# random_cut_point=$( shuf -i 1-${no_of_atom_types} -n 1 )
#PAUSE# random_cut_point=$( awk -v min=1 -v max=${no_of_atom_types} 'BEGIN{srand(); print int(min+rand()*(max-min+1))}' )

#PAUSE# next_copy_part_begin=$(( $line_till_copy_para + 1 ))
#PAUSE# next_copy_part_end=$(( $line_till_copy_para + 1 + $random_cut_point ))
#PAUSE# copy_part1=$( sed -n "${next_copy_part_begin},${next_copy_part_end}p" ${folder_1}/para.ethanethiol.* )
#PAUSE# copy_part2=$( sed -n "${next_copy_part_begin},${next_copy_part_end}p" ${folder_2}/para.ethanethiol.* )
#PAUSE# echo ${copy_part1} >> ${fol1}/para.ethanethiol.${fol_c1}.temp
#PAUSE# echo ${copy_part2} >> ${fol2}/para.ethanethiol.${fol_c2}.temp

# Now crossover the remaining atomtypes

#PAUSE# no_of_atom_types=$(( $no_of_atom_types + 1 ))
#PAUSE# crossover_section_1=$(tac ${folder_1}/para.ethanethiol.* | grep "pair_coeff" -m $(( $no_of_atom_types - $random_cut_point )) |awk '{print $2 " " $3 " " $4 " " $5}' )
#PAUSE# crossover_atom_types=$(tac ${temp_out_folder}/para.ethanethiol.${rand_1} | grep "pair_coeff" -m $(( $no_of_atom_types - $random_cut_point )) |awk '{print $6}' | cut -d# -f 2 )
#PAUSE# 
#PAUSE# crossover_section_2=$(tac ${folder_2}/para.ethanethiol.* | grep "pair_coeff" -m $(( $no_of_atom_types - $random_cut_point )) |awk '{print $2 " " $3 " " $4 " " $5}' )


#PAUSE# no_of_atom_types=$(( $no_of_atom_types + 1 ))

crossover_section_1=$(tac ${folder_1}/para.ethanethiol.* | grep "pair_coeff"  |awk '{print $2 " " $3 " " $4 " " $5}' )
crossover_atom_types=$(tac ${folder_1}/para.ethanethiol.* | grep "pair_coeff" |awk '{print $6}' | cut -d# -f 2 )

crossover_section_2=$(tac ${folder_2}/para.ethanethiol.* | grep "pair_coeff" |awk '{print $2 " " $3 " " $4 " " $5}' )

echo ${crossover_section_1} > crossover_section_1.temp
echo ${crossover_section_2} > crossover_section_2.temp
echo ${crossover_atom_types} > crossover_section_atom_types.temp

cat > process_crossover.py << EOF
import numpy as np
import sys
import random

def beta():
	n = 50
	mu = random.uniform(0, 1)
	if mu <= 0.5:
		return (2.0 * mu)**(1.0/(n + 1))
	else:
		return (0.5/(1-mu))**(1.0/(n + 1))

def mutation(original):
	return (original + original * random.uniform(-0.1, 0.1))

def sbx_mutation(par1, par2 ):
	b = beta()
	child1 = 0.5*( (1+b)*par1 - (1-b)*par2 )
	b = beta()
	child2 = 0.5*( (1+b)*par1 - (1-b)*par2 )	
	
	child1 = mutation(child1)
	child2 = mutation(child2)
	
	return child1, child2
	

sec1=np.loadtxt("crossover_section_1.temp")
sec2=np.loadtxt("crossover_section_2.temp")
type=[]
with open('crossover_section_atom_types.temp') as my_file:
	for line in my_file:
		type.append(line)    

# Process here onwards:
if len(sec1) == len(sec2) and len(sec1) == len(type):
	# print("ALRIGHT")
	pass
else:
	print("WRONG SELECTIONS ARE HAPENNING! PLS CHECK!")
	print("Exiting")
	exit



f1 = open("fol1_append.temp", "w")
f2 = open("fol2_append.temp", "w")
for i in range(len(sec1)):

	E_ch1, E_ch2 = sbx_mutation( sec1[i, 2], sec2[i, 2]  )
	S_ch1, S_ch2 = sbx_mutation( sec1[i, 3], sec2[i, 3]  )

	f1.write("pair_coeff "+ str(int(sec1[i, 0]))+" " + str(int(sec1[i, 1]))+" " + str(E_ch1)+" " + str(S_ch1)+"   " + "#"+str(type[i]))
	f2.write("pair_coeff "+ str(int(sec2[i, 0]))+" " + str(int(sec2[i, 1]))+" " + str(E_ch2)+" " + str(S_ch2)+"   " + "#"+str(type[i]))

f1.close()
f2.close()


EOF

python3 process_crossover.py # crossover_section_1.temp crossover_section_2.temp crossover_section_atom_types.temp


cat ${fol1}/para.ethanethiol.${fol_c1}.temp fol1_append.temp > ${fol1}/para.ethanethiol.${fol_c1}
rm ${fol1}/para.ethanethiol.${fol_c1}.temp
cat ${fol2}/para.ethanethiol.${fol_c2}.temp fol2_append.temp > ${fol2}/para.ethanethiol.${fol_c2}
rm ${fol2}/para.ethanethiol.${fol_c2}.temp

rm fol1_append.temp
rm fol2_append.temp
rm crossover_section_1.temp
rm crossover_section_2.temp
rm crossover_section_atom_types.temp


rm process_crossover.py



done

rm merit_rank_teller.py

