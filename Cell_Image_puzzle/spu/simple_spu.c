#include <stdio.h>
#include <time.h>
#include <spu_mfcio.h>
#include <libmisc.h>
#include <unistd.h>
#include <stdlib.h>
#include <spu_intrinsics.h>
#include <math.h>

#include "graphics.h"

#define waitag(t) mfc_write_tag_mask(1<<t); mfc_read_tag_status_all();

typedef struct piesa{

        PPMPixel *offset;
        PPMPixel *offset_final;
        int pozitionat;//1 daca da, 0 daca nu
        int padding;

}piesa;

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


PPMPixel *piesa_sus;
PPMPixel *piesa_stanga;
PPMPixel *piesa_comparat_stanga, *piesa_comparat_sus;
PPMPixel *image;
piesa *lista_piese;
int* piese_nepozitionate __attribute__ ((aligned(128)));

volatile info_spu info __attribute__ ((aligned(128)));
volatile info_ppu ppu __attribute__ ((aligned(128)));

int manhattan(); // face distanta intre cele 3 petice
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


int main( unsigned long long id, unsigned long long argc){

    int i,j,k,m;
    uint32_t tag_id;

    printf("@@@@@@: Hello World %llx!\n",argc);

    info_ppu* pppu = (info_ppu*)spu_read_in_mbox();

    //iau datele din structura
    tag_id = mfc_tag_reserve();
        if (tag_id==MFC_TAG_INVALID){
            printf("SPU: ERROR can't allocate tag ID\n"); return -1;
        }
    mfc_get((void *)(&ppu), (unsigned int)pppu, sizeof(info_ppu), tag_id, 0, 0);
    waitag(tag_id);

    printf("SPU*: %p %d %p %p %d \n",ppu.image,ppu.no_piese,ppu.lista_piese,ppu.piese_nepozitionate,ppu.no_iteratii);
    printf("SPU**: %d %d %d \n",ppu.lungime, ppu.latime, ppu.latime_piesa);
	
    piesa_sus = malloc_align(ppu.latime_piesa * sizeof(PPMPixel), 7); // iau doar ultima linie
    if(piesa_sus == NULL){
	perror("Nu mai e memorie");
	exit(1);
    }
    piesa_stanga = malloc_align(ppu.latime_piesa * sizeof(PPMPixel), 7); // iau doar ultima coloana
    if(piesa_stanga == NULL){
        perror("Nu mai e memorie");
	exit(1);
    }
    piesa_comparat_stanga = malloc_align(ppu.latime_piesa * sizeof(PPMPixel), 7);
    if(piesa_comparat_stanga == NULL){
        perror("Nu mai e memorie");
	exit(1);
    }

    piesa_comparat_sus = malloc_align(ppu.latime_piesa * sizeof(PPMPixel), 7);
    if(piesa_comparat_sus == NULL){
        perror("Nu mai e memorie");
        exit(1);
    }
    lista_piese = malloc_align(ppu.no_piese * sizeof(piesa),7);


    printf("aici1\n");
    //iau lista de piese
    tag_id = mfc_tag_reserve();
    if (tag_id==MFC_TAG_INVALID){
            printf("SPU: ERROR can't allocate tag ID\n");
            return 1;
    }
    printf("!! %p %p \n",lista_piese, ppu.lista_piese);
    mfc_get((void *)(lista_piese), (unsigned int)ppu.lista_piese, ppu.no_piese * sizeof(piesa), tag_id, 0, 0);
    waitag(tag_id);
    mfc_tag_release(tag_id);
 
    for(i=0;i<ppu.no_piese;i++)
        printf("%p ",lista_piese[i].offset);
    printf("\n");


    for(i=0;i<ppu.no_iteratii;i++){
    	info_spu* pinfo = (info_spu*)spu_read_in_mbox();
	printf("SPU' %llx: %p\n",argc,pinfo);
	//iau datele din structura
    	tag_id = mfc_tag_reserve();
	if (tag_id==MFC_TAG_INVALID){
		printf("SPU: ERROR can't allocate tag ID\n"); 
		return -1;
	}
	mfc_tag_release(tag_id);
	mfc_get((void *)(&info), (unsigned int)pinfo, sizeof(info_spu), tag_id, 0, 0);
	waitag(tag_id);	  
	printf("SPU'' %llx: %p %p %d %d \n",argc,info.piesa_stanga, info.piesa_sus, info.offset, info.cnt);
	if(info.cnt > 0){
		//iau indexii peticelor pe care le am de evaluat
	        int indecsi[to_4(info.cnt)]  __attribute__ ((aligned(128)));
		tag_id = mfc_tag_reserve();
	        if (tag_id==MFC_TAG_INVALID){
	                printf("SPU: ERROR can't allocate tag ID\n"); return -1;
        	}
		printf("ana are mere\n");
	        mfc_get((void *)(&indecsi[0]), (unsigned int)(ppu.piese_nepozitionate + info.offset), to_16(info.cnt*sizeof(int)), tag_id, 0, 0);
	        waitag(tag_id);
		mfc_tag_release(tag_id);
	
		//iau peticele de referinta
		if(info.piesa_stanga != NULL){

			PPMPixel *start = info.piesa_stanga + ppu.latime_piesa - 1;
			for(j=0;j<ppu.latime_piesa;j++){//pentru fiecare linie
				//iau cate o liniie
				tag_id = mfc_tag_reserve();
				if (tag_id==MFC_TAG_INVALID){
				    printf("SPU: ERROR can't allocate tag ID\n"); 
				    return -1;
				}
				mfc_get((void*)(&piesa_stanga[j]), (unsigned int)start, sizeof(PPMPixel), tag_id, 0, 0);

				waitag(tag_id);
			        mfc_tag_release(tag_id);
				start += ppu.lungime;
			}
        /*        if(info.piesa_stanga == (PPMPixel*)0xf7d68580){
                                printf("~ ");
                                for(k=0; k < 80; k++){
                                        printf("%d %d %d ",piesa_stanga[k].red, piesa_stanga[k].green, piesa_stanga[k].blue);
                                }
                                printf("\n");
                }*/

				

		}
	        if(info.piesa_sus != NULL){
	                        j = ppu.latime_piesa-1;// ultima linie
	        	        //iau cate une element
        	        	tag_id = mfc_tag_reserve();
                		if (tag_id==MFC_TAG_INVALID){
                    			printf("SPU: ERROR can't allocate tag ID\n");
	                    		return -1;
		                }
        		        PPMPixel *start = info.piesa_sus + ppu.lungime * j;
               			mfc_get((void*)(piesa_sus), (unsigned int)start, ppu.latime_piesa * sizeof(PPMPixel), tag_id, 0, 0);

	               		waitag(tag_id);
		                mfc_tag_release(tag_id);
        	        
                   /*     if(info.piesa_sus == (PPMPixel*)0xf7d68580){
                                printf("* ");
                                for(k=0; k < 80; k++){
                                        printf("%d %d %d ",piesa_sus[k].red, piesa_sus[k].green, piesa_sus[k].blue);
                                }
                                printf("\n");
                        }*/

	        }
		//iau piesa de comparat
		int dist, dist_min = 100000;
		int best = indecsi[0];
		for(k=0;k<info.cnt;k++){
    		    if(lista_piese[indecsi[k]].pozitionat == 0){
			//piesa de comparat sus (prima linie)
		        tag_id = mfc_tag_reserve();
        		if (tag_id==MFC_TAG_INVALID){
                	   	printf("SPU: ERROR can't allocate tag ID\n");
                        	return -1;
                	}
        	        mfc_get((void*)(piesa_comparat_sus), (unsigned int)lista_piese[indecsi[k]].offset, ppu.latime_piesa * sizeof(PPMPixel), tag_id, 0, 0);
	        	waitag(tag_id);
                	mfc_tag_release(tag_id);

                        //piesa de comparat stanga (prima coloana)
                        PPMPixel *start = lista_piese[indecsi[k]].offset;
                        for(j=0;j<ppu.latime_piesa;j++){//pentru fiecare linie
                                //iau cate un element
                                tag_id = mfc_tag_reserve();
                                if (tag_id==MFC_TAG_INVALID){
                                    printf("SPU: ERROR can't allocate tag ID\n");
                                    return -1;
                                }
                                mfc_get((void*)(&piesa_comparat_stanga[j]), (unsigned int)start, sizeof(PPMPixel), tag_id, 0, 0);
                                waitag(tag_id);
                                mfc_tag_release(tag_id);
                                start += ppu.lungime;
                        }
			dist = manhattan();
			if(dist < dist_min){
				dist_min = dist;
				best = indecsi[k];
		        }
			//printf("dist intre %p si %d  = %d \n",info.piesa_stanga, indecsi[k], dist);
		    }
                        if(lista_piese[indecsi[k]].offset == (PPMPixel*)0xf7d68580){
                                printf("$ ");
                                for(m=0; m < 80; m++){
                                        printf("%d %d %d ",piesa_comparat_sus[m].red, piesa_comparat_sus[m].green, piesa_comparat_sus[m].blue);
                                }
                                printf("\n");
                                for(m=0; m < 80; m++){
                                        printf("%d %d %d ",piesa_comparat_stanga[m].red, piesa_comparat_stanga[m].green, piesa_comparat_stanga[m].blue);
                                }
                                printf("\n");

                        }
		}
		printf("SPU %llx: %d %d\n",argc, best, dist_min);	
		spu_write_out_mbox((unsigned int)best);
		spu_write_out_mbox(dist_min);
	    }
	    else{
                spu_write_out_mbox(-1);
                spu_write_out_mbox(-1);
	    }
    }
    return 0;
}

int manhattan(){
	
	int dist = 0;
	int i;
/*
	vector int *stanga_ref = (vector int *)(&piesa_stanga[0]);
	vector int *sus_ref = (vector int *)(&piesa_sus[0]);
	vector int *comp_sus = (vector int *)(&piesa_comparat_sus[0]);
    vector int *comp_stanga = (vector int *)(&piesa_comparat_stanga[0]);
    vector int dif,dif2;

    if(info.piesa_stanga != NULL){
		int j = ppu.latime_piesa % 4;
	    for(i=0;i<ppu.latime_piesa/4;i++){
			dif[i] = spu_sub(piesa_stanga[i],piesa_comparat_stanga[i]);
			dif[i] = absi4(dif[i]);
	    }
		for(j=0;j<i;j++){
			dist += dif[i];		
		}	    
		for(i=ppu.latime_piesa-j;i<ppu.latime_piesa;i++){
			dist += abs(piesa_stanga[i].red - piesa_comparat_stanga[i].red);
			dist += abs(piesa_stanga[i].green - piesa_comparat_stanga[i].green);
			dist += abs(piesa_stanga[i].blue - piesa_comparat_stanga[i].blue);			
		}

    }

	if(info.piesa_sus != NULL){
		int j = ppu.latime_piesa % 4;
           for(i=0;i<ppu.latime_piesa/4;i++){
               dif2[i] = spu_sub(piesa_sus[i],piesa_comparat_sus[i]);
               dif2[i] = absi4(dif2[i]);
           }
        }
        		for(j=0;j<i;j++){
			dist += dif[i];		
		}	    
		for(i=ppu.latime_piesa-j;i<ppu.latime_piesa;i++){
			dist += abs(piesa_sus[i].red - piesa_comparat_sus[i].red);
			dist += abs(piesa_sus[i].green - piesa_comparat_sus[i].green);
			dist += abs(piesa_sus[i].blue - piesa_comparat_sus[i].blue);			
		}
    }
    
    
    
    
	return dist;
}
