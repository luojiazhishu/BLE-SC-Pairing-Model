#!/usr/bin/python

import requests, json, sys, os
from bs4 import BeautifulSoup

def select_file(prefix, filename):
    """
    Para:
        prefix: localhost and port where tamarin runs.
        filename: xxx.spthy, the spthy we are proving now.
    Return:
        file_link. the link to the file we want (correspond to xxx.spthy and Original.)
    """
    print("filename: " + filename)
    r = requests.get(prefix)
    soup = BeautifulSoup(r.text, 'html.parser')
    files = soup.find_all('tr')
    for file in files:
        if list(file.children)[2].text == 'Original' \
                and list(file.children)[3].text.split('/')[-1] == filename:
            return file.a['href']

def select_lemmas(prefix, link):
    """
    Para:
        prefix: localhost and port where tamarin runs.
        link: link to the file we are proving.
    Return:
        A list saving all the links to the corresponding lemmas.
    """
    r = requests.get(prefix + link)     # Enter the file's page.
    soup = BeautifulSoup(r.text, 'html.parser')
    sorries = soup.find_all(class_ = 'internal-link proof-step sorry-step')
    return [ sorry['href'] for sorry in sorries ]


def find_traces(prefix, link):
    """
    Para:
        prefix: localhost and port where tamarin runs.
        link: link to the file we are proving.
    Return:
        A list saving all the links to the "SOLVED // trace found" line
    """
    r = requests.get(prefix + link)
    soup = BeautifulSoup(r.text, 'html.parser')
    spans = soup.find_all('span')
    
    try:
        trace_links1 = [span.parent['href'] for span in spans if span.text == 'SOLVED']
    except KeyError:
        print("SOLVED: invalid proof step encounterd")
        trace_links1 = []

    try: 
        trace_links2 = [span.parent['href'] for span in spans if span.text == '/* invalid proof step encountered */']
    except KeyError:
        print("Perhaps no invalid proof steps?")
        trace_links2 = []

    return trace_links1 + trace_links2

    
        
def get_graph(prefix, link):
    """
    Para:
        prefix: localhost and port where tamarin runs.
        link: link to the lemma (sorry)
    Return:
        A list containing all the links to the corresponding graphs
    """
    r = requests.get(prefix + link)
    # return json by clicking sorry
    soup = BeautifulSoup(r.json().get('html'), 'html.parser')
    autoprove = soup.find(class_ = 'internal-link autoprove')
    auto_link = autoprove['href']
    proof = requests.get(prefix + auto_link)
    # return json (containing a redirect link) by clicking autoprove
    proof_link = proof.json().get('redirect')
    proof_req = requests.get(prefix + proof_link)
    proof_soup = BeautifulSoup(proof_req.text, 'html.parser')
    graphs = proof_soup.find_all(class_ = 'graph')
    return [ graph['src'] for graph in graphs ]

def get_graph_interactive(prefix, link):
    """
    Used in Tamarin interactive mode.
    Para:
        prefix: localhost and port where tamarin runs.
        link: link to the SOLVED.
    Return:
        A list containing all the links to the corresponding graphs
    """
    r = requests.get(prefix + link)
    soup = BeautifulSoup(r.json().get('html'), 'html.parser')
    graphs = soup.find_all('img')
    return [ graph['src'] for graph in graphs ]
        

def save_graph(prefix, link, path):
    """
    Para:
        prefix: localhost and port where tamarin runs.
        link: link to the graph
        path: where to save the graph
    Return:
        None. The graph will be saved to proper place named by lemma's name.
    """
    print("Graph: " + link)
    graph_name = link.split('/')[6]
    graph_req = requests.get(prefix + link)
    # TODO: save the .svg in ./Results/proofs/src/$FILENAME/$LEMMANAME.svg
    if not os.path.exists(path):
        os.makedirs(path)
    with open(path + graph_name + '.svg', 'wb') as graph_file:
        for chunk in graph_req.iter_content(100000):
            graph_file.write(chunk)


if __name__ == "__main__":
    url_prefix = 'http://127.0.0.1:3001' 

    # A system parameter is needed.
    try:
        path = sys.argv[1]
    except IndexError:
        path = input("Which file do you want to analysis? (relative path is needed)\n")

    # TODO:
    # if path.split has 'tmp':
    #     save_path = ....
    # else:
    #     save_path = ....
    file_name = path.split('/')[-1]
    folder = os.path.dirname(path)
    if folder.split('/')[-1] == 'tmp':
        folder = os.path.dirname(folder)

    save_path = folder + '/src/' + file_name.split('.')[0] + '/'

    print("File: " + file_name)
    print("save_path: " + save_path)

    file_link = select_file(url_prefix, file_name)

    # # No intermediate results.
    # sorry_links = select_lemmas(url_prefix, file_link)
    # for sorry_link in sorry_links:
    #     print("lemma: " + sorry_link)
    #     graph_links = get_graph(url_prefix, sorry_link)

    #     if graph_links == []:
    #         print("This lemma has no paths")
    #     else:
    #         for graph_link in graph_links:    
    #             # Only one graph in graphs actually 
    #             save_graph(url_prefix, file_name, graph_link)


    # Use intermediate results.
    trace_links = find_traces(url_prefix, file_link)
    for trace_link in trace_links:
        graph_links = get_graph_interactive(url_prefix, trace_link)

        if graph_links == []:
            print("This lemma has no paths")
        else:
            for graph_link in graph_links:    
                # Only one graph in graphs actually 
                save_graph(url_prefix,graph_link,save_path)
