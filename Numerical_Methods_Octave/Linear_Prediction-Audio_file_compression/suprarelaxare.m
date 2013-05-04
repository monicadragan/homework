function x = suprarelaxare(a,b,x0,w,eps,maxiter)

[n,n]=size(a);
x=zeros(n,1);

for pas=1:maxiter
	if n==1
		x=b/a;
	else
		for i=1:n
			s1 = a(i,1:i-1) * x(1:i-1);
			s1 = s1 / a(i,i);
			s2 = a(i,i+1:n) * x0(i+1:n);
			s2 = s2 / a(i,i);
			x(i) = (-1) * w * s1 + (1 - w) * x0(i) - w * s2 + w * b(i) / a(i,i);
		end

		p = norm(x-x0,1);
		q = norm(x,1);
	
		if p <= eps*q
			break;
		end
	
		x0=x;
	end	

end

endfunction
