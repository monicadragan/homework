function nonlinear_isotropic_diffusion(filein, iteratii, fileout)

	Img = imread(filein);

	lambda = 0.25;
	k = 0.005;
	Img2 = im2double(Img);
	
	for i = 1:iteratii
	
		fright = [Img2(:,1),Img2(:,1:end-1)];
		fleft = [Img2(:,2:end),Img2(:,end)];
		fdown = [Img2(1,:);Img2(1:end-1,:)];
		fup = [Img2(2:end,:);Img2(end,:)];
		
		Img2 = Img2 + lambda*( (k./(k+(fright - Img2).^2)).*(fright - Img2) + (k./(k+(fleft - Img2).^2)).*(fleft - Img2) + (k./(k+(fup - Img2).^2)).*(fup - Img2) + (k./(k+(fdown - Img2).^2)).*(fdown - Img2));
		
	endfor

	imshow(Img2);
	imwrite(Img2,fileout);

endfunction
