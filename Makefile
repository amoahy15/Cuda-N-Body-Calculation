all: 
	gcc  -o serial  NBody.cpp  -lm
	nvcc -o parallel  NBody.cu
	gcc -o SpeedUp  SpeedUp.c

run: all
	./serial 10
	./parallel 10
	./SpeedUp c_exec_time.csv cu_exec_time.csv

clean:
	rm -f serial
	rm -f parallel
	rm -f SpeedUp
	rm -f c_exec_time.csv
	rm -f cu_exec_time.csv
	rm -f SpeedUp.csv
	rm -f serialNBody.pdb
	rm -f NBody.pdb
	
