function linear_isotropic_diffusion(filein, iteratii, fileout)

	Img = imread(filein);

	lambda = 0.25;
	Img2 = im2double(Img);
	
	for i = 1:iteratii
	
		fright = [Img2(:,1),Img2(:,1:end-1)];
		fleft = [Img2(:,2:end),Img2(:,end)];
		fdown = [Img2(1,:);Img2(1:end-1,:)];
		fup = [Img2(2:end,:);Img2(end,:)];

 		Img2 = Img2 + lambda*(fright + fleft + fup + fdown - 4*Img2);
		
		
	endfor

	imshow(Img2);
	imwrite(Img2,fileout);

endfunction
