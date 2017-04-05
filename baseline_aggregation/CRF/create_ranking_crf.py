#use the final scores of the CRF to construct an output ranking
#this output ranking could be used to calc the metrics (MAP, NDCG...)


import sys


def write_user_ranking(user,items,size_ranking):
    
    s = str(user)+"\t["
    for i in range(size_ranking-1):        
        item,score = items[i]
        s += "%d:%.4f," %(item,score)

    item,score = items[-1]
    s += "%d:%.4f]\n" %(item,score)

    return s
    



'''
test_file : arquivo de teste usado pelo CRF. Este eh o arquivo de teste que foi convertido para o formato esperado pelo CRF
scores_file : arquivo contendo os scores que o CRF atribuiu para cada instancia
out_dir : pasta onde devem ser salvos os rankings gerados a partir dos scores
size_ranking : Tamanho do ranking de saida
partition : particao atual


Salva um arquivo contendo um ranking gerado a partir dos scores atribuidos pelo CRF
'''
def run(test_file_path, scores_file_path, out_dir, size_ranking, partition):


    test_file = open(test_file_path,'r')
    scores_file = open(scores_file_path,'r')



    name_f = partition + "-CRF.out"
    output_f = open(out_dir+name_f,"w")

    qid_past = -1

    crf_ranking = []
    #users = []
    for line_test,line_score in zip(test_file,scores_file):
        
        #nesse momento, as unicas informacoes importantes vindas do tokens_test
        #sao o id do usuario(qid) e o id do item (docid)        
        tokens_test = line_test.strip().split(" ")
        qid = int(tokens_test[1].split(":")[1])
        item = int(tokens_test[tokens_test.index("#docid") + 2])
        score = float(line_score)

        #salva o ranking para o usuario. Ordena os scores e pega os size_ranking 
        #maiores
        if qid_past != qid and qid_past != -1:
            crf_ranking.sort(key = lambda tup : tup[1],reverse=True)
            output_f.write(write_user_ranking(qid_past,crf_ranking,size_ranking))
            crf_ranking = [(item,score)]
            #users.append(qid_past)
        else:
            crf_ranking.append((item,score))

        qid_past = qid


    #dados do ultimo usuario
    crf_ranking.sort(key = lambda tup : tup[1],reverse=True)
    output_f.write(write_user_ranking(qid_past,crf_ranking,size_ranking))

    output_f.close()



if __name__ == "__main__":
    
    test_file = sys.argv[1]
    scores_file = sys.argv[2]
    out_dir = sys.argv[3]
    size_ranking = int(sys.argv[4])
    partition = sys.argv[5]    

    run(test_file,scores_file,out_dir,size_ranking,partition)

    
