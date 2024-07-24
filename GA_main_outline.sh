############################################

# CAPTION:: COMPARISON PARAMETERS


############################################

# CAPTION:: Generic Input Script for Lammps Runs

lammps_data_file="data.ethanethiol"
parameter_file="para.ethanethiol"
temperature=300
pressure=1.0
nMolecules=250

cat > in.lammps << EOF
units           real
atom_style      full
boundary        p p p
dielectric      1
#special_bonds   lj/coul 0.0 0.0 1.0 

pair_style      lj/charmm/coul/long  9.0 10.5
bond_style      harmonic
angle_style     harmonic
dihedral_style  charmm
improper_style  none
kspace_style    pppm 0.0001

read_data       ${lammps_data_file} 
include         ${parameter_file}

variable        Temp    equal   ${temperature}
variable        Press   equal   ${pressure}

variable        run_length_nve_rescale  equal 10000000
variable        run_length_nve          equal 2000000
variable        run_length_npt          equal 20000000
variable        run_length_nvt          equal 0
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
thermo_style    thermo_style    custom step pe ke etotal temp xlo xhi ylo yhi zlo zhi vol  density enthalpy


log             log.nve_rescale
print                          .
print ==================================================
print "NVE dynamics with Rescale"
print ==================================================
print                          .
fix             8 all nve
fix             7 all temp/rescale 1 \${Temp} \${Temp} 0.02 1.0
run             \${run_length_nve_rescale}
unfix           7
unfix           8

log             log.nve
print                          .
print ==================================================
print "NVE dynamics"
print ==================================================
print                          .
fix             8 all nve
run             \${run_length_nve}
unfix           8



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

log             log.nvt
print                          .
print =================================================
print "NVT Equilibriation"
print =================================================
print                          .
fix             2 all nvt temp \${Temp} \${Temp} 100.0
neigh_modify    every 1 delay 0 check no
restart         \${dump_freq} \${sname}_nvt.restart1 \${sname}_nvt.restart2
dump            1 all dcd \${dump_freq} \${sname}_nvt.dcd
dump_modify     1 unwrap yes sort id
run             \${run_length_nvt}
undump          1
unfix           2

write_data      data.\${sname}_nvt_equil

EOF

############################################

# CAPTION:: Check System energy convergence of single run

log_file_convergence="log.nve2"
check_convergence_python="check_convergence.py"
flag=$( python3 ${log_file_convergence}  )

if [ $flag == 1]
then
	echo "Simulation Converged.\nGoing to next step."
	## Add Next Step
else
	echo "Simulation did not converge! :( "
	echo "Run simulation again with different settings"
	## Add GOTO Line

fi

############################################

# CAPTION:: Check System energy convergence of ALL runs

if [ "Some Did not Converge"  ]
then
	echo "Run the ones that did not converge Again."
else
	echo "Proceed to Analysing Model Output"

############################################

# CAPTION:: Model output

# Extract density 
# ----------------


############################################

# 1. CAPTION:: Order outputs according to merit

############################################

# 2. CAPTION:: Select the first two best output

############################################

# 3. CAPTION:: Select random pairs from the others till desired population number is reached

############################################

# 4. CAPTION:: Do Cross-overs

############################################

# 5. CAPTION:: Do Mutation 

############################################

# 6. CAPTION:: Go to Step 1. unless highest merit is reached

############################################



