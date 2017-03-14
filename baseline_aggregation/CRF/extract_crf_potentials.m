function [features] = extract_crf_potentials(data, parameters)

	features = cell(size(data, 1), 1);
	nlists = size(data{1, 1}, 2);

	if strcmp(parameters.pairwise_type, 'BINARY') == true
		type = 0;

	elseif strcmp(parameters.pairwise_type, 'RANK DIFFERENCE') == true
		type = 1;

	elseif strcmp(parameters.pairwise_type, 'LOG RANK DIFFERENCE') == true
		type = 2;

	else
		fprintf(1, '<extract_features> ERROR: unrecognized pairwise_type\n');
		keyboard
	end

	for i = 1:size(data, 1)
		
		rankings = data{i, 1};
		ndocs = size(rankings, 1);

		%unary potential
		unary_potential = double(rankings == 0);

		if parameters.normalize == true
			max_ranks = max(rankings, [], 1);
			max_ranks(max_ranks == 0) = 1;

			if type == 1
				rankings = rankings ./ repmat(max_ranks, ndocs, 1);

			elseif type == 2
				log_max = log(max_ranks);
				log_max(log_max == 0) = 1;
			end
		end

		nfeatures_per_list = 2;
		qfeatures = zeros(ndocs, nfeatures_per_list*nlists);
		
		%win/loss for every document
		for l = 1:nlists
			Y = zeros(ndocs, ndocs);
			for j = 1:ndocs-1
				if rankings(j, l) == 0
					continue;
				end
				
				for k = j+1:ndocs
					if rankings(k, l) == 0
						continue
					end

					if rankings(j, l) < rankings(k, l)
						if type == 0
							Y(j, k) = 1;
	
						elseif type == 1
							Y(j, k) = rankings(k, l) - rankings(j, l);
	
						elseif type == 2
							if parameters.normalize == true
								Y(j, k) = (log(rankings(k, l)) - log(rankings(j, l))) / log_max(1, l);
							else
								Y(j, k) = log(rankings(k, l)) - log(rankings(j, l));
							end
						end
					else
						if type == 0
							Y(k, j) = 1;
	
						elseif type == 1
							Y(k, j) = rankings(j, l) - rankings(k, l);
	
						elseif type == 2
							if parameters.normalize == true
								Y(k, j) = (log(rankings(j, l)) - log(rankings(k, l))) / log_max(1, l);
							else
								Y(k, j) = log(rankings(j, l)) - log(rankings(k, l));
							end
						end
					end
				end
			end
			Y = Y ./ (ndocs - 1);
			qfeatures(:, (l-1)*nfeatures_per_list+1:l*nfeatures_per_list) = [sum(Y, 2), -sum(Y, 1)'];
		end

		features{i, 1} = [unary_potential, qfeatures];
	end
end





