/**********************************/
/**** Dragan Monica, Tema 2 ML ****/
/**********************************/

#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <string.h>

using namespace std;

#define ITER      10000
#define LEARNRATE 0.7
#define EPS		  0.15
#define MIN_ERR	  0.01
#define DEBUG 	  0
#define N		  50

// Function declaratation
float Train(float*, float*);
float  Run(float*, float*);
float Sigmoid(float num);
void print_weights();
void read_input(char*);

// The neural network variables (the neurons and the weights)
int levels_hidden = 1;
int nodes_hidden = 10;
int len_input = 13;
int len_output = 1;
int no_training;
int no_tests;

float** training_data;
float** test_data;
float** training_target;
float** test_target;
float** w_input_hidden;
float*** w_hidden;
float** w_hidden_output;

float** hidden_bias;
float* output_bias;

void read_input(char* filename){

	ifstream fin ("BodyFat.csv");

    int i, j, k=-1;
    float val;
    float min[len_input];
    float max[len_input];    
    float min_output[len_output];
    float max_output[len_output];     
    char c;
    string header;
    
    no_training = 160;
    no_tests = -1;
    
    for(i=0;i<len_input;i++){
    	min[i] = 100000;
    	max[i] = 0;
    }
    
    for(i=0;i<len_output;i++){
    	min_output[i] = 100000;
    	max_output[i] = 0;
    }

	training_data = (float **)malloc(300 * sizeof(float *));
	training_target = (float **)malloc(300 * sizeof(float *));	
	
	test_data = (float **)malloc(300 * sizeof(float *));
	test_target = (float **)malloc(300 * sizeof(float *));	

    getline (fin,header);
	int cnt = 0;
    //citire
    while (!fin.eof()){

		if (!fin) 
			break;

		if(k < no_training ){
			training_data[++k] = (float *)malloc((len_input+1) * sizeof(float));
   			training_target[k] = (float *)malloc((len_output+1) * sizeof(float));
	    	//read inputs
    		for(i=0; i<len_input; i++){    		
    			fin>>val;
    			fin>>c;
    			training_data[k][i] = val;
    			if(min[i] > val)
    				min[i] = val;
    			if(max[i] < val)
    				max[i] = val;
    		}
    		//read outputs
    		for(i=0;i<len_output-1; i++){
    			fin>>val;
    			fin>>c;
    			training_target[k][i] = val; 
    			if(min_output[i] > val)
    				min_output[i] = val;
    			if(max_output[i] < val)
    				max_output[i] = val;    						
    		}
    		fin>>val;
    		training_target[k][len_output-1] = val;
   			if(min_output[len_output-1] > val)
   				min_output[len_output-1] = val;
   			if(max_output[len_output-1] < val)
   				max_output[len_output-1] = val;     		
    	}

    	else{
			test_data[++no_tests] = (float *)malloc((len_input+1) * sizeof(float));
   			test_target[no_tests] = (float *)malloc((len_output+1) * sizeof(float));
   			//read inputs    
    		for(i=0; i<len_input; i++){    		
    			fin>>val;
    			fin>>c;
    			test_data[no_tests][i] = val;
    			if(min[i] > val)
    				min[i] = val;
    			if(max[i] < val)
    				max[i] = val;       			
    		}
    		//read outputs
    		for(i=0;i<len_output-1; i++){
    			fin>>val;
    			fin>>c;
    			test_target[no_tests][i] = val;
    			if(min_output[i] > val)
    				min_output[i] = val;
    			if(max_output[i] < val)
    				max_output[i] = val;      			
    		}   				
    		fin>>val;
    		test_target[no_tests][len_output-1] = val;
   			if(min_output[len_output-1] > val)
   				min_output[len_output-1] = val;
   			if(max_output[len_output-1] < val)
   				max_output[len_output-1] = val;    		
    	}   
    }
    
    fin.close();
    
    for(i=0;i<no_training;i++)
    	for(j=0;j<len_input;j++)
	    	training_data[i][j] = (float)(training_data[i][j] - min[j])/(max[j]-min[j]);
    	
    for(i=0;i<no_training;i++)
    	for(j=0;j<len_output;j++)
	    	training_target[i][j] = (float)(training_target[i][j] - min_output[j])/(max_output[j]-min_output[j]);
	    	
    for(i=0;i<no_tests;i++)
    	for(j=0;j<len_input;j++)
	    	test_data[i][j] = (float)(test_data[i][j] - min[j])/(max[j]-min[j]);    	   	
	    	
    for(i=0;i<no_tests;i++)
    	for(j=0;j<len_output;j++)
	    	test_target[i][j] = (float)(test_target[i][j] - min_output[j])/(max_output[j]-min_output[j]);	    
	    
	if(DEBUG){    	
		for(i=0;i<no_training;i++){
			for(j=0;j<len_input;j++){
				cout<<training_data[i][j]<<" ";
			}
			cout<<training_target[i][0]<<endl;
		}
	}
}

ofstream fout;	
int main(int argc, char *argv[]) {

	int i,j,k;
	float total_err = 0;
	srand((unsigned)time(NULL));
	float INIT = (float)(1- ((float) rand() / (RAND_MAX/2)))/10;
	
	float errors[N];//buffer circular
	
	char* output_filename = strdup("Results.csv");
	
	if(argc == 4){
		nodes_hidden = atoi(argv[1]);
		levels_hidden = atoi(argv[2]);
		output_filename = strdup(argv[3]);
	}	
	
	cout<<levels_hidden<<" nivele cu "<<nodes_hidden<<" noduri fiecare"<<endl;

	fout.open(output_filename);	
	read_input(NULL);

	//alocare matrici	
	
	w_input_hidden = (float **)malloc((len_input+1) * sizeof(float *));
	for(i=0; i<len_input; i++){
		w_input_hidden[i] = (float *)malloc((nodes_hidden+1) * sizeof(float));
		for(j=0; j<nodes_hidden; j++)
			w_input_hidden[i][j] = INIT;
	}
		
	w_hidden = (float ***)malloc((levels_hidden+1) * sizeof(float **));
	hidden_bias = (float **)malloc((levels_hidden+1) * sizeof(float *));
	for(i=0; i<levels_hidden; i++){
		w_hidden[i] = (float **)malloc((nodes_hidden+1) * sizeof(float));
		hidden_bias[i] = (float *)malloc((nodes_hidden+1) * sizeof(float));	
		for(j=0; j<nodes_hidden; j++){
			w_hidden[i][j] = (float *)malloc((nodes_hidden+1) * sizeof(float));	
			hidden_bias[i][j] = INIT;
		}	
		for(j=0; j<nodes_hidden; j++){
			for(k=0; k<nodes_hidden; k++){
				w_hidden[i][j][k] = INIT;
			}
		}
	}
		
	w_hidden_output = (float **)malloc((nodes_hidden+1) * sizeof(float *));
	for(i=0; i<nodes_hidden; i++){
		w_hidden_output[i] = (float *)malloc((len_output+1) * sizeof(float));
		for(j=0; j<len_output; j++)			
			w_hidden_output[i][j] = INIT;
	}
	
	output_bias = (float *)malloc(len_output * sizeof(float));			

    // Train
    for(i=0; i<ITER; i++){
    	total_err = 0;
  		for(j=0;j<no_training;j++)
  			total_err += Train(training_data[j], training_target[j]);  		
  		if(DEBUG)
	  		cout<<"epoque "<<i<<", "<<"err = "<<total_err/no_training<<endl;
  		
  		if(total_err < MIN_ERR)
  			break;
  		
  		//daca eroarea stagneaza in ultimele N iteratii
  		errors[i%N]	= total_err;
  		float first = errors[0];
  		bool stop = true;
  		if (i >= N){
  			for(j=1;j<N;j++){
  				if(first != errors[j]){
  					stop = false;
  					break;
  				}
  			}	
  			if(stop == true)
  				break;
  		}	  		
    }
    
    cout<<"Numar total de iteratii: "<<i<<endl;
    cout<<"Eroarea de antrenare = "<<total_err/no_training<<endl;
    
	//print_weights();

       
    // Show results
    int cnt = 0;
	for(j=0;j<no_training;j++){
  		float err = Run(training_data[j], training_target[j]);    
  		if(err < EPS)
  			cnt++;
  	}
  	cout<<"Nr teste care au trecut: "<<cnt<<" din "<<no_training<<endl;
  	
	cnt = 0;
	for(j=0;j<no_tests;j++){
  		float err = Run(test_data[j], test_target[j]);    
  		if(err < EPS)
  			cnt++;
  	}
  	
  	cout<<"Nr teste care au trecut: "<<cnt<<" din "<<no_tests<<endl;  	
    fout.close();
    
	cout<<endl;

    cout<<"---------------------\n";     
    
    return 0;
}


float Train(float *input, float *target){
    
    int i, j, k;
    float err = 0;
    float o_hidden[levels_hidden][nodes_hidden];
	float o_hidden_err[levels_hidden][nodes_hidden];	
	float o_output[len_output];
	float o_output_err[len_output];
	
//////////////////////////////////////////////////////////
////////////////////////FORWARD///////////////////////////	
//////////////////////////////////////////////////////////
	
//INPUT -> HIDDEN

	for (i=0; i<nodes_hidden; i++){
		o_hidden[0][i] = 0;
		for (j=0; j<len_input; j++){
			o_hidden[0][i] += input[j] * w_input_hidden[j][i];			
		}
		o_hidden[0][i] += hidden_bias[0][i];
		o_hidden[0][i] = Sigmoid(o_hidden[0][i]);
	}
	
	if(DEBUG){
		for (i=0; i<nodes_hidden; i++){
				cout<<o_hidden[0][i]<<" ";
			}
		cout<<endl;
	}
	
	//completez outputurile dintre straturile ascunse
	if(levels_hidden > 1){
		for(k=1; k<levels_hidden; k++){
			for(i=0; i<nodes_hidden; i++){
				o_hidden[k][i] = 0;
				for(j=0; j<nodes_hidden; j++){
					o_hidden[k][i] += o_hidden[k-1][j] * w_hidden[k-1][j][i];							
				}
				o_hidden[k][i] += hidden_bias[k][i];
				o_hidden[k][i] = Sigmoid(o_hidden[k][i]);
			}
		}
	}
	
//HIDDEN -> OUTPUT

	for (i=0; i<len_output; i++){
		o_output[i] = 0;
		for (j=0; j<nodes_hidden; j++){
			o_output[i] += o_hidden[levels_hidden-1][j] * w_hidden_output[j][i];
		}
		o_output[i] += output_bias[i];			
		o_output[i] = Sigmoid(o_output[i]);
	}
	
	for (i=0; i<len_output; i++)
		err += (o_output[i] - target[i])*(o_output[i] - target[i]);
	err = sqrt(err);

	if(DEBUG){
		for (i=0; i<len_output; i++){
			cout<<o_output[i]<<" ";
		}
		cout<<endl;	
	}
	
//////////////////////////////////////////////////////////
///////////////////ERROR BACKPROPAGATION//////////////////
//////////////////////////////////////////////////////////

//Calculul erorii

//EROARE OUTPUT
 
    for (i=0; i<len_output; i++){
    	o_output_err[i] = o_output[i] * (1 - o_output[i]) * (target[i] - o_output[i]);
    }
    
    if(DEBUG){
    	cout<<"adjustments\n";
		for (i=0; i<len_output; i++){
				cout<<o_output_err[i]<<" ";
			}
		cout<<endl;  
	}

//EROARE HIDDEN LAYERS 

//ultimul layer ascuns
	for (j=0; j<nodes_hidden; j++){
		o_hidden_err[levels_hidden-1][j] = 0;
		for (i=0; i<len_output; i++){
			o_hidden_err[levels_hidden-1][j] += o_output_err[i] * w_hidden_output[j][i];
		}
		o_hidden_err[levels_hidden-1][j] *= o_hidden[levels_hidden-1][j] * (1 - o_hidden[levels_hidden-1][j]);
	}
	
//parcurg layerele in sens invers
	
	if(levels_hidden > 1){
		for (k=levels_hidden-2; k>=0; k--){
			for (j=0; j<nodes_hidden; j++){
				o_hidden_err[k][j] = 0;
				for (i=0; i<nodes_hidden; i++){
					o_hidden_err[k][j] += o_hidden_err[k+1][i] * w_hidden[k][j][i];
				}
				o_hidden_err[k][j] *= o_hidden[k][j] * (1 - o_hidden[k][j]);
			}
		}	
	}	
 
	if(DEBUG){
		for (i=0; i<nodes_hidden; i++){
				cout<<o_hidden_err[0][i]<<" ";
			}
		cout<<endl;	
	}
	
//Ajustare ponderile 
 
    for (j=0; j<len_input; j++){
		for (i=0; i<nodes_hidden; i++){
			w_input_hidden[j][i] += LEARNRATE * o_hidden_err[0][i] * input[j];
		}
	}
	
	if(levels_hidden > 1){
		for (k=0; k<levels_hidden-1; k++){
			for (j=0; j<nodes_hidden; j++){
				for (i=0; i<nodes_hidden; i++){
					w_hidden[k][i][j] += LEARNRATE * o_hidden_err[k+1][j] * o_hidden[k][j];
				}
			}
		}
	}
	

	for (i=0; i<nodes_hidden; i++){
		for (j=0; j<len_output; j++){
			w_hidden_output[i][j] += LEARNRATE * o_output_err[j] * o_hidden[levels_hidden-1][j];
		}
	}
	
//Ajustez bias

	for (k=0; k<levels_hidden; k++){
		for (i=0; i<nodes_hidden; i++){
			hidden_bias[k][i] += LEARNRATE * o_hidden_err[k][i];					
		}
	}
	
	for (i=0; i<len_output; i++){
		output_bias[i] += LEARNRATE * o_output_err[i];
	} 

	if(DEBUG){
		print_weights();
		cout<<endl<<endl;
	}
 	
 	return err;
}

 
float Run(float *input, float *target){
    
    int i,j,k;
	float err = 0;    
    
    float o_hidden[levels_hidden][nodes_hidden];
	float output[len_output];    

	for (i=0; i<nodes_hidden; i++){
		o_hidden[0][i] = 0;
		for (j=0; j<len_input; j++){
			o_hidden[0][i] = o_hidden[0][i] + (float)input[j] * w_input_hidden[j][i];			
		}
		o_hidden[0][i] += hidden_bias[0][i];
		o_hidden[0][i] = Sigmoid(o_hidden[0][i]);
	}
	
	if(DEBUG){
		cout<<"output hidden: \n";
		for (j=0; j<nodes_hidden; j++)	
			for(i=0;i<len_output;i++)
				cout<<o_hidden[j][i]<<" ";
		cout<<endl;	
	}

	//completez outputurile dintre straturile ascunse
	if(levels_hidden > 1){
		for(k=1; k<levels_hidden; k++){
			for(i=0; i<nodes_hidden; i++){
				o_hidden[k][i] = 0;
				for(j=0; j<nodes_hidden; j++){
					o_hidden[k][i] += o_hidden[k-1][j] * w_hidden[k-1][j][i];							
				}
				o_hidden[k][i] += hidden_bias[k][i];
				o_hidden[k][i] = Sigmoid(o_hidden[k][i]);
			}
		}
	}
	
	//completez matricea o_output
	for (i=0; i<len_output; i++){
		output[i] = 0;
		for (j=0; j<nodes_hidden; j++){
			output[i] = output[i] + o_hidden[levels_hidden-1][j] * w_hidden_output[j][i];
		}
		output[i] = output[i] + output_bias[i];			
		output[i] = Sigmoid(output[i]);
	}
	
	
	for (i=0; i<len_output; i++)
		err += (output[i] - target[i])*(output[i] - target[i]);
	err = sqrt(err);
	
	fout<<output[0]<<" "<<target[0]<<" "<<err<<endl;

	return err;
}


float Sigmoid(float num) {
    return (float)(1/(1+exp(-num)));
}


void print_weights(){

	int i,j;
	cout<<endl;
    cout<<"w_input_hidden"<<":"<<endl;
    for (j=0; j<len_input; j++){
		for (i=0; i<nodes_hidden; i++){
			cout<<w_input_hidden[j][i]<<" ";
		}
		cout<<endl;
	}
	cout<<endl;
    cout<<"w_hidden_output"<<":"<<endl;	
    for (j=0; j<nodes_hidden; j++){
		for (i=0; i<len_output; i++){
			cout<<w_hidden_output[j][i]<<" ";
		}
		cout<<endl;
	}	
    cout<<"bias hidden"<<":"<<endl;
    for (j=0; j<levels_hidden; j++){
		for (i=0; i<nodes_hidden; i++){
			cout<<hidden_bias[j][i]<<" ";
		}
		cout<<endl;
	}	
	
    cout<<"bias output"<<":"<<endl;
	for (i=0; i<len_output; i++){
		cout<<output_bias[i]<<" ";
	}
	cout<<endl;

}

