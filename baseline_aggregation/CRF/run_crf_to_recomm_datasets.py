'''Esse script vai seguir os seguintes passos
1)converter as bases de recomendacao no formato esperado pelo CRF
2)Fazer a leitura desses datasets convertidos utilizando a funcao read_from_txt
3) rodar o CRF e salvar os scores atribuidos por ele para cada uma das instancias
4) utilizar os scores gerados pelo CRF para criar um arquivo de saida com os 
rankings correspondentes
'''

import sys
import os
import calc_metrics
import rankings_to_seach_dataset
import create_ranking_crf

def convert_recomm_to_search_format(basedir,partition,size_input_ranking,
                                    which,output_folder_fold):


    print output_folder_fold
    #output_folder_fold = output_folder + partition+ "/"
    if which == "validation":
        rankings_to_seach_dataset.run(basedir,partition,size_input_ranking,which,output_folder_fold)
        os.system("cp " + output_folder_fold+which+".txt "+output_folder_fold+"train.txt")
    else:
        basedir += "reeval/"
        rankings_to_seach_dataset.run(basedir,partition,size_input_ranking,which,output_folder_fold)


    

if __name__ == "__main__":


    basedir = sys.argv[1]

    size_input_ranking = int(sys.argv[2])

    output_folder = sys.argv[3]
    
    max_crf_iter = 200


    if not os.path.isdir(output_folder):
        os.mkdir(output_folder)
        #os.mkdir(output_folder+partition)

    #else:
    
    for which in ["test","validation"]:
        for part in range(1,6):
            
            partition = "u" + str(part)

            #if not os.path.isdir(output_folder+partition):
            output_folder_fold = os.path.join(output_folder,"Fold"+str(part),"")
            #os.mkdir(output_folder+"Fold"+str(part))

            convert_recomm_to_search_format(basedir,partition,size_input_ranking,which,output_folder_fold)
    
    

    os.system("octave learn_crf_aggr.m "+output_folder + " " + str(max_crf_iter))

    if not os.path.isdir(output_folder+"CRF_rankings"):
        os.mkdir(output_folder+"CRF_rankings")

    for part in range(1,6):
        partition = "u"+str(part)

        create_ranking_crf.run(output_folder+"Fold"+str(part)+"/test.txt", 
                                output_folder+"Fold"+str(part)+"/crf_scores",
                                output_folder+"CRF_rankings/", size_input_ranking,
                                partition)

    
    os.system("cp "+basedir+output_folder+"*.test "+ basedir+output_folder+"CRF_rankings/" )
    calc_metrics.run(output_folder+"CRF_rankings/")
    


    
    



