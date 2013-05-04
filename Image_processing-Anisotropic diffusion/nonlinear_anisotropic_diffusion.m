function nonlinear_anisotropic_diffusion(filein, iteratii, fileout)

	Img = imread(filein);
	im = im2double(Img);

diff_im = im;


dx = 1;
dy = 1;
dd = sqrt(2);

% 2D convolution masks - finite differences.
hN = [0 1 0; 
	  0 -1 0; 
	  0 0 0];
hS = [0 0 0; 
	  0 -1 0; 
	  0 1 0];
hE = [0 0 0; 
	  0 -1 1; 
	  0 0 0];
hW = [0 0 0; 
	  1 -1 0; 
	  0 0 0];
hNE = [0 0 1; 
	   0 -1 0; 
	   0 0 0];
hSE = [0 0 0; 
	   0 -1 0; 0 0 1];
hSW = [0 0 0; 
       0 -1 0; 
       1 0 0];
hNW = [1 0 0; 
	   0 -1 0; 
	   0 0 0];


for t = 1:iteratii

		%gradientii de ordin 1 pe toate directiile
        nablaN = imfilter(diff_im,hN,'conv');
        nablaS = imfilter(diff_im,hS,'conv');   
        nablaW = imfilter(diff_im,hW,'conv');
        nablaE = imfilter(diff_im,hE,'conv');   
        nablaNE = imfilter(diff_im,hNE,'conv');
        nablaSE = imfilter(diff_im,hSE,'conv');   
        nablaSW = imfilter(diff_im,hSW,'conv');
        nablaNW = imfilter(diff_im,hNW,'conv');
        

        k = 0.01;
        lambda = 0.25;
        

	    cN = exp(-(nablaN/k).^2);
        cS = exp(-(nablaS/k).^2);
        cW = exp(-(nablaW/k).^2);
        cE = exp(-(nablaE/k).^2);
        cNE = exp(-(nablaNE/k).^2);
        cSE = exp(-(nablaSE/k).^2);
        cSW = exp(-(nablaSW/k).^2);
        cNW = exp(-(nablaNW/k).^2);


        diff_im = diff_im + lambda*((1/(dy^2))*cN.*nablaN + (1/(dy^2))*cS.*nablaS + (1/(dx^2))*cW.*nablaW + (1/(dx^2))*cE.*nablaE + (1/(dd^2))*cNE.*nablaNE + (1/(dd^2))*cSE.*nablaSE + (1/(dd^2))*cSW.*nablaSW + (1/(dd^2))*cNW.*nablaNW );
           
end

	Img2 = diff_im; 

	imshow(Img2);
	imwrite(Img2,fileout);

endfunction
