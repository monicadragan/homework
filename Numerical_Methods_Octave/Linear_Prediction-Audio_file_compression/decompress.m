function decompress(wavname)

% pregateste noul fisier decomprimat

k=strfind(wavname,'.');
compfile(1:k)=wavname(1:k);
originalwav(1:k)=wavname(1:k);
compfile(k:k+4)='2.wav';
originalwav(k+1:k+3)='wav';

f=fopen(wavname,'r');

m=fread(f,[1 2],'float32');
ms=m(1);
p=int32(m(2));

size = wavread(originalwav,'size');
sample_no = size(1);

rate = int32(ms * 8000); %nr de esantioane pentru fiecare interval ms

sample_no-=mod(sample_no,rate);

for i=1:rate:sample_no-1
	y(i:i+p-1)=fread(f,[1 p],'float32');
	a(1:p)=fread(f,[1 p],'float32');
	
	for n=i+p:i+rate-1
		y(n)=0;
		
		y(n)=a(1:p)*y(n-1:-1:n-p)';
		
		y(n)=y(n)*(-1);
	end

end

fclose(f);

%f=fopen(compfile,'a');
wavwrite(compfile,y');
%fclose(f);

endfunction
