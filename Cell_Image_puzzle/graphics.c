#include <stdlib.h>
#include <stdio.h>
#include <libmisc.h>
#include "graphics.h"

#define CREATOR "Monica_DRAGAN"
#define RGB_COMPONENT_COLOR 255

extern PPMPixel *pixels;

PPMImage *readPPM(const char *filename)
{
     char buff[16];
     PPMImage *img;
     FILE *fp;
     int c, rgb_comp_color;
     //open PPM file for reading
     fp = fopen(filename, "rb");
     if (!fp) {
          fprintf(stderr, "Unable to open file '%s'\n", filename);
          return NULL;
    }

    //read image format
    if (!fgets(buff, sizeof(buff), fp)) {
          perror(filename);
          return NULL;
    }

    //check the image format
    if (buff[0] != 'P' || buff[1] != '3') {
         fprintf(stderr, "Invalid image format (must be 'P6')\n");
         return NULL;
    }

    //alloc memory form image
    img = malloc(sizeof(PPMImage));
    if (!img) {
         fprintf(stderr, "Unable to allocate memory\n");
         return NULL;
    }

    //check for comments
    c = getc(fp);
    while (c == '#') {
    	while (getc(fp) != '\n') ;
        	 c = getc(fp);
    }

    ungetc(c, fp);
    //read image size information
    if (fscanf(fp, "%d %d", &img->x, &img->y) != 2) {
         fprintf(stderr, "Invalid image size (error loading '%s')\n", filename);
         exit(1);
    }

    //read rgb component
    if (fscanf(fp, "%d", &rgb_comp_color) != 1) {
         fprintf(stderr, "Invalid rgb component (error loading '%s')\n", filename);
         exit(1);
    }

    //check rgb component depth
    if (rgb_comp_color!= RGB_COMPONENT_COLOR) {
         fprintf(stderr, "'%s' does not have 8-bits components\n", filename);
         exit(1);
    }

    while (fgetc(fp) != '\n') ;
    //memory allocation for pixel data
    pixels = malloc_align(img->x * img->y * sizeof(PPMPixel),7);

    if (!pixels) {
         fprintf(stderr, "Unable to allocate memory\n");
         exit(1);
    }

    //read pixel data from file
    int i;
    for(i=0;i<img->x * img->y;i++){
    	fscanf(fp, "%d\n", &(pixels[i].red));
    	fscanf(fp, "%d\n", &(pixels[i].green));
    	fscanf(fp, "%d\n", &(pixels[i].blue));   
    }    

    img->data = pixels;
    
    fclose(fp);
    return img;
}

void writePPM(const char *filename, PPMImage *img)
{
    FILE *fp;
    //open file for output
    fp = fopen(filename, "wb");
    if (!fp) {
         fprintf(stderr, "Unable to open file '%s'\n", filename);
         exit(1);
    }

    //write the header file
    //image format
    fprintf(fp, "P3\n");

    //comments
    fprintf(fp, "# Created by %s\n",CREATOR);

    //image size
    fprintf(fp, "%d %d\n",img->x,img->y);

    // rgb component depth
    fprintf(fp, "%d\n",RGB_COMPONENT_COLOR);

    // pixel data
    PPMPixel *data = img->data;
    int i;
    for(i=0;i<img->x * img->y;i++){
        fprintf(fp, "%d\n", data[i].red);
        fprintf(fp, "%d\n", data[i].green);
        fprintf(fp, "%d\n", data[i].blue);
    }

    fclose(fp);
}

/*int compare(PPMImage* ultimul_petic, PPMImage* noul_petic, int dim_peric_oriz, int dim_peric_vert){

	return 0;
}
PPMImage* copiez_petic(int line, int col, int dim_oriz, int dim_vert, PPMImage* image_in){

	return NULL;
}*/










