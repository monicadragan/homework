function [R G B] = sistem(Y,Cr,Cb)

a=0.299;
b=0.587;
c=0.114;
d=0.168736;
e=0.331264;
f=0.5;
g=0.418688;
h=0.081312;


M=[a , b , c ;
   -d,-e , f ;
    f,-g ,-h;];
%det(M)
%a*e*h + c*d*g + f*f*b + c*e*f + a*f*g - b*d*h

R=Y * (e*h + f*g) + (Cb-128) * (-c*g + b*h) + (Cr-128) * (b*f + c*e);
R=R/det(M);

G=Y*(f*f - d*h) + (Cb-128) * (-a*h - c*f) + (Cr-128) * (-c*d - a*f);
G=G/det(M);

B=Y*(d*g + e*f) + (Cb-128) * (b*f + a*g) + (Cr-128) * (-a*e + d*b);
B=B/det(M);


endfunction
