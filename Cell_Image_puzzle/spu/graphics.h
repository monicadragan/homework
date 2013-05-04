

typedef struct {
     int red,green,blue,padding;
} PPMPixel;

typedef struct {
     int x, y;
     PPMPixel *data;
} PPMImage;

PPMImage* readPPM(const char*);
void writePPM(const char*, PPMImage*);
//PPMImage** copiez_petic(int, int, int, int, PPMImage*);
//int compare(PPMImage*, PPMImage*, int,int);

void get_random_coord(int *line, int *col);

