function compress(bmp_filename, myjpg_filename)

a=0.299;
b=0.587;
c=0.114;
d=0.168736;
e=0.331264;
g=0.418688;
h=0.081312;

[R G B]=read_BMP(bmp_filename);

f=fopen(myjpg_filename ,'w');

[n m]=size(R);
fwrite(f,n,'int32');
fwrite(f,m,'int32');

Y = a*R + b*G + c*B;
Cb = 128 - d*R - e*G + 0.5*B;
Cr = 128 + 0.5*R - g*G - h*B;

Y(1:8,1:8);
Cb(1:8,1:8);
Cr(1:8,1:8);

Y = Y - 128;
Cb = Cb - 128;
Cr = Cr - 128;

% transformata cosinus si quantizarea

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

for i=1:8:n
	for j=1:8:m

	%Y2(i:i+7,j:j+7)=T*Y(i:i+7,j:j+7)*T';
	Y2=T*Y(i:i+7,j:j+7)*T';
	%Y2=T*Y(1:8,1:8)*T';	
	Y2=round(Y2./Q);

	fwrite(f,Y2,'int16');

	Cb2=T*Cb(i:i+7,j:j+7)*T';
	Cb2=round(Cb2./Q);
	fwrite(f,Cb2,'int16');

	Cr2=T*Cr(i:i+7,j:j+7)*T';
	Cr2=round(Cr2./Q);
	fwrite(f,Cr2,'int16');

	end
end
fclose(f);

endfunction
