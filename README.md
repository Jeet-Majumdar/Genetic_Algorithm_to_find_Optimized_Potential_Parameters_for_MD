# Optimized_Potential_Parameters_for_MD_using_Genetic_Algorithm

An implementation of Genetic Algorithm to find optimized potential interaction parameters for and from MD simulations

The main bottleneck of the whole process is running many simulations for every population.
But if done, the scripts are to be run in the order as given in prefix.
`GA_main_outline.sh` contains the outline of the steps involved.

An example population `pop_1` is given for the perusal of the user.

The entire activity is partlially automatic and has to be done through the helper scripts as described below.

1. `GA_initial_population_builder.sh` for generation of initial population.
2. `GA_1_check_convergence_population.sh` checks the convergence of the finished MD simulations. Some simulations may not converge in density or energy within our simulation timescale. This may be due to random parameterizations. Such simulations should be discarded.
3. `GA_2_extract_properties_population.sh` can be used to extract the desirable properties from the simualtion outputs.
4. `GA_3_find_merit_population.sh` is used to find the merit of the simulations in a population. This file compares the desired simulation property from that of experiment. Here this is density for the target temperatures as given in line `16`.
5. `GA_4_create_new_population.sh` can be used to create a new population from an existing one with crossover and mutation.
6. `GA_5_reassign_rank.sh` can be used to rename run folders in a given population folder. It is of no use if you just rename the population folder to some other name.

Making it automatic was not feasible as it would require me to add another monitoring app which can track the completion of all the MD runs in a population.