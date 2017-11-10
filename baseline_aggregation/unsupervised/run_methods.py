import argparse
import os
import sys
import comb_family as Comb, RRF, MRA, borda_count as BC

def parse_args():
    p = argparse.ArgumentParser()

    p.add_argument('--base_dir',type=str,required=True,
        help = 'folder containg the datasets')
    p.add_argument('-p','--part',type=str,default='u1',
        help='Partition to be used')
    p.add_argument('--base_recs',nargs='*',
        help='Indicate the recommenders containing the recommendations used ' \
        'to construct the group recommendation. When none recommender is set ' \
        'all the recommenders in the base_dir will be used')

    p.add_argument('--base_rec',type=str,
        help='The algorithm currently used in the group recommendation.'
             'Usually is one of the algorithms in args.base_recs')

    p.add_argument('--test_file', type=str,
        help='The file containing the test file. It will be used to construct the oraculus recommendation')

    p.add_argument('--train_file',type=str,
        help='The file containing the training file used by the base recommender')

    p.add_argument('-o','--out_dir',type=str,default='',
        help='Output folder. The group recommendations will be saved in this foder')

    p.add_argument('--i2use',type=int,default=20,
        help='Size of the input rankings')

    p.add_argument('--i2sug',type=int,default=10,
        help='Size of the outrput rankings')

    p.add_argument('--alg', nargs='*',
        help="Algorithms to be used to aggregate the rankings. Valid algorithms " \
        "are Borda, RRF, MRA, CombSUM, CombMNZ, CombMED, CombMIN, CombMAX" )


    parsed = p.parse_args()
    #ipdb.set_trace()
    if parsed.out_dir == '':
        parsed.out_dir = parsed.base_dir

    #base_rec_path = parsed.part + "-" + parsed.base_rec + ".out"
    #parsed.base_rec = os.path.join(parsed.base_dir,base_rec_path)

    parsed.test_file = os.path.join(parsed.base_dir,parsed.part+'.test')
    parsed.train_file = os.path.join(parsed.base_dir,parsed.part+'.base')

    #we use the same groups for all partitions
    #parsed.groups_file = parsed.groups_file.replace('u1',parsed.part)
     
    if not parsed.base_recs:
        recs_in_dir = set().union([rec[3:-4] for rec in sorted(glob.glob(os.path.join(parsed.base_dir,"*.out")))])
        parsed.base_recs = list(recs_in_dir)    
	        


    return parsed



if __name__ == "__main__":
