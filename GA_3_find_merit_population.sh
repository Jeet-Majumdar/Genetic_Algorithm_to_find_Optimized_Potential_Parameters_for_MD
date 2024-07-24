# Find merit of each population

file_population_properties="population_properties.dat"
output_text_file="${file_population_properties}_meritted"

for pop in pop_1
do

cd $pop

rm ${output_text_file}

cat > find_merit.py << EOF
import numpy as np
file=np.loadtxt("${file_population_properties}")
exp_values_liq={'240':0.86992 , '260': 0.86782, '280': 0.86328, '300': 0.84881, '320': 0.82074, '340': 0.79299, '360': 0.76493, '373': 0.74561, '380': 0.73555, '400': 0.70653, '420': 0.67476, '440': 0.63679, '460': 0.58979, '480': 0.53147}

total_relative_deviation = 0.0
M = np.zeros(np.shape(file))

f = open("${output_text_file}", "a")

dev=[]
for i in range(len(file)):
        deviation = np.abs( exp_values_liq[str(int(file[i, 1]))] - file[i, 2] )/exp_values_liq[str(int(file[i, 1]))]
        dev.append(deviation)

file = np.append(file, np.transpose([dev]), axis=1)

file_sorted_by_merit = file[ np.argsort( file[:,3] ) ]

for i in range(len(file_sorted_by_merit)):
    f.write(str(int(file_sorted_by_merit[i, 0]))+" "+str(int(file_sorted_by_merit[i, 1]))+" "+str(file_sorted_by_merit[i, 2])+" "+str(file_sorted_by_merit[i, 3])+"\n")


f.close()

EOF

python3 find_merit.py


rm find_merit.py

cd ../
done
