function output = run_ann(input, w_input_hidden, levels_hidden, w_hidden_output, hidden_bias, output_bias)

	len_input = length(input);
	len_output = size(w_hidden_output,2);
	nodes_hidden = size(w_input_hidden,2);

	o_hidden = zeros(levels_hidden, nodes_hidden);

	for i = 1:nodes_hidden
		for j=1:len_input
			o_hidden(1,i) = o_hidden(1,i) + input(j) * w_input_hidden(j,i);			
		end
		o_hidden(1,i) = o_hidden(1,i) + hidden_bias(1,j);
		o_hidden(1,i) = sigmoid(o_hidden(1,i));
	end

	
	if levels_hidden(1) > 1
		%TODO
		%pentru fiecare strat ascuns
		1;
	end
	

	output = zeros(len_output);
		
	%completez matricea o_output
	for i=1:len_output
		output(i) = 0;
		for j = 1:nodes_hidden
			output(i) = output(i) + o_hidden(end,j) * w_hidden_output(j,i);
		end
		output(i) = output(i) + output_bias(i);			
		output(i) = sigmoid(output(i));
	end	


endfunction
