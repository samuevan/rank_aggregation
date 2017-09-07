function [ndcg, precision, map, hits] = evaluate_model(file_path, data_path, scores, dataset, fold, which)

	in_file = [data_path,dataset,'Fold',num2str(fold),'/', 'in', which, num2str(randn), '.txt'];
	out_file = [data_path,dataset,'Fold',num2str(fold),'/', 'out', which, num2str(randn), '.txt'];

	fid = fopen(in_file, 'w');    
	fprintf(fid, '%f\n', scores);
	fclose(fid);

    map_file = [data_path, dataset, '/Fold', num2str(fold), '/', which, '.map'];
    map_file_stats = exist(map_file,'file');
    #verify if the folder containing the input files contains files in the
    #octave format (.x .y and .map) or in the text format and calls the 
    #Evaluation script to the correct format

    if map_file_stats == 2
	    perl('Eval-Score-4.0.pl', [data_path, dataset, '/Fold', num2str(fold), '/', which, '.map'],...
		    in_file,...
		    out_file,...
		    '0');
    else
	    perl('Eval-Score-4.0.pl', [data_path, dataset, '/Fold', num2str(fold), '/', which, '.txt'],...
		    in_file,...
		    out_file,...
		    '0');
    end

	[ndcg, precision, map, hits] = extract_results(out_file);
	delete(in_file);
	delete(out_file);
end


