function [ndcg, precision, map, hits] = evaluate_model(file_path, data_path, scores, dataset, fold, which)

	in_file = [data_path,dataset,'Fold',num2str(fold),'/', 'in', which, num2str(randn), '.txt'];
	out_file = [data_path,dataset,'Fold',num2str(fold),'/', 'out', which, num2str(randn), '.txt'];


	fid = fopen(in_file, 'w');    
	fprintf(fid, '%f\n', scores);
	fclose(fid);
	perl('Eval-Score-4.0.pl', [data_path, dataset, '/Fold', num2str(fold), '/', which, '.map'],...
		in_file,...
		out_file,...
		'0');

	[ndcg, precision, map, hits] = extract_results(out_file);
	delete(in_file);
	delete(out_file);
end


