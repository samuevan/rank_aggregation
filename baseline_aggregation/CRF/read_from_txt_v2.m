function [targets,dados] = read_from_txt(inputf)
%read data from the 
%clear all;
%close all;
fid =  fopen(inputf);
num_of_experts = 9; %TODO descobrir num of experts automaticamente

#fid2 = fopen("README");
qid_past = -1;
numq = 1;
docs_evals = [];
docs_ids = cell();
dados = {};
targets = {};
targets_aux = [];
num_lines_read = 1;

#READ THE FIRST LINE
linef = fgetl(fid);
linef = strrep(linef,"NULL","0");
tokens = strsplit (linef," ");
doc_id_pos = find(index(tokens,"#docid"),1) + 2;
nun_of_experts = find(index(tokens,"#docid"),1) - 3;

target_val = str2num(tokens{1});
qid = str2num(strsplit(tokens{2},":"){2});
#pega os valores das avaliacoes dos experts
experts = zeros(1,num_of_experts);

for k = 3:num_of_experts+2
    val = str2num(strsplit(tokens{k},":"){2});        
    experts(k-2) = val;
endfor

docs_evals(end+1,:) = experts;
doc_id_pos = find(index(tokens,"#docid"),1) + 2; # percorre duas vezes
#doc_id_pos = num_of_experts + 3;
docs_ids(end+1,:) = tokens{doc_id_pos};
targets_aux(end+1,1) = target_val; 
qid_past = qid;

format_str = ["%f"];
for i = 2:length(tokens)
    format_str = [format_str," %s"];
endfor


while (! feof (fid))


    multiple_lines = textscan(fid,format_str,1000);
    num_lines = length(multiple_lines{1});

    for nline = 1:num_lines

        tokens = multiple_lines;
        #linef = strrep(linef,"NULL","0");
        #tokens = strsplit (linef," ");
        target_val = tokens{1}(nline);
        #target_val = str2num(tokens{1}(nline));

        qid = str2num(strsplit(tokens{2}{nline},":"){2});
        #pega os valores das avaliacoes dos experts
        experts = zeros(1,num_of_experts);

        for k = 3:num_of_experts+2
            val = str2num(strsplit(tokens{k}{nline},":"){2});        
            experts(k-2) = val;
        endfor


        if qid_past == qid || length(docs_evals) == 0

            docs_evals(end+1,:) = experts;
            #doc_id_pos = find(index(tokens,"#docid"),1) + 2; # percorre duas vezes
            #doc_id_pos = num_of_experts + 3;
            docs_ids(end+1,:) = tokens{doc_id_pos}{nline};
            targets_aux(end+1,1) = target_val; 

        else
            dados{numq,1} = docs_evals;
            dados{numq,2} = docs_ids;
                
            #doc_id_pos = find(index(tokens,"#docid"),1) + 2; # percorre duas vezes
            #doc_id_pos = num_of_experts + 3;
            docs_ids = cell();      
            docs_ids(1) = tokens{doc_id_pos}{nline};#continuar daqui

            docs_evals = [experts];
            targets{numq,1} = targets_aux;
            targets_aux = [target_val];       
            numq += 1;

        endif        
        qid_past = qid;
        num_lines_read += 1;

        if mod(num_lines_read,1000) == 0
            disp(num_lines_read)
        endif        
            

        endfor

    #pega os valores de qid, dos experts e do docid
        
endwhile
#ao final do arquivo preciso salvar o ultimo conjunto de query - docs
dados{numq,1} = docs_evals;
dados{numq,2} = docs_ids;
targets{numq,1} = targets_aux;

