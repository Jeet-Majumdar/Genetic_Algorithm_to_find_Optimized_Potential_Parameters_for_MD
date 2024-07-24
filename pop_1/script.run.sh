for i in 30011 30012 
do
cd $i

echo "Waiting for 3.5h ..."

sleep 3.5h 

qsub run_lammps_tue
echo "$i Job submitted!"


cd ../

done


