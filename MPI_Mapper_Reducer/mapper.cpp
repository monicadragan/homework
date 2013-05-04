#include "mpi.h"
#include <iostream>
#include <fstream>
#include <cctype>
#include <stdio.h>
#include <string.h>
#include <string>
#include <sstream>
#include <map>
#include <vector>
#include <algorithm>
#include <stdlib.h>


using namespace std;

struct Frecvstruct
{
    int frecv;
    char word[50];
};
   

int main(int argc, char* argv[]){

        int rank, rc, nprocs;
	MPI_Comm parentcomm, intercomm;
	MPI_File fh;

	MPI_Init (&argc, &argv);   
        MPI_Comm_rank (MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD,&nprocs); 

	char filename[30];

	int id_parent = MPI_Comm_get_parent(&parentcomm); 

	//primesc numele fisierului
	int len = -1;
	MPI_Recv(&len, 1, MPI_INT, id_parent, MPI_ANY_TAG, parentcomm, MPI_STATUS_IGNORE);
	MPI_Recv(filename, len, MPI_CHAR, id_parent, MPI_ANY_TAG, parentcomm, MPI_STATUS_IGNORE);
	filename[len] = '\0';
        //primesc numar de reducers
        int reducers = 0;
        MPI_Recv(&reducers, 1, MPI_INT, id_parent, MPI_ANY_TAG, parentcomm, MPI_STATUS_IGNORE);
	int errcodes[reducers];
	//primesc offset
	int offset = 0;
	MPI_Recv(&offset, 1, MPI_INT, id_parent, MPI_ANY_TAG, parentcomm, MPI_STATUS_IGNORE);
	//primesc lungimea sceventei
        int size = 0;
        MPI_Recv(&size, 1, MPI_INT, id_parent, MPI_ANY_TAG, parentcomm, MPI_STATUS_IGNORE);
	char* stream = (char*)malloc(size+10);
	//deschid fisierul si creez un view pt citire
	rc = MPI_File_open( MPI_COMM_WORLD, filename, MPI_MODE_RDONLY, MPI_INFO_NULL, &fh );
        if(rc!=MPI_SUCCESS)
                printf("Mapper %d: Insucces la file open\n",rank);

	rc = MPI_File_seek( fh, offset, MPI_SEEK_SET );
	if(rc!=MPI_SUCCESS)
		printf("Mapper %d: Insucces la seek\n",rank);

	int relaxed_size = size;
	if(rank != nprocs-1)
		relaxed_size+=10;
	rc = MPI_File_read( fh, stream, relaxed_size, MPI_CHAR, MPI_STATUS_IGNORE);
	MPI_File_close(&fh);

	//ma pozitionez corect (la inceput de cuvant)
	string separators("0123456789 [](),@=;%!?^$\\.-#:'*/\"\r\n\t");
	while(separators.find_first_of(stream[0]) != string::npos){
		stream++;
	}
	//ma pozitionez corect la sfarsit de cuvant
	if(rank!= nprocs-1){
        	while(separators.find_first_of(stream[size]) == string::npos){
			size++;
		}
	}

	stream[size] = '\0';

        MPI_Comm_spawn( "./reducer", MPI_ARGV_NULL, reducers, MPI_INFO_NULL, 0, MPI_COMM_SELF, &intercomm, errcodes);

        int chars_sent = 0;
        for(int i=0;i<reducers;i++){
        
                if(i != reducers-1){

			//trimit lungimea stringului
			int chunk = (int)size/reducers;
			char* adresa_inceput = stream;
			stream = stream + chunk;
			//ajustez finalul stringului 
        		while(separators.find_first_of(*stream) == string::npos){
		                stream++;
                		chunk++;
		        }
			
                	chars_sent += chunk;
			//trimit lungimea streamului
                	MPI_Send(&chunk,1,MPI_INT,i,1, intercomm);
			//trimit stringul
			MPI_Send(adresa_inceput, chunk,  MPI_CHAR, i, 1, intercomm);
		}
		else{
			size-=chars_sent;
			if(size < 0){
				size = 0;
				MPI_Send(&size,1,MPI_INT,i,1, intercomm);
			}
			else{
				MPI_Send(&size,1,MPI_INT,i,1, intercomm);
				MPI_Send(stream, size,  MPI_CHAR, i, 1, intercomm);
			}
		}
	}
	
	//primesc raspunsul cu frecventele
        MPI_Status status;
	MPI_Datatype Frecvtype;
	MPI_Datatype type[2] = { MPI_INT, MPI_CHAR};
        int blocklen[2] = { 1, 50};
	MPI_Aint disp[2];

        disp[0] = 0;
	disp[1] = 4;
	MPI_Type_create_struct(2, blocklen, disp, type, &Frecvtype);
	MPI_Type_commit(&Frecvtype);	

	//initializez hashmapul
	map<string,int>dictionar;
	map<string,int>::iterator it;

	for(int i=0;i<reducers;i++){
		len = -1;
		MPI_Recv(&len, 1, MPI_INT, i, MPI_ANY_TAG, intercomm, MPI_STATUS_IGNORE);		
		if(len > 0){
			struct Frecvstruct frecvente[len];
			MPI_Recv(&frecvente, len, Frecvtype, i, MPI_ANY_TAG, intercomm, MPI_STATUS_IGNORE);

			//adaug in dictionar
			for(int j=0;j<len;j++){
				string str(frecvente[j].word);
				it = dictionar.find(str);
				int frecv = frecvente[j].frecv;
			
				if(it != dictionar.end()){
					frecv += dictionar[str];
					dictionar.erase(str);
					dictionar.insert(pair<string,int>(str,frecv));
				}
				else{
					dictionar.insert(pair<string,int>(str,frecv));
				}
			}				
		}
	}

	len = dictionar.size();
	struct Frecvstruct frecvente[len];
        int i = -1;
        for ( it=dictionar.begin() ; it != dictionar.end(); it++ ){
                strcpy(frecvente[++i].word,(*it).first.c_str());
                frecvente[i].frecv = (*it).second;
        }

        MPI_Send(&len, 1,  MPI_INT, id_parent, 1, parentcomm);
        MPI_Send(frecvente, len,  Frecvtype, id_parent, 1, parentcomm);
	
	MPI_Finalize();
	return 0;
}
