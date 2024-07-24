for fol in pop_1
do
cd $fol

for temp in 300
do	
	count=0
	for i in $(ls -d ${temp}.*)
	do
		t=$( ${i} | cut -d'.' -f 1)
		count=$(( $count + 1 ))
		mv ${i} ${t}.${count}. 
	done


done
cd ../
done
