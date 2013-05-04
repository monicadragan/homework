#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <libspe2.h>
#include <pthread.h>
#include <libmisc.h>

#include "graphics.h"

extern spe_program_handle_t simple_spu;

#define SPU_THREADS 8
#define min(a,b) a>b?b:a

typedef struct piesa{

	PPMPixel *offset;
	PPMPixel *offset_final;
	int pozitionat;//1 daca da, 0 daca nu
	int padding;

}piesa;

typedef struct ctx_struct{

        spe_context_ptr_t ctx;
        int id;

} ctx_struct;

typedef struct info_spu{

        PPMPixel *piesa_stanga;
        PPMPixel *piesa_sus;
        int offset; //offset din lista_piese_neprocesate
        int cnt; // cate piese sunt de procesat pt fiecare spu

}info_spu;

typedef struct info_ppu{

	PPMPixel *image;
	int lungime;
	int latime;
	int no_piese;
	int latime_piesa;
	piesa *lista_piese;
	int* piese_nepozitionate;
	int no_iteratii;

}info_ppu;

info_spu info[SPU_THREADS] __attribute__ ((aligned(128)));
info_ppu ppu __attribute__ ((aligned(128)));
PPMPixel *pixels;
piesa *lista_piese;
int *lista_piese_nepozitionate __attribute__ ((aligned(128)));//contine indexii din lista_piese al pieselor nepozitionate

int to_16(int x){

        int i;
        for(i=0;;i+=16){
                if(x<=i)
                        return i;
        }
}

int to_4(int x){

        int i;
        for(i=0;;i+=4){
                if(x<=i)
                        return i;
        }
}

void *ppu_pthread_function(void *arg) {
    //spe_context_ptr_t ctx;
    ctx_struct* ctx;
    unsigned int entry = SPE_DEFAULT_ENTRY;

    ctx = ((ctx_struct *)arg);
    if (spe_context_run(ctx->ctx, &entry, 0, ctx->id ,NULL, NULL) < 0) {
        perror ("Failed running context");
        return NULL;
    }    
    pthread_exit(NULL);
}


int main(int argc, char** argv){

    int i,j,k,spu_threads;

    spe_event_unit_t pevents[SPU_THREADS], event_received;
    spe_event_handler_ptr_t event_handler = spe_event_handler_create(); 

    //receive parameter info

    ctx_struct ctxs[SPU_THREADS];
    pthread_t threads[SPU_THREADS];

    // Determine the number of SPE threads to create.
    spu_threads = spe_cpu_info_get(SPE_COUNT_USABLE_SPES, -1);
    if (spu_threads > SPU_THREADS) spu_threads = SPU_THREADS;

    //parmetrii de run
    if(argc < 3){
	printf("Pay attention to parametres!\n");
	return 1;
    }

    char *fis_in = strdup(argv[1]);
    char *nume_out = strdup(argv[2]);
    int n = atoi(argv[3]);
    printf("%s %d\n",fis_in,n);
    char fis_out[30];
    sprintf(fis_out,"%s_out",fis_in);
    printf("nume: %s\n",fis_out);

    //citesc imaginea
    PPMImage *image_in = readPPM(fis_in);

    printf("size of piesa %d",sizeof(piesa));
    printf("%d %d\n",image_in->x, image_in->y);


    //fac lista de piese
    int no_piese = image_in->x * image_in->y / n / n;
    int no_piese_nepozitionate = no_piese - 1;
    printf("--- piese nepozitionate %d\n",no_piese_nepozitionate);

    lista_piese = malloc_align(no_piese * sizeof(piesa),7);
    lista_piese_nepozitionate = malloc_align(to_16(no_piese * sizeof(piesa)),7);
    int no_piese_x = image_in->x /n;
    int no_piese_y = image_in->y /n;
    printf("PPU: %d %d piese\n",no_piese_x, no_piese_y);

    no_piese = -1;
    for(i=0;i<no_piese_y;i++){
            for(j=0;j<no_piese_x;j++){
                lista_piese[++no_piese].offset = image_in->data + i * n * image_in->x + j * n;
                lista_piese[no_piese].pozitionat = 0;
            }
    }
    no_piese++;

    lista_piese[0].pozitionat = 1;
    lista_piese[0].offset_final = image_in->data;

    for(i=0;i<no_piese_nepozitionate;i++)
        lista_piese_nepozitionate[i] = i+1;

    // Create several SPE-threads to execute 'simple_spu'.        
    for(i=0; i<spu_threads; i++) {

        // Create context 
        if ((ctxs[i].ctx = spe_context_create (0, NULL)) == NULL) {
            perror ("Failed creating context");
            exit (1);
        }

	ctxs[i].id = i;
        // Load program into context 
        if (spe_program_load (ctxs[i].ctx, &simple_spu)) {
                perror ("Failed loading program");
                exit(1);
        }
        // Create thread for each SPE context 
        if (pthread_create (&threads[i], NULL, &ppu_pthread_function, &ctxs[i]))  {
            perror ("Failed creating thread");
            return 1;
        }

        //trimit adresa de inceput a listei de piese
        ppu.image = image_in->data;
	ppu.lungime = image_in->x;
	ppu.latime = image_in->y;
	ppu.no_piese = no_piese;
        //trimit latura unei piese
        ppu.latime_piesa = n;
	//trimit adresa de inceput a listei de piese
	ppu.lista_piese = lista_piese;
	//trimit adresa de inceput a listei de indecsi de piese nepozitionate
        ppu.piese_nepozitionate = lista_piese_nepozitionate;
	//trimit numarul de interogari care vor urma
        ppu.no_iteratii = no_piese_nepozitionate;
        unsigned int mdata = (unsigned int)(&ppu);
	spe_in_mbox_write(ctxs[i].ctx, &mdata, 1, SPE_MBOX_ALL_BLOCKING);

    }


    for(i=1;i<no_piese;i++){
	if(lista_piese[i].pozitionat == 0){
	    int piese_trimise = 0;
            //trimit indecsii din lista de piese a pieselor nepozitionate, repartizate pt toate SPUurile
            int cnt = to_4(no_piese_nepozitionate / spu_threads);
            for(j=0; j<spu_threads; j++) {
		//trimit adresa piesei din stanga daca exista			
		unsigned int mdata;
		
		if((i<no_piese_x) || (i % no_piese_x != 0)){
			info[j].piesa_stanga = lista_piese[i-1].offset_final;
		}else{	
			info[j].piesa_stanga = NULL;
		}
		//trimit adresa piesei de sus daca exista
		if(i >= no_piese_x){
			info[j].piesa_sus = lista_piese[i - no_piese_x].offset_final;
		}else{
			info[j].piesa_sus = NULL;
		}

		//trimit adresa relativa la inceputul vectorului
		if(piese_trimise < no_piese_nepozitionate){
			info[j].offset = j*cnt;
			if((j==(spu_threads - 1))){
 				info[j].cnt = no_piese_nepozitionate - piese_trimise;
			}
			else{
				info[j].cnt = cnt;
				piese_trimise += cnt;
			}
		}
		else 
			info[j].cnt = 0;
		printf("trimit %p %p\n", info[j].piesa_stanga, info[j].piesa_sus);
		mdata = (unsigned int) (&info[j]);
		spe_in_mbox_write(ctxs[j].ctx, &mdata, 1, SPE_MBOX_ALL_BLOCKING);
		
	    }	
	    int min = 100000;
	    unsigned int best;
	    for(j=0;j<spu_threads;j++){
		
		unsigned int best_partial,dif;
		while (spe_out_mbox_status(ctxs[j].ctx) == 0);
		spe_out_mbox_read(ctxs[j].ctx, &best_partial,1);
                while (spe_out_mbox_status(ctxs[j].ctx) == 0);
                spe_out_mbox_read(ctxs[j].ctx, &dif,1);
		//printf("*** %d %d %d \n",best,dif,min);
/*
		int nevents = spe_event_wait(event_handler,&event_received,1,-1);
		if(nevents<0){
			printf("SPU:Error la spe_event_wait(res=%d)\n",nevents);
		}
		else{
			if (event_received.events & SPE_EVENT_OUT_INTR_MBOX){
				while (spe_out_intr_mbox_status(event_received.spe) < 1);
				spe_out_intr_mbox_read(event_received.spe, &best_partial, 1, SPE_MBOX_ANY_NONBLOCKING);
			}
			else{
				printf("PPE:Caz nefericit avem alt exit status din SPU; spe=%d.\n",i);
			}
		}
		/*
		nevents = spe_event_wait(event_handler,&event_received,1,-1);
                if(nevents<0){
                        printf("SPU:Error la spe_event_wait(res=%d)\n",nevents);
                }
                else{
                        if (event_received.events & SPE_EVENT_OUT_INTR_MBOX){
                                while (spe_out_intr_mbox_status(event_received.spe) < 1);
                                spe_out_intr_mbox_read(event_received.spe, &dif, 1, SPE_MBOX_ANY_NONBLOCKING);
                        }
                        else{
                                printf("PPE:Caz nefericit avem alt exit status din SPU; spe=%d.\n",i);
                        }
                }*/
		//dif = 10;

		if(best_partial != -1 && dif != -1)
			if(min > dif){
				min = dif;
				best = best_partial;
			}
	    }
	    printf("best = %d\n",best);
	    lista_piese[i].offset_final = lista_piese[best].offset;
	    lista_piese[i].pozitionat = 1;
	    //elimin piesa din lista_piese nepozitionate
	    for(j=0;j<no_piese_nepozitionate;j++)
		if(lista_piese_nepozitionate[j] == best)
			for(k=j;k<no_piese_nepozitionate-1;k++)
				lista_piese_nepozitionate[k] = lista_piese_nepozitionate[k+1];
	    no_piese_nepozitionate --;
    	}
    }
    // Wait for SPU-thread to complete execution.  
    for (i=0; i<spu_threads; i++) {
        if (pthread_join (threads[i], NULL)) {
            perror("Failed pthread_join");
            return 1;
        }

        // Destroy context 
        if (spe_context_destroy (ctxs[i].ctx) != 0) {
            perror("Failed destroying context");
            return 1;
        }
    }

    //for(i=0;i<no_piese;i++)
    //	printf("%p %p\n",lista_piese[i].offset, lista_piese[i].offset_final);

    //reconstituire imagine
    PPMPixel *final_image = malloc_align(image_in->x * image_in->y * sizeof(PPMPixel),7);
    PPMImage image_out;
    image_out.x = image_in->x;
    image_out.y = image_in->y;

    for(k=0;k<no_piese;k++){

        PPMPixel *start_final = lista_piese[k].offset_final;
	PPMPixel *start = lista_piese[k].offset;
	for(i=0;i<n;i++){//pentru fiecare linie
		int offset = start - image_in->data;
		for(j=0;j<n;j++)
			final_image[(offset + j)] = start_final[j];
		start_final += image_in->x;
		start += image_in->x; 
        }

    }
    image_out.data = final_image;    
    writePPM(nume_out, &image_out);

    printf("\nThe program has successfully executed.\n");
    return 0;
}
