function x = suptr(a,b)

[n n]=size(a);
x=zeros(n,1);

for i=n:-1:1
	x(i)=(b(i)-a(i,1:n)*x)/a(i,i);
end

endfunction