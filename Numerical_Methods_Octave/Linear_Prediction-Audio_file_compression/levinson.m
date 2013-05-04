%nu conteaza daca y(care pastreaza rezultatele) este vctor linie sau coloana
function x = levinson(a,y,n,f,b,x)

%incepi apelul cu n=1

if n==1 
	newf=1/a(1,1);
	newb=1/a(1,1);
	x(1)=y(1)/a(1,1);
else 
% stiu pasul n-1, aflu pasul n
	%a(n,1:n-1)
	epsf=a(n,1:n-1)*f';
	epsb=a(1,2:n)*b';
	epsx=a(n,1:n-1)*x';
	f(n)=0;
	auxb=b;
	b(2:n)=auxb(1:n-1);
	b(1)=0;
	newf=(1/(1-epsf*epsb)).*f(1:n) - (epsf/(1-epsf*epsb)).*b(1:n); 
	newb=(1/(1-epsf*epsb)).*b(1:n) - (epsb/(1-epsf*epsb)).*f(1:n); 
	x(n)=0;
	x = x + (y(n)-epsx).*newb;


endif

[N N]=size(a);

if n<N
x = levinson(a,y,n+1,newf,newb,x);
endif

endfunction
