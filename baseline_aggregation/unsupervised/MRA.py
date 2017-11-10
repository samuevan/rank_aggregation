def MRA_comb(rankings,rank_size=10):
    scores = {}
    counting = {} #counts how many times the items apepars in the rankings
    if isinstance(rankings,dict):
        rankings_to_agg = list(rankings.values())
    else:
        rankings_to_agg = rankings

    #pega o tamanho do maior ranking para o caso de rankings de tamanhos diferentes
    input_size = max([len(rankings_to_agg[i]) for i in range(len(rankings_to_agg))])

    final_rank = []
    #percorre os rankings posicao a posicao
    for pos in range(input_size):
        for rank in rankings_to_agg:
            if pos < len(rank): 
                #para cada ranking, conta o numero de vezes que o item na posicao 
                #corrente já apareceu
                elem = rank[pos]
                if elem in scores:
                    scores[elem] += 1
                    #caso o item tenha aparecido em mais de metada dos 
                    #rankings (median) ele eh adicionado no ranking final 
                    #e removido do dicionario de controle
                    if scores[elem] >= (len(rankings)/2):
                        final_rank.append((elem,scores[elem]))
                        scores.pop(elem)
                elif not elem in final_rank:
                    scores[elem] = 1
    
    #caso nao tenha preenchido o total de items necessarios para o tamanho do
    #raking de saida, adiciona os items ordenados pela frequencia dos mesmos nos
    #rankings de entrada. Note que essa frequencia pode ser inclusive maior que 
    #a mediana, mas o que importa no metodo eh o intante em que um item alcanca 
    #a mediana das contagems
    if len(final_rank) < rank_size:
        scores = sorted(list(scores.items()), key = lambda tup : tup[1], reverse = True)
        pos = 0     
        while len(final_rank) < rank_size and pos < len(scores):    
            final_rank.append(scores[pos])
            pos += 1

    return final_rank
