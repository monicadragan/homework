MCC = mpic++ 
NP  = 1
 
all: tema2
 
tema2: tema2_exec
	time mpirun -np $(NP) ./tema2

tema2_exec: mapper.cpp tema2_mpi.cpp
	$(MCC) mapper.cpp -o mapper
	$(MCC) reducer.cpp -o reducer
	$(MCC) tema2_mpi.cpp -o tema2
                                     
clean: 
	rm -f mappers tema2
