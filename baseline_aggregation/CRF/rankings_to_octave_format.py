'''this script converts a set of rank files (in My Media Lite format) to a 
single file in the same format used by the MQXXXX-agg datasets.

Input:
A set of rankings in the following format
<user_id>: [<item_id>:score,<item_id>:score,...,<item_id>:score]

Output:
A single file merging all the rankings to the following format

target qid:<user_id> <ranker_id>:<item_id_pos> ... <ranker_id>:<item_id_pos> #docid = <doc_id> inc = <ind> prob = <prob>
target qid:<user_id> <ranker_id>:<item_id_pos> ... <ranker_id>:<item_id_pos> #docid = <doc_id> inc = <ind> prob = <prob>
target qid:<user_id> <ranker_id>:<item_id_pos> ... <ranker_id>:<item_id_pos> #docid = <doc_id> inc = <ind> prob = <prob>

It means that each line represents a pair <usr,item> and the positions that 
the given item appears in each of the baseline rankings. If an item does not 
appear in a specific ranking it receives the value NULL for this ranking

0 qid:435 1:NULL 2:3 3:20 4:NULL 5:NULL 6:NULL #docid = 6543 inc = 1 prob = 1

Usage:

python rankings_to_search_dataset <basedir> <output_dir> <partition> <rank_size> <val or test>

'''



import sys
import os
import glob
import numpy as np
import time
import ipdb
import random




def call_system(cmd,tmpfile=None):
    
    tmpfile = "tmp_{0}".format(str(random.randint(0,1000)))
    
    os.system("{0} > {1}".format(cmd,tmpfile))
    content = open(tmpfile,'r').readlines()
    os.system("rm "+tmpfile)
    
    return content



def read_data_ml(inputf):
    data = open(inputf,'r')
        
    user_items = {}
    past_usr,past_mov,past_rat = data.readline().strip().split('\t')
    user_items[int(past_usr)] = [int(past_mov)]
    #movies_freq[int(past_mov)] = 1

    line_usr = past_mov
    #nratings = 1
    nusers = 1;
    for line in data:
        usr,mov,rat = line.strip().split('\t')
   
        #creating user line
        if usr == past_usr:
            user_items[int(usr)].append(int(mov))
            #line_usr += ' '+mov
            past_usr,past_mov = usr,mov
        else:
            user_items[int(usr)] = [int(mov)]
            nusers += 1
            past_usr,past_mov = usr,mov


    return user_items

"""
Receives:
user_id : The user id
positions: User item map
basedir: directory where the test/validation file is located
which : a flag for test/validation

returns:
data_str : A string containing the positions of each item recommended to user_id
in each input ranking (along with its metadata)
target_str : A string containing the labels/relevance of the items recommended 
to user_id (along with its metadata)

"""
def converto_to_MQ_format(user_id,positions,basedir,partition,data_target,which="test"):
    

    #since all the itens has the same number of rankers 
    #take the first item in the dict in order to count the number of rankers

    num_rankings = len(positions[list(positions.keys())[0]])

    data_str = "#name: <cell-element>\n# type: matrix\n" \
                +"# rows: {0}\n# columns: {1}\n".format(len(positions),num_rankings)

    labels_str = "#name: <cell-element>\n# type: matrix\n" \
                "# rows: {0}\n# columns: 1\n".format(len(positions))


    map_str = ""

    straux = ""
    #data_target = read_data_ml(basedir+partition+"."+which)

    for key in positions.keys():
        target_value = 0

        if user_id in data_target:
            if key in data_target[user_id]:
                labels_str += "1\n"
                map_str += "1 qid:{0} #docid = {1}\n".format(user_id,key)
            else:
                labels_str += "0\n"
                map_str += "0 qid:{0} #docid = {1}\n".format(user_id,key)
                #target_value = 1 #REMOVER

        #straux += "%d qid:%s " %(target_value,user_id) REMOVER

        rankings_pos = positions[key]
        data_str += " ".join([str(x) for x in positions[key]])
        data_str += "\n"

        #for pos in range(len(rankings_pos)-1):
        #    item_pos = str(int(rankings_pos[pos])) if rankings_pos[pos] > 0 else "NULL"
        #    straux += "%d:%s " %(pos+1,item_pos)
        #item_pos = str(int(rankings_pos[pos])) if rankings_pos[-1] > 0 else "NULL"
        #straux += "%d:%s " %(len(rankings_pos),item_pos)    
        #straux += "#docid = %d inc = 0.0 prob = 0.0\n" %(key)
        
    #ipdb.set_trace()
    return data_str, labels_str, map_str
         



def run(basedir,partition,size_input_ranking,which,output_dir):

    if not os.path.isdir(output_dir):
        os.mkdir(output_dir)


    if "test" in which:
        if not "reeval" in basedir:
            basedir = os.path.join(basedir,"reeval/")



    output_f = open(output_dir+which+".txt","w")
    output_x = open(output_dir+which+".x","w")
    output_y = open(output_dir+which+".y","w")
    output_map = open(output_dir+which+".map","w")


    files_path = sorted(glob.glob(basedir+partition+"*.out"))
    #ipdb.set_trace()
    #pega o numero de usuarios contando as linhas de algum dos arquivos de entrada
    num_users = call_system("wc -l {0}".format(files_path[0]))[0].split(" ")[0] #TODO filtrar
    num_users = int(num_users)


    header = "# name: {0}_{1}\n# type: cell\n# rows: {2}\n# columns: 1\n"
    output_x.write(header.format(which,"data",num_users))
    output_y.write(header.format(which,"targets",num_users))



    files = []
    for f in files_path:
        files.append(open(f))
    end_files = False
    user = -1

    str_aux = ""
    data_target = read_data_ml(basedir+partition+"."+which)

    while True:
        #print user    
        user_item_map = {}
        user = -1

        #passa por cada um dos rankings de entrada e armazena os items 
        #recomendados para cada usuario bem como a posicao desses items nos 
        #rankings
        tini = time.time()
        for rank_id in range(len(files)):
            #print(files[rank_id])
            #ipdb.set_trace()
            try:
                line = files[rank_id].readline()
                user,tokens = line.strip().split("\t")
                user = int(user)
                tokens = tokens.replace("[","").replace("]","").split(",")
                #pega a quantidade de itens definida pelo parametro size_input_rankings
                for item_pos in range(size_input_ranking):
                    #print "I pos: " + str(item_pos)
                    item,score = tokens[item_pos].split(":") #separa item id do score
                    item = int(item)
                    #atribui a posicao de cada item nos respectivos rankings
                    if not item in user_item_map:
                        user_item_map[item] = np.zeros(len(files),dtype=int)
                        #soma +1 para diferenciar dos items faltantes 
                        #(que ficarao com o valor 0 e serao trocados por NULL
                        user_item_map[item][rank_id] = item_pos+1
                    else:
                        user_item_map[item][rank_id] = item_pos+1
            except :
                end_files = True
                break
        #print("REad -> "+ str(time.time()-tini))
        if not end_files:
            #ipdb.set_trace()
            #str_aux += converto_to_MQ_format(user,user_item_map,basedir,partition,which) + "\n"
            tini2 = time.time()
            data_str, label_str, map_str = converto_to_MQ_format(user,
                                            user_item_map,basedir,partition,
                                            data_target,which)            
            #print("Conversion -> "+str(time.time()-tini2))

            tini3 = time.time()
            output_x.write(data_str)
            output_y.write(label_str)
            output_map.write(map_str)
            #print("Write -> " + str(time.time()-tini3))
            num_users += 1
            #ipdb.set_trace()
            #output_f.write(converto_to_MQ_format(user,user_item_map,basedir,partition,which))
        else:
            break
        

    #output_f.write(str_aux)    
    output_x.close()
    output_y.close()
    output_f.close()


if __name__ == "__main__":
    
    
    basedir = sys.argv[1] #"./"
    partition = sys.argv[2]

    size_input_ranking = int(sys.argv[3]) #10
    output_dir = sys.argv[4]
    which = sys.argv[5]
    total_time = time.time()
    run(basedir,partition,size_input_ranking,which,output_dir)
    total_time = time.time() - total_time
    print("Total Time : " + str(total_time))

