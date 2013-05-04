function compress(wavname,ms,p)

% pregateste noul fisier comprimat

k=strfind(wavname,'.');
compfile(1:k)=wavname(1:k);
compfile(k+1:k+10)='compressed';

f=fopen(compfile,'w');

fwrite(f,ms,'float32');
fwrite(f,p,'float32');

%lucreaza la comprimarea fisierului original

size = wavread(wavname,'size');
sample_no = size(1);

rate = ms * 8000; %nr de esantioane pentru fiecare interval ms
sample_no-=mod(sample_no,rate);



for i=0:rate:sample_no-1

	y = wavread(wavname,[i+1 i+p]); % astea sunt valorile reale
	fwrite(f,y,'float32');
	x = wavread(wavname,[i+1 i+rate]);
	x(1);
	%calculez coeficientii de predictie
	R=zeros(p,p);	
	for k=1:p
		%for j=k:rate			
		%	R(1,k)=R(1,k)+(x(j)*x(j-k+1));
		R(1,k)=x(k:rate)'*x(1:rate-k+1);		
		R(k,1)=R(1,k);
		%end
	end
	
	%completeaza restul matricii 
	for j=2:p
		for k=2:p
			R(j,k)=R(j-1,k-1);
		end
	end

	r(1:p-1)=R(1,2:p);
	r(p)=0;
	for j=p+1:rate
		r(p)=r(p)+x(j)*x(j-p);
	end

	a=levinson(R,-r,1,0,0);

	fwrite(f,a,'float32');

end

fclose(f);

endfunction
