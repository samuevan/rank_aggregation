%compute parameter gradients
function [f, df, RESULT] = crf_aggr_der(W, data, samples, samples_OBJ, scores_only)

nqueries = size(data, 1);
dW = zeros(size(W, 1), 1);

f = 0;
df = 0;
RESULT.scores = cell(nqueries, 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:nqueries
%query data
	qdata = data{i, 1};
	if scores_only == false
		qsamples = samples{i, 1};
		qsamples_OBJ = samples_OBJ{i, 1};
		nqsamples = size(qsamples, 2);
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%scores
	scores = qdata * W;
	RESULT.scores{i, 1} = scores;
	if scores_only == true
		continue
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%energy
	normalized_samples = 1./(log2(qsamples + 1));
	
	E_model = normalized_samples' * scores;
	log_Z_model = logadd(E_model, 1);
	P_model = exp(E_model - log_Z_model);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%expected loss objective and score derivatives
	qEX = qsamples_OBJ * P_model;

	temp = P_model * P_model';
	temp(1:nqsamples+1:nqsamples*nqsamples) = P_model .* (P_model - 1);
	dfdscores = -normalized_samples * (qsamples_OBJ * temp)';

	f = f + qEX;

	%weight derivatives
	dW = dW + qdata' * dfdscores;
end

if scores_only == true
	return;
end
df = dW;

end