#include "mpi.h"
#include <iostream>
#include <fstream>
#include <cctype>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <sstream>
#include <map>
#include <vector>
#include <algorithm>

using namespace std;



typedef std::pair<std::string, int> mypair;

struct IntCmp {
    bool operator()(const mypair &lhs, const mypair &rhs) {
        return lhs.second > rhs.second;
    }
};

string UpToLow(string str) {
    for (int i=0;i<strlen(str.c_str());i++)
    if (str[i] >= 0x41 && str[i] <= 0x5A)
    str[i] = str[i] + 0x20;
    return str;
}

struct Frecvstruct
{
    int frecv;
    char word[50];
};

using namespace std;

int main(int argc, char* argv[]){

        int rank, rc;
	MPI_Comm parentcomm, intercomm;
	MPI_File fh;

	MPI_Init (&argc, &argv);      
        MPI_Comm_rank (MPI_COMM_WORLD, &rank);

	int id_parent = MPI_Comm_get_parent(&parentcomm); 

	//primesc streamul

	int len = -1;
	MPI_Recv(&len, 1, MPI_INT, id_parent, MPI_ANY_TAG, parentcomm, MPI_STATUS_IGNORE);
	char* stream = (char*)malloc(len+1);
	if(len > 0){
		MPI_Recv(stream, len, MPI_CHAR, id_parent, MPI_ANY_TAG, parentcomm, MPI_STATUS_IGNORE);
		stream[len] = '\0';

 	       string separators("0123456789 [(),@=;%!?^$\\.-*#:'/\"\r\n\t");
               while(separators.find_first_of(stream[0]) != string::npos)
     	           stream++;
	
		char s[50], u[100];
        	map<string,int>dictionar;
	        map<string,int>::iterator it;
        	int read;
		int offset = 0;
        	while(read = sscanf(stream+offset,"%49[a-zA-Z]%100[0-9 [(),@=;%!?^$\\.-#:'/*\"\r\n\t]*",s,u)>0){

                	string str = string(UpToLow(s));
			//cout<<str<<endl;

	                it = dictionar.find(str);
        	        if(it != dictionar.end()){
                	        int frecv = dictionar[str];
                        	dictionar.erase(str);
	                        dictionar.insert(pair<string,int>(str,++frecv));
        	        }
                	else{
                        	int frecv = 1;
	                        dictionar.insert(pair<string,int>(str,frecv));
        	        }
                	offset += strlen(s) + strlen(u);
			//deoarece nu am putu pune ']' in expresia regulata
			if(*(stream+offset) == ']'){
				offset++;
				read = sscanf(stream+offset,"%100[0-9 [(),@=;%!?^$\\.-#:'/*\"\r\n\t]*",u);
				if(read > 0)
					offset+=strlen(u);
			}
			if(offset >= len)
				break;
			
	        }

		//initializez structura
    		struct Frecvstruct frecvente[dictionar.size()];
	    	MPI_Status status;
    		MPI_Datatype Frecvtype;
	    	MPI_Datatype type[2] = { MPI_INT, MPI_CHAR};
    		int blocklen[2] = { 1, 50};
	    	MPI_Aint disp[2];
		struct Frecvstruct f[0];
 
	    	disp[0] = 0;
    		disp[1] = 4;
	    	MPI_Type_create_struct(2, blocklen, disp, type, &Frecvtype);
	    	MPI_Type_commit(&Frecvtype);
    	
		//trimit raspunsul
		int i = -1;
		for ( it=dictionar.begin() ; it != dictionar.end(); it++ ){
			strcpy(frecvente[++i].word,(*it).first.c_str());	
			frecvente[i].frecv = (*it).second;
        	}

		len = dictionar.size();

		MPI_Send(&len, 1,  MPI_INT, id_parent, 1, parentcomm);
		MPI_Send(frecvente, len,  Frecvtype, id_parent, 1, parentcomm);
	}
	else{
		len = 0;	
		MPI_Send(&len, 1,  MPI_INT, id_parent, 1, parentcomm);
	}
	MPI_Finalize();
	return 0;
}
