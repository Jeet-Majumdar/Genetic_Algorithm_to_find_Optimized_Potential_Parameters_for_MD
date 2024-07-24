
for i in $(seq 1 12)
do

lammps_data_file="data.250N_ethanethiol_liquid_AA"
parameter_file="para.ethanethiol"
runfile="run_lammps_pkm2"
temperature=280 # 340
pressure=1.0
nMolecules=250

newdir="${temperature}.${i}."  # First 3 digit temp, then next digits signifies number of instances

mkdir ${newdir}
cd ${newdir}

cp ../${lammps_data_file} ./
cp ../${runfile} ./
sed -i "7s/.*/#PBS -N  ${newdir}/" ${runfile}

cat > gen.py.temp << EOF
import sys
import random
a=float(sys.argv[1])
mini = a - a*0.1
maxi = a + a*0.1
print(random.uniform(mini, maxi))
EOF

cat > ${parameter_file}.${i} << EOF
pair_style      lj/charmm/coul/long  9.0 10.5
bond_style      harmonic
angle_style     harmonic
dihedral_style  charmm
improper_style  none
kspace_style    pppm 0.0001

mass 1 12.01 # c3
mass 2 1.008 # h1
mass 3 1.008 # hc
mass 4 1.008 # hs
mass 5 32.06 # sh

bond_coeff 1 291.9     1.3473  # 1  hs-sh
bond_coeff 2 213.7     1.8435  # 2  c3-sh
bond_coeff 3 330.6     1.0969  # 3  c3-h1
bond_coeff 4 300.9     1.5375  # 4  c3-c3
bond_coeff 5 330.6     1.0969  # 5  c3-hc

angle_coeff 1 46.4      109.56  # 1  c3-c3-h1
angle_coeff 2 46.3      109.80  # 2  c3-c3-hc
angle_coeff 3 60.4      113.13  # 3  c3-c3-sh
angle_coeff 4 44.5       96.40  # 4  c3-sh-hs
angle_coeff 5 39.2      108.46  # 5  h1-c3-h1
angle_coeff 6 42.0      108.42  # 6  h1-c3-sh
angle_coeff 7 39.4      107.58  # 7  hc-c3-hc

dihedral_coeff 1 0.750     3  0     0.000 # 1  c3-c3-sh-hs
dihedral_coeff 2 1.400     3  0     0.000 # 2  h1-c3-c3-hc
dihedral_coeff 3 0.750     3  0     0.000 # 3  h1-c3-sh-hs
dihedral_coeff 4 1.400     3  0     0.000 # 4  hc-c3-c3-sh

EOF

pair_coeff_1_e_GAFF=0.1094		# c3
pair_coeff_1_s_GAFF=3.399669508423535   # c3

pair_coeff_2_e_GAFF=0.0157		# h1
pair_coeff_2_s_GAFF=2.471353044121301   # h1

pair_coeff_3_e_GAFF=0.0157		# hc
pair_coeff_3_s_GAFF=2.649532787749369   # hc

pair_coeff_4_e_GAFF=0.0157		# hs
pair_coeff_4_s_GAFF=1.069078461768407   # hs

pair_coeff_5_e_GAFF=0.2500		# sh
pair_coeff_5_s_GAFF=3.563594872561357   # sh

echo "pair_coeff 1 1 $(python3 gen.py.temp ${pair_coeff_1_e_GAFF}) $(python3 gen.py.temp ${pair_coeff_1_s_GAFF}) #c3" >>  ${parameter_file}.${i}
echo "pair_coeff 2 2 $(python3 gen.py.temp ${pair_coeff_2_e_GAFF}) $(python3 gen.py.temp ${pair_coeff_2_s_GAFF}) #h1" >>  ${parameter_file}.${i}
echo "pair_coeff 3 3 $(python3 gen.py.temp ${pair_coeff_3_e_GAFF}) $(python3 gen.py.temp ${pair_coeff_3_s_GAFF}) #hc" >>  ${parameter_file}.${i}
echo "pair_coeff 4 4 $(python3 gen.py.temp ${pair_coeff_4_e_GAFF}) $(python3 gen.py.temp ${pair_coeff_4_s_GAFF}) #hs" >>  ${parameter_file}.${i}
echo "pair_coeff 5 5 $(python3 gen.py.temp ${pair_coeff_5_e_GAFF}) $(python3 gen.py.temp ${pair_coeff_5_s_GAFF}) #sh" >>  ${parameter_file}.${i}

rm gen.py.temp


cat > in.npt_nve << EOF
units           real
atom_style      full
boundary        p p p
dielectric      1
#special_bonds   lj/coul 0.0 0.0 1.0 

read_data       ${lammps_data_file} 
include         ${parameter_file}.${i}

variable        Temp    equal   ${temperature}
variable        Press   equal   ${pressure}

#PAUSE# variable        run_length_nve_rescale  equal 10000000
#PAUSE# variable        run_length_nve          equal 2000000
variable        run_length_npt          equal 10000000
variable        run_length_nve          equal  2000000
#PAUSE# variable        run_length_nvt          equal 0
variable        dump_freq               equal 1000
variable        t_step                  equal 1 

pair_modify     mix arithmetic
neighbor        4.0 bin
neigh_modify    every 1 delay 0 check yes
thermo_style    multi

variable        input index in.graphene_flow_pure2.lammps
variable        sname index ethanethiol_${nMolecules}N_\${Temp}_\${Press}

print                          .
print ==========================================
print "Minimization"
print ==========================================
print                          .
thermo          10
min_style       sd
minimize        1.0e-4 1.0e-4 500 5000
min_style       cg
minimize        1.0e-4 1.0e-4 500 5000


reset_timestep  0
timestep        \${t_step}
thermo          \${dump_freq}
thermo_style    custom step pe ke etotal temp xlo xhi ylo yhi zlo zhi vol  density enthalpy


#PAUSE# log             log.nve_rescale
#PAUSE# print                          .
#PAUSE# print ==================================================
#PAUSE# print "NVE dynamics with Rescale"
#PAUSE# print ==================================================
#PAUSE# print                          .
#PAUSE# fix             8 all nve
#PAUSE# fix             7 all temp/rescale 1 \${Temp} \${Temp} 0.02 1.0
#PAUSE# run             \${run_length_nve_rescale}
#PAUSE# unfix           7
#PAUSE# unfix           8
#PAUSE# 
#PAUSE# log             log.nve
#PAUSE# print                          .
#PAUSE# print ==================================================
#PAUSE# print "NVE dynamics"
#PAUSE# print ==================================================
#PAUSE# print                          .
#PAUSE# fix             8 all nve
#PAUSE# run             \${run_length_nve}
#PAUSE# unfix           8


log             log.npt
print                          .
print ==================================================
print "NPT dynamics with an isotropic pressure"
print ==================================================
print                          .
fix             2 all npt temp \${Temp} \${Temp} 100.0 iso \${Press} \${Press} 1000.0
neigh_modify    every 1 delay 0 check no
restart         \${dump_freq} \${sname}_npt.restart1 \${sname}_npt.restart2
dump            1 all dcd \${dump_freq} \${sname}_npt.dcd
dump_modify     1 unwrap yes sort id
run             \${run_length_npt} 
undump          1
unfix           2

write_data      data.\${sname}_npt_equil

log             log.nve
print                          .
print ==================================================
print "NVE dynamics"
print ==================================================
print                          .
fix             8 all nve
dump            1 all dcd \${dump_freq} \${sname}_nve.dcd
dump_modify     1 unwrap yes sort id
run             \${run_length_nve}
undump          1
unfix           8

write_data      data.${sname}_nve_equil

#PAUSE# log             log.nvt
#PAUSE# print                          .
#PAUSE# print =================================================
#PAUSE# print "NVT Equilibriation"
#PAUSE# print =================================================
#PAUSE# print                          .
#PAUSE# fix             2 all nvt temp \${Temp} \${Temp} 100.0
#PAUSE# neigh_modify    every 1 delay 0 check no
#PAUSE# restart         \${dump_freq} \${sname}_nvt.restart1 \${sname}_nvt.restart2
#PAUSE# dump            1 all dcd \${dump_freq} \${sname}_nvt.dcd
#PAUSE# dump_modify     1 unwrap yes sort id
#PAUSE# run             \${run_length_nvt}
#PAUSE# undump          1
#PAUSE# unfix           2
#PAUSE# 
#PAUSE# write_data      data.\${sname}_nvt_equil

EOF

cd ../
done
