function decompress(myjpg_filename, bmp_filename)

f=fopen(myjpg_filename,"r");

size=fread(f,[1 2], "int32");
n=size(1);
m=size(2);

   Q = [16,  11,   10,   16,   24,    40,    51,    61;
        12,  12,   14,   19,   26,    58,    60,    55;
        14,  13,   16,   24,   40,    57,    69,    56;
        14,  17,   22,   29,   51,    87,    80,    62;
        18,  22,   37,   56,   68,    109,   103,   77;
        24,  35,   55,   64,   81,    104,   113,   92;
        49,  64,   78,   87,   103,   121,   120,   101;
        72,  92,   95,   98,   112,   100,   103,   99];

T=zeros(8,8);
T(1,:)=1/sqrt(8);
for i=1:7
	for j=0:7
		T(i+1,j+1) = sqrt(1/4) * cos((2*j+1)*i*pi/16);
	end
end

for i=1:8:n-7
	for j=1:8:m-7
	
	Y=fread(f,[8 8],'int16');
	Y=Y.*Q;
	Y=T'*Y*T + 128;

	Cb=fread(f,[8 8],'int16');
	Cb=Cb.*Q;
	Cb=T'*Cb*T + 128;

	Cr=fread(f,[8 8],'int16');
	Cr=Cr.*Q;
	Cr=T'*Cr*T + 128;

	[R(i:i+7,j:j+7) G(i:i+7,j:j+7) B(i:i+7,j:j+7)]=sistem(Y,Cr,Cb);


	end
end

fclose(f);

write_BMP(bmp_filename,R,G,B);

endfunction
