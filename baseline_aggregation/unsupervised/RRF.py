def RRF_func(pos,k):
    return 1.0/(k+pos)


'''
Receives a set of rankings and return an aggregated rankings in the form
[(item1,score1),(item2,score2)...(itemN,scoreN)]
'''
def RRF_comb(rankings,k=60):
    scores = {}
    counting = {} #counts how many times the items apepars in the rankings
    if isinstance(rankings,dict):
        rankings_to_agg = list(rankings.values())
    else:
        rankings_to_agg = rankings

    for rank in rankings_to_agg:
        for pos,elem in enumerate(rank):
            if elem in scores :
                scores[elem] += RRF_func(pos,k)
            else:
                scores[elem] = RRF_func(pos,k)

    final_rank = [(x,y) for x,y in sorted(scores.items(), key = lambda tup : tup[1],reverse=True)]
    return final_rank
