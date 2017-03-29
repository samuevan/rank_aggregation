#!/usr/bin/octave -qf
clear all;
close all;
path(pathdef);

arg_list = argv ();
dataset = arg_list{1};#'MQ2008-agg';
num_max_iter = str2num(arg_list{2});
pini = arg_list{3};#'MQ2008-agg';
pend = arg_list{4};#'MQ2008-agg';
%paths to data and this file - set these to the location where the folder
%is extracted
data_path = [pwd, filesep];
file_path = [pwd, filesep];

RESULTS = cell(5, 7);

for fold = pini:pend
    disp("Starting FOLD")
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %load LETOR4.0 data

    %load([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'train.mat'], 'train_targets', 'train_data');
    %load([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'vali.mat'], 'valid_targets', 'valid_data');
    %load([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'test.mat'], 'test_targets', 'test_data');
    tic()
    [train_targets,train_data] = read_from_txt([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'train.txt']);
    toc()
    tic()
    [valid_targets,valid_data] = read_from_txt([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'validation.txt']);
    toc()
    [test_targets,test_data] = read_from_txt([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'test.txt']);
    disp("FOLD READ - END")
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %set learning parameters

    parameters.nexperts = size(train_data{1, 1}, 2); %number of rankings in the agg
    parameters.init = 0.01;
    parameters.maxiter = num_max_iter;			%more iterations tends to give better results!
    parameters.learning_cut_ndcg = 10; %size of the output rankings(?)
    parameters.ndocs_per_query = 6;		%\epsilon in Algorithm 1
    parameters.weight_penalty = 0;

    %binary, rank difference and log rank difference methods to calculate the
    %pairwse potential \phi_k

    % parameters.normalize = false;
    % parameters.pairwise_type = 'BINARY';

    % parameters.normalize = true;
    % parameters.pairwise_type = 'RANK DIFFERENCE';

    parameters.normalize = true;
    parameters.pairwise_type = 'LOG RANK DIFFERENCE';
    parameters.learnrate = 2;


    parameters
    fold_time = tic;
    fid_log = fopen([data_path, dataset, filesep, 'Fold', num2str(fold), filesep,"crf_log"], 'w');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %pre-compute unary (\varphi_k) and pairwise potentials (\phi_k)
    train_data = extract_crf_potentials(train_data, parameters);
    valid_data = extract_crf_potentials(valid_data, parameters);
    test_data = extract_crf_potentials(test_data, parameters);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    E_TR = zeros(parameters.maxiter+1, 1);

    NDCG_VL = zeros(parameters.maxiter, parameters.learning_cut_ndcg);
    PR_VL = zeros(parameters.maxiter, parameters.learning_cut_ndcg+1);

    NDCG_TS = zeros(parameters.maxiter, parameters.learning_cut_ndcg);
    PR_TS = zeros(parameters.maxiter, parameters.learning_cut_ndcg+1);
    HITS_TS = zeros(parameters.maxiter, parameters.learning_cut_ndcg+1);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %initialize weights
    W = parameters.init .* randn(size(train_data{1, 1}, 2), 1);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    iter = 1;
    [~, ~, RESULT_valid] = crf_aggr_der(W, valid_data, [], [], true);
    [ndcg, precision, map, hits] = evaluate_model(file_path, data_path, cell2mat(RESULT_valid.scores), dataset, fold, 'validation');
    NDCG_VL(iter, :) = ndcg;
    PR_VL(iter, :) = [precision, map];


    [~, ~, RESULT_test] = crf_aggr_der(W, test_data, [], [], true);
    [ndcg, precision, map, hits] = evaluate_model(file_path, data_path, cell2mat(RESULT_test.scores), dataset, fold, 'test');
    NDCG_TS(iter, :) = ndcg;
    PR_TS(iter, :) = [precision, map];
    HITS_TS(iter, :) = hits;

    fprintf(fid_log, '<Aggr: ENDCG objective> ITER:%i  TIME:%3.1f  OBJ:%4.2f  |W|:%6.2f\n', iter, 0, E_TR(iter, 1), norm(W));
    #disp([NDCG_VL(iter, :); NDCG_TS(iter, :)])

    nqueries = size(train_targets, 1);
    batch_perm = randperm(nqueries)';

    for iter = 2:parameters.maxiter
        iter
	    startT = tic;
	    %make a pass through the training data and update CRF weights
	    for j = 1:nqueries
		    batch_index = batch_perm(j, 1);

		    %downsample documents for the current query
		    [qindex, query_targets, query_samples, query_samples_NDCG] =...
						    subsample_instance(train_targets{batch_index, 1}, parameters);
		
		    %find gradients
		    query_data = {train_data{batch_index, 1}(qindex, :)};
		    [f, df] = crf_aggr_der(W, query_data, query_samples, query_samples_NDCG, false);

		    %update parameters
		    E_TR(iter, 1) = E_TR(iter, 1) + f;
		    W = W + parameters.learnrate .* df - parameters.weight_penalty .* parameters.learnrate .* W;
	    end

	    %validate and test the model
	    [~, ~, RESULT_valid] = crf_aggr_der(W, valid_data, [], [], true);
	    [ndcg, precision, map, hits] = evaluate_model(file_path, data_path, cell2mat(RESULT_valid.scores), dataset, fold, 'validation');
	    NDCG_VL(iter, :) = ndcg;
	    PR_VL(iter, :) = [precision, map];
	
	    [~, ~, RESULT_test] = crf_aggr_der(W, test_data, [], [], true);
	    [ndcg, precision, map, hits] = evaluate_model(file_path, data_path, cell2mat(RESULT_test.scores), dataset, fold, 'test');
	    NDCG_TS(iter, :) = ndcg;
	    PR_TS(iter, :) = [precision, map];
        HITS_TS(iter, :) = hits;
	    fprintf(fid_log, '<Aggr: ENDCG objective> ITER:%i  TIME:%3.1f  OBJ:%4.2f  |W|:%6.2f\n', iter, toc(startT), E_TR(iter, 1), norm(W));
	    #disp([NDCG_VL(iter, :); NDCG_TS(iter, :)])


     	fid_final = fopen([data_path, dataset, filesep, 'Fold', num2str(fold), filesep,"crf_scores"], 'w');
	    fprintf(fid_final, '%f\n', cell2mat(RESULT_test.scores));
	    fclose(fid_final);

    end

fprintf(fid_log, 'Total Time: %f', toc(fold_time));
fclose(fid_log);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%save fold results
    RESULTS{fold, 1} = E_TR;
    RESULTS{fold, 2} = PR_VL;
    RESULTS{fold, 3} = NDCG_VL;
    RESULTS{fold, 4} = PR_TS;
    RESULTS{fold, 5} = NDCG_TS;
    RESULTS{fold, 6} = parameters;
    RESULTS{fold, 7} = W;
    RESULTS{fold, 8} = HITS_TS;
end

%average NDCG, Precision and MAP test results
test_ndcg = [];
test_prec = [];
hits_total = [];
for fold = 1:5
	test_prec = [test_prec; RESULTS{fold, 4}(end, :)];
	test_ndcg = [test_ndcg; RESULTS{fold, 5}(end, :)];
    hits_total = [hits_total; RESULTS{fold,8}(end, :)]

end
fprintf(1, '%2.2f ', [100.*mean(test_ndcg(:, 1:5), 1), 100.*mean(test_prec(:, 1:5), 1), 100.*mean(test_prec(:, end), 1),mean(hits_total(:, end),1) ]);
fprintf(1, '\n');

% results should be close to:
% 42.29 44.99 47.54 49.05 51.03 48.67 44.58 42.08 38.75 36.55 50.41





