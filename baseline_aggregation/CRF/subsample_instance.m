%downsample training query ensuring that at least one document of every
%relevance is included in the sample
function [sample, query_targets, query_samples, query_samples_OBJ] = subsample_instance(qtargets, parameters)

	nqdocs = size(qtargets, 1);
	if nqdocs <= parameters.ndocs_per_query
		sample = (1:nqdocs)';
	else
		labels_distinct = flipud(unique(qtargets));
		nlabels_distinct = size(labels_distinct, 1);

		if nlabels_distinct == 1
			sample = randperm(nqdocs)';
			sample = sample(1:parameters.ndocs_per_query, 1);
		else
			%find positions of each relevance label
			index = (1:nqdocs)';
			qlabel_index = cell(nlabels_distinct, 1);
			sample = zeros(parameters.ndocs_per_query, 1);
			for i = 1:nlabels_distinct
				qlabel_index{i, 1} = index(qtargets == labels_distinct(i, 1), 1);
				qlabel_index{i, 1} = qlabel_index{i, 1}(randperm(size(qlabel_index{i, 1}, 1))', 1);

				sample(i, 1) = qlabel_index{i, 1}(1, 1);
				qlabel_index{i, 1} = qlabel_index{i, 1}(2:end, 1);
			end
			
			%sample the rest randomly
			rest = cell2mat(qlabel_index);
			rest = rest(randperm(size(rest, 1)), 1);
	
			sample(i+1:end, 1) = rest(1:parameters.ndocs_per_query-i, 1);
		end
	end

	query_targets = {qtargets(sample, 1)};
	query_samples = {perms(1:size(sample, 1))'};
	query_samples_OBJ = {find_sample_ndcg(query_samples{1, 1}, query_targets{1, 1})};
end


function [ndcg] = find_sample_ndcg(ranks, labels)
	
	dcgs = labels' * (1./log2(ranks + 1));
	norm = max(dcgs, [], 2);
	if norm == 0
		ndcg = ones(1, size(ranks, 2));
	else
		ndcg = dcgs ./ norm;
	end
end
