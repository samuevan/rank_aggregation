#!/usr/bin/octave -qf
clear all;
close all;
path(pathdef);

arg_list = argv ();
dataset = arg_list{1};#'MQ2008-agg';
num_max_iter = str2num(arg_list{2});
pini = str2num(arg_list{3});#'MQ2008-agg';
pend = str2num(arg_list{4});#'MQ2008-agg';
nruns = str2num(arg_list{5});#'MQ2008-agg';
%paths to data and this file - set these to the location where the folder
%is extracted
data_path = [pwd, filesep];
file_path = [pwd, filesep];

RESULTS = cell(5, 7);
#run_id = num2str(randn)

#out_scores_file = ["crf_",run_id,".scores"]
#str_read_params_time = ""

for fold = pini:pend
    #fid_log = fopen([data_path, dataset, filesep, 'Fold', num2str(fold), filesep,"crf_log_",run_id], 'w');

    disp("Starting FOLD")
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %load LETOR4.0 data
    read_time = tic;
    load([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'train.x'], 'train_data');
    load([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'train.y'], 'train_targets');

    load([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'test.x'], 'test_data');
    load([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'test.y'], 'test_targets');

    load([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'validation.x'], 'validation_data');
    load([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'validation.y'], 'validation_targets');
    
    #load([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'vali.mat'], 'validation_targets', 'validation_data');
    #load([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'test.mat'], 'test_targets', 'test_data');
    
    #[train_targets,train_data] = read_from_txt([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'train.txt']);
    
    #[validation_targets,validation_data] = read_from_txt([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'validation.txt']);
    
    #fprintf(fid_log, 'Reading Time: %f\n',toc(read_time));
    str_read_params_time = ['Reading Time: ',num2str(toc(read_time)),'\n'];
    #[test_targets,test_data] = read_from_txt([data_path, dataset, filesep, 'Fold', num2str(fold), filesep, 'test.txt']);
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


    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %pre-compute unary (\varphi_k) and pairwise potentials (\phi_k)
    param_time = tic;
    train_data = extract_crf_potentials(train_data, parameters);
    str_read_params_time = [str_read_params_time, 'Param Train Time:',num2str(toc(param_time)),'\n'];
    #fprintf(fid_log, 'Param Train Time: %f\n',toc(param_time));
    param_time = tic;
    validation_data = extract_crf_potentials(validation_data, parameters);
    str_read_params_time = [str_read_params_time, 'Param Val Time:',num2str(toc(param_time)),'\n'];
    #fprintf(fid_log, 'Param Val Time: %f\n',toc(param_time));
    param_time = tic;
    test_data = extract_crf_potentials(test_data, parameters);
    str_read_params_time = [str_read_params_time, 'Param Test Time:',num2str(toc(param_time)),'\n'];
    #fprintf(fid_log, 'Param Test Time: %f\n',toc(param_time));
    #fflush(fid_log)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for runid = 1:nruns
        fold_time = tic;
        fid_log = fopen([data_path, dataset, filesep, 'Fold', num2str(fold), filesep,"crf_log_",num2str(runid)], 'w');
        fprintf(fid_log,str_read_params_time);

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
        [~, ~, RESULT_valid] = crf_aggr_der(W, validation_data, [], [], true);
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
	        [~, ~, RESULT_valid] = crf_aggr_der(W, validation_data, [], [], true);
	        [ndcg, precision, map, hits] = evaluate_model(file_path, data_path, cell2mat(RESULT_valid.scores), dataset, fold, 'validation');
	        NDCG_VL(iter, :) = ndcg;
	        PR_VL(iter, :) = [precision, map];
	
	        [~, ~, RESULT_test] = crf_aggr_der(W, test_data, [], [], true);
	        [ndcg, precision, map, hits] = evaluate_model(file_path, data_path, cell2mat(RESULT_test.scores), dataset, fold, 'test');
	        NDCG_TS(iter, :) = ndcg;
	        PR_TS(iter, :) = [precision, map];
            HITS_TS(iter, :) = hits;
	        fprintf(fid_log, '<Aggr: ENDCG objective> ITER:%i  TIME:%3.1f  OBJ:%4.2f  |W|:%6.2f\n', iter, toc(startT), E_TR(iter, 1), norm(W));
            fflush(fid_log);
	        disp([NDCG_VL(iter, :); NDCG_TS(iter, :)])

            out_scores_file = ["crf_",num2str(runid),".scores"];
         	fid_final = fopen([data_path, dataset, filesep, 'Fold', num2str(fold), filesep,out_scores_file], 'w');
	        fprintf(fid_final, '%f\n', cell2mat(RESULT_test.scores));
	        fclose(fid_final);

            

        end

        fprintf(fid_log, 'Total Time: %f', toc(fold_time));
        fclose(fid_log);

    end


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
for fold = pini:pend
	test_prec = [test_prec; RESULTS{fold, 4}(end, :)];
	test_ndcg = [test_ndcg; RESULTS{fold, 5}(end, :)];
    hits_total = [hits_total; RESULTS{fold,8}(end, :)];

end
%fprintf(1, '%2.2f ', [100.*mean(test_ndcg(:, pini:pend), 1), 100.*mean(test_prec(:, pini:pend), 1), 100.*mean(test_prec(:, end), 1),mean(hits_total(:, end),1) ]);
%fprintf(1, '\n');

% results should be close to:
% 42.29 44.99 47.54 49.05 51.03 48.67 44.58 42.08 38.75 36.55 50.41





