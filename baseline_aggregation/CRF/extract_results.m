function [ndcg, precision, map, hits] = extract_results(file_name)

precision = zeros(1, 10);
ndcg = zeros(1, 10);
map = zeros(1, 1);
hits = zeros(1, 1);
%file_name
results = textread(file_name, '%s');
%results

hits(1, 1) = str2num(results{25, 1});
map(1, 1) = str2num(results{26, 1});

for i = 1:10
	precision(1, i) = str2num(results{14+i, 1}); #ALTERADO DE 13 PARA 14, POIS ADICIONEI OS HITS NA LINHA DE LABEL E NOS RESULTADOS
	ndcg(1, i) = str2num(results{40+i, 1}); #O MESMO DA LINHA ANTERIOR
end


end



