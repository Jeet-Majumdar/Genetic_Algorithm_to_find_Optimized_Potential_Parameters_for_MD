## Extract the different properties of the populations

populations=( "pop_1" )
temperatures=( "300" )

population_strength=12
n_rows=2000
generic_file_name="log.nve"

file_population_properties="population_properties.dat"


for pop in ${populations[*]}
do

cd $pop

rm ${file_population_properties}

for temperature in ${temperatures[*]}
do

folders=$( ls -d ${temperature}.* )
folders=(${folders})

for i in ${folders[*]}
do

temperature=$( echo ${i} | cut -d'.' -f 1 )
instance=$( echo ${i} | cut -d'.' -f 2 )

cd $i
cd temp


## Now they are into a folder where the run data exist.

IFS=

step_start=$(( $( grep "Step" ${generic_file_name} -n | cut -d: -f 1  ) + 1 ))
step_end=$(( $( grep "Step" ${generic_file_name} -n | cut -d: -f 1  ) + 1 + ${n_rows}))
# data=$( sed -n "${step_start},${step_end}p" ${generic_file_name} )

density=$( awk -v var="$step_end" 'NR==var' ${generic_file_name} | awk '{print $13}' )

echo "${temperature}.${instance} ${temp} $density" 

###########
cd ../../
echo "${instance} ${temperature} $density" >> ${file_population_properties}

done

done

cd ../
done

