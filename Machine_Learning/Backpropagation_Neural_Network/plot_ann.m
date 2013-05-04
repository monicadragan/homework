function plot_ann(filename)

	clf();
	data = load(filename);
	%sortez dupa coloana a 2a (target)
	data = sortrows(data,2);
	plot(data(:,1),'r*');

	hold on;
	plot(data(:,2),'b*');
	legend("ann result","target");	
	title(filename);
	
endfunction
