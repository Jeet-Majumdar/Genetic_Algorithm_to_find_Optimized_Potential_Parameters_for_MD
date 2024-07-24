## Check convergence on the various runs and report out the ones that did not converge. 
## If All converged, report Success message

populations=( "pop_1" )
temperatures=( "300" )

population_strength=12
n_rows=2000
generic_file_name="log.nve"

for pop in ${populations[*]} 
do

cd $pop	

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
## Perform the convergence tests and output the ones that did not converge

IFS=

step_start=$(( $( grep "Step" ${generic_file_name} -n | cut -d: -f 1  ) + 1 ))
step_end=$(( $( grep "Step" ${generic_file_name} -n | cut -d: -f 1  ) + 1 + ${n_rows}))
data=$( sed -n "${step_start},${step_end}p" ${generic_file_name} )

echo $data > "data.temp"

cat > convergence_test.py << EOF
import numpy as np
import sys
a = np.loadtxt(sys.argv[1])
lines_from_last = 500
column = 3
std_a = np.std(a[-lines_from_last:, column])
avg_a = np.average(a[-lines_from_last:, column])

rel_dev = std_a / avg_a

if (rel_dev) > 0.001:
	print("NC "+str(rel_dev))
else:
	print("C "+str(rel_dev))

import matplotlib.pyplot as plt
plt.plot(a[:, column])
plt.savefig('total_energy.pdf')

EOF

python_return=$( echo $( python3 convergence_test.py data.temp) )

if [ $(echo $python_return | head -n1 | awk '{print $1;}' ) = "NC" ]
then
	echo "${temperature}.$instance NOT converged!  Dev: $(echo $python_return | head -n1 | awk '{print $2;}' )"
else
	echo "Finished checking ${temperature}.$instance successfully! CONVERGED!! Dev: $(echo $python_return | head -n1 | awk '{print $2;}' )"
fi

rm convergence_test.py
rm data.temp
###########
cd ../../
done

done

cd ../
done

