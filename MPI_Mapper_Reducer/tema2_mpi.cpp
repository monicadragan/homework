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
//#include <conio.h>

using namespace std;

struct Frecvstruct
{
    int frecv;
    char word[50];
};

typedef std::pair<std::string, int> mypair;

struct IntCmp {
    bool operator()(const mypair &lhs, const mypair &rhs) {
        return lhs.second > rhs.second;
    }
};

int main( int argc, char *argv[] )
{
    int np = 1;
    int errcodes[np];
    MPI_Comm parentcomm, intercomm;

    MPI_Init( &argc, &argv );
    MPI_Comm_get_parent( &parentcomm );

        int rank, size;

        int mappers = 4;
        int reducers = 2;
	char filein [30], fileout [30];

	//citire fisier de configurare
	FILE *f;
	f = fopen("config.in","rb");
	if(f == NULL)
		printf("Fisierul de configurare nu a putut fi deschis.\n");
	else{
		fscanf(f,"%d %d %s %s",&mappers, &reducers, filein, fileout);	
	
		printf("Programul principal: \n");
		printf("\t %d mappers\n",mappers);
		printf("\t %d reducers\n",reducers);
		printf("\t %s filein\n",filein);

		FILE *f;
		f = fopen(filein,"rb");
		fseek( f, 0, SEEK_END );
		int size = ftell(f);

		printf("\t %s fileout\n",fileout);

		MPI_Comm_spawn( "./mapper", MPI_ARGV_NULL, mappers, MPI_INFO_NULL, 0, MPI_COMM_WORLD, &intercomm, errcodes);
		int chars_sent = 0;
		for(int i=0;i<mappers;i++){
			//trimit numele fisierului
			int len = strlen(filein);
			MPI_Send(&len, 1,  MPI_INT, i, 1, intercomm);
			MPI_Send(filein,len,MPI_CHAR,i,1, intercomm);
			//trimit nr de reducers
			MPI_Send(&reducers, 1,  MPI_INT, i, 1, intercomm);			
			//trimit offsetul
			int offset = (int)i*size/mappers;
			MPI_Send(&offset,1,MPI_INT,i,1, intercomm);
			if(i != mappers-1){
				int chunk = (int)size/mappers;
				chars_sent += chunk;
				MPI_Send(&chunk,1,MPI_INT,i,1, intercomm);
			}
			else{
				size -= chars_sent;
				MPI_Send(&size,1,MPI_INT,i,1, intercomm);
			}
		}


	        MPI_Status status;
        	MPI_Datatype Frecvtype;
      	 	MPI_Datatype type[2] = {MPI_INT, MPI_CHAR};
       		int blocklen[2] = {1, 50};
	        MPI_Aint disp[2];
	
	        disp[0] = 0;
	        disp[1] = 4;
	        MPI_Type_create_struct(2, blocklen, disp, type, &Frecvtype);
	        MPI_Type_commit(&Frecvtype);

	        //initializez hashmapul
                map<string,int>dictionar;
                map<string,int>::iterator it;

		for(int i=0;i<mappers;i++){
	                int len = -1;
        	        MPI_Recv(&len, 1, MPI_INT, i, MPI_ANY_TAG, intercomm, MPI_STATUS_IGNORE);
	                
			struct Frecvstruct frecvente[len];	
        	        MPI_Recv(&frecvente, len, Frecvtype, i, MPI_ANY_TAG, intercomm, MPI_STATUS_IGNORE);
	                for(int j=0;j<len;j++){

        	                string str(frecvente[j].word);
                	        it = dictionar.find(str);
				int frecv = frecvente[j].frecv;
                        	if(it != dictionar.end()){
					frecv+=dictionar[str];	
	                                dictionar.erase(str);
        	                        dictionar.insert(pair<string,int>(str,frecv));
                	        }
                        	else{
	                                dictionar.insert(pair<string,int>(str,frecv));
        	                }
                	}
		}
	
    		vector<mypair> myvec(dictionar.begin(), dictionar.end());
    		sort(myvec.begin(), myvec.end(), IntCmp());

		FILE *fout;
		fout = fopen(fileout,"wb");
                        
		for (int i = 0; i < myvec.size(); ++i) {
        		fprintf(fout,"%s\t %d\n ",myvec[i].first.c_str(), myvec[i].second);
    		}

                for (int i = 0; i < 15; ++i) {
                        printf("%s\t %d\n ",myvec[i].first.c_str(), myvec[i].second);
                }
		fclose(fout);

	}
	
    
    
    fflush(stdout);
    MPI_Finalize();
    return 0;
}
