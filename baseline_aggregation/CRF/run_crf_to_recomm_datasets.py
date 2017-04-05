'''Esse script vai seguir os seguintes passos
1)converter as bases de recomendacao no formato esperado pelo CRF
2)Fazer a leitura desses datasets convertidos utilizando a funcao read_from_txt
3) rodar o CRF e salvar os scores atribuidos por ele para cada uma das instancias
4) utilizar os scores gerados pelo CRF para criar um arquivo de saida com os 
rankings correspondentes
'''

import sys
import os
#import calc_metrics
import rankings_to_seach_dataset
import rankings_to_octave_format
import create_ranking_crf
import argparse
import ipdb






def parse_args():

    p = argparse.ArgumentParser()

    p.add_argument("basedir",type=str,
        help="Folder containing the rankings to be converted to CRF format")
    p.add_argument("--i2use",type=int,default=20,
        help="Size of the input rankings")
    p.add_argument("--i2sug",type=int,default=10,
        help="Size of the aggregated rankings")
    p.add_argument("-o","--out_dir",type=str,
        help="Folder to save the aggregated rankings")
    p.add_argument("--pini",type=int,default=1)
    p.add_argument("--pend",type=int,default=5)
    p.add_argument("--crf_iter",type=int,default=200)

    return p.parse_args()


def convert_recomm_to_octave_format(basedir,partition,size_input_ranking,
                                    which,output_folder_fold):

    print(output_folder_fold)
    #output_folder_fold = output_folder + partition+ "/"
    if which == "validation":
        rankings_to_octave_format.run(basedir,partition,size_input_ranking,which,output_folder_fold)
        os.system("cp " + output_folder_fold+which+".x " +output_folder_fold+"train.x")
        os.system("cp " + output_folder_fold+which+".y " +output_folder_fold+"train.y")
        os.system("sed -i '0,/validation/{s/validation/train/}' "+output_folder_fold+"train.x")
        os.system("sed -i '0,/validation/{s/validation/train/}' "+output_folder_fold+"train.y")
        os.system("cp " + output_folder_fold+which+".map " +output_folder_fold+"train.map")
    else:
        basedir += "reeval/"
        rankings_to_octave_format.run(basedir,partition,size_input_ranking,which,output_folder_fold)



def convert_recomm_to_search_format(basedir,partition,size_input_ranking,
                                    which,output_folder_fold):


    print(output_folder_fold)
    #output_folder_fold = output_folder + partition+ "/"
    if which == "validation":
        rankings_to_seach_dataset.run(basedir,partition,size_input_ranking,which,output_folder_fold)
        os.system("cp " + output_folder_fold+which+".txt "+output_folder_fold+"train.txt")
    else:
        basedir += "reeval/"
        rankings_to_seach_dataset.run(basedir,partition,size_input_ranking,which,output_folder_fold)


    

if __name__ == "__main__":

    octave_format = True

    args = parse_args()

    '''basedir = ""
    if len(sys.argv) > 3:
        basedir = sys.argv[1]
        size_input_ranking = int(sys.argv[2])
        output_folder = sys.argv[3]
    else:
        output_folder = sys.argv[1]
        size_input_ranking = int(sys.argv[2])
        
    max_crf_iter = 10'''


    if not os.path.isdir(args.out_dir):
        os.mkdir(args.out_dir)
        #os.mkdir(output_folder+partition)

    #else:
    if args.basedir:    

        for part in range(args.pini,args.pend+1):
            for which in ["test","validation"]:                
                partition = "u" + str(part)

                #if not os.path.isdir(output_folder+partition):
                output_folder_fold = os.path.join(args.out_dir,"Fold"+str(part),"")
                #os.mkdir(output_folder+"Fold"+str(part))

                
                if octave_format:
                    convert_recomm_to_octave_format(args.basedir,
                        partition,args.i2use,which,output_folder_fold)
                else:
                    convert_recomm_to_search_format(args.basedir,partition,
                        args.i2use,which,output_folder_fold)
    
    


    crf_cmd = "octave learn_crf_aggr2.m {out_dir} {crf_iter} {pini} {pend}"
    #os.system("octave learn_crf_aggr2.m "+output_folder + " " + str(max_crf_iter) + " 1 5")
    print(crf_cmd.format(**args.__dict__))
    #ipdb.set_trace()
    os.system(crf_cmd.format(**args.__dict__))

    if not os.path.isdir(os.path.join(args.out_dir+"CRF_rankings")):
        os.mkdir(os.path.join(args.out_dir+"CRF_rankings"))

    for part in range(args.pini,args.pend+1):
        partition = "u"+str(part)
        print("CACETA")
        create_ranking_crf.run(args.out_dir+"Fold"+str(part)+"/test.map", 
                                args.out_dir+"Fold"+str(part)+"/crf_scores",
                                args.out_dir+"CRF_rankings/", args.i2sug,
                                partition)

    
    #os.system("cp "+basedir+output_folder+"*.test "+ basedir+output_folder+"CRF_rankings/" )
    #calc_metrics.run(output_folder+"CRF_rankings/")
    


    
    



