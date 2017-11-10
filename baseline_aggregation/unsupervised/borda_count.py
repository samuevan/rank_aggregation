

def BordaCount(rankings):

    if isinstance(rankings,dict):
        rankings_to_agg = list(rankings.values())
    else:
        rankings_to_agg = rankings

    borda_scores = {}

    for rank in rankings:
        for item_pos,item in enumerate(rank):
            item_id = item
            if item_id in borda_scores:
                borda_scores[item_id] += len(rank)-item_pos
            else:
                borda_scores[item_id] = len(rank)-item_pos


    final_ranking = [(item,borda_scores[item]) for item in borda_scores]
    final_ranking = sorted(final_ranking,key = lambda tup : tup[1], reverse = True)

    return final_ranking

