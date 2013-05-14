function [W, answer] = protein_family(input_file, test_file)

N = 1000;
D=[];
alphabet = "ARNDCQEGHILKMFPSTWYV-";
fid = fopen (input_file);
for i = 1:N
	fgetl (fid); %waste
	seq = fgetl(fid);
	strrep (seq, "X", "-"); % X is not in the alphabet
	D = [D;seq];
end

L=length(D(1,:));
length(alphabet);
W = zeros(length(alphabet),L);
D(:,5)';
for c=1:L %for each column
	for a=1:length(alphabet)
		%column c is D(:,i)
		%alphabet(a)
		W(a,c) = (length(findstr(D(:,c)',alphabet(a),0))+1)/(N+length(alphabet));
	end
end
fclose (fid);

max_weights = max(W);

for c=1:L %for each column
	idx = find(W(:,c) == max_weights(c));
	max_weights(c);
	alphabet(idx);
end

%compute F0 matix

for r=1:length(alphabet) %for each column
	F0(r) = sum(W(r,:))/L;
end

fid = fopen (test_file);
T=[];
l=[];
for i = 1:N
	fgetl (fid); %waste
	seq = fgetl(fid);
	strrep (seq, "X", "-"); % X is not in the alphabet
	T = [T;seq];
	suma = 0;
	for j = 1:L
		%get the index of the letter in the alphabet
		idx = findstr(alphabet,seq(j),0);
		if idx > 0
			suma = suma +  (log(W(idx,j)/F0(idx)));
		end
	end
	if suma > 0
		l = [l;1];
	else
		l = [l;0];
	end
end
answer = l
endfunction
