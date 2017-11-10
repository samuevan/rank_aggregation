"""The methods in this file implements the Comb* family of rank aggregation 
methods.
These functions receives a set of rankings (can be a list or a dict) and returns
a ranking in the form [(item1,score1),(item2,score2)...(itemN,scoreN)]

If the input rankings have scores you should remove them using the function 
remove_scores in the utils.py file

"""




def score_function(item_pos,rank_size):
    res = 1 -  float(item_pos)/rank_size
    return res
    

#Encapsular todos os Combs em uma funcao

def CombSUM(rankings):
    scores = {}

    if isinstance(rankings,dict):
        rankings_to_agg = list(rankings.values())
    else:
        rankings_to_agg = rankings

    for rank in rankings_to_agg:
        for pos,elem in enumerate(rank):
            if elem in scores :
                scores[elem] += score_function(pos,len(rank))#1 -  float(pos)/len(rank)
            else:
                scores[elem] = score_function(pos,len(rank))

    final_rank = [(x,y) for x,y in sorted(scores.items(), key = lambda tup : tup[1],reverse=True)]

    return final_rank


def CombMIN(rankings):
    scores = {}
    if isinstance(rankings,dict):
        rankings_to_agg = list(rankings.values())
    else:
        rankings_to_agg = rankings

    for rank in rankings_to_agg:
        for pos,elem in enumerate(rank):
            if elem in scores :
                scores[elem] = min(score_function(pos,len(rank)),scores[elem])#1 -  float(pos)/len(rank)
            else:
                scores[elem] = score_function(pos,len(rank))
    final_rank = [(x,y) for x,y in sorted(scores.items(), key = lambda tup : tup[1],reverse=True)]
    return final_rank


def CombMAX(rankings):
    scores = {}
    if isinstance(rankings,dict):
        rankings_to_agg = list(rankings.values())
    else:
        rankings_to_agg = rankings

    for rank in rankings_to_agg:
        for pos,elem in enumerate(rank):
            if elem in scores :
                scores[elem] = max(score_function(pos,len(rank)),scores[elem])#1 -  float(pos)/len(rank)
            else:
                scores[elem] = score_function(pos,len(rank))
    final_rank = [(x,y) for x,y in sorted(scores.items(), key = lambda tup : tup[1],reverse=True)]
    return final_rank

def CombMED(rankings):
    scores = {}
    if isinstance(rankings,dict):
        rankings_to_agg = list(rankings.values())
    else:
        rankings_to_agg = rankings

    for rank in rankings_to_agg:
        for pos,elem in enumerate(rank):
            if elem in scores :
                scores[elem] += score_function(pos,len(rank))/len(rankings)
            else:
                scores[elem] = score_function(pos,len(rank))/len(rankings)
    final_rank = [(x,y) for x,y in sorted(scores.items(), key = lambda tup : tup[1],reverse=True)]
    return final_rank

def CombANZ(rankings):
    scores = {}
    countings = {} #counts how many times the items apepars in the rankings

    if isinstance(rankings,dict):
        rankings_to_agg = list(rankings.values())
    else:
        rankings_to_agg = rankings

    for rank in rankings_to_agg:
        for pos,elem in enumerate(rank):
            if elem in scores :
                scores[elem] += score_function(pos,len(rank))/len(rankings)
                countings[elem] += 1
            else:
                scores[elem] = score_function(pos,len(rank))/len(rankings)
                countings[elem] = 1

    for key in scores:
        scores[key] = scores[key]/countings[key]

    final_rank = [(x,y) for x,y in sorted(scores.items(), key = lambda tup : tup[1],reverse=True)]
    return final_rank


def CombMNZ(rankings):
    scores = {}
    countings = {} #counts how many times the items apepars in the rankings
    if isinstance(rankings,dict):
        rankings_to_agg = list(rankings.values())
    else:
        rankings_to_agg = rankings

    for rank in rankings_to_agg:
        for pos,elem in enumerate(rank):
            if elem in scores :
                scores[elem] += score_function(pos,len(rank))/len(rankings)
                countings[elem] += 1
            else:
                scores[elem] = score_function(pos,len(rank))/len(rankings)
                countings[elem] = 1
    for key in scores:
        scores[key] = scores[key]*countings[key]

    final_rank = [(x,y) for x,y in sorted(scores.items(), key = lambda tup : tup[1],reverse=True)]
    return final_rank


