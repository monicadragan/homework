function x = householder(a,b)

[m n] = size(a);

for k = 1:n
	x = a(k:m,k);


	e = zeros(m-k+1,1);
	e(1) = 1;



	v = sign(x(1)) * norm(x) * e + x;

	v = v / norm(v);
	
	a(k:m,k:n) = a(k:m, k:n) - 2.*v*v'*a(k:m, k:n);

	b(k:m) = b(k:m) - 2.*v*v'*b(k:m);

end

x=suptr(a,b);

endfunction
