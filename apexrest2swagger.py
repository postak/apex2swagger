#!/usr/bin/python
import sys
import os
import os.path
import re


import sys, getopt

def main(argv):

    fdin = sys.stdin
    fdout = sys.stdout
    title = "this is the title"
    description = "this is the description"
    host = "localhost"
    port = 8080

    try:
        opts, args = getopt.getopt(argv,"?h:p:t:d:i:o:",["ifile=","ofile=","help","description=","port=","host=","title="])
    except getopt.GetoptError:
        print 'apexrest2swagger.py -i <inputfile> -o <outputfile>'
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-?", "--help"):
            print 'apexrest2swagger.py -i <inputfile> -o <outputfile>'
            sys.exit()
        elif opt in ("-i", "--ifile"):
            if not os.path.isfile(arg) or not os.access(arg, os.R_OK):
                print  "Either file is missing or is not readable"
                sys.exit(2)
            fdin = open(arg, "r+")
        elif opt in ("-o", "--ofile"):
	        fdout = open(arg, "w+")
        elif opt in ("-t", "--title"):
	        title = arg
        elif opt in ("-d", "--description"):
	        description = arg
        elif opt in ("-h", "--host"):
	        host = arg
        elif opt in ("-p", "--port"):
	        port = arg


    text = fdin.read()

    print >> fdout,  "swagger: '2.0'"
    print >> fdout,  "info:"
    print >> fdout,  "  title: " + title
    print >> fdout,  "  description: " + description
    print >> fdout,  "  version: \"1.0.0\""
    print >> fdout,  "# the domain of the service"
    if (port != 80):
        print >> fdout,  "host: %s:%d" % ( host , port )
    else:
        print >> fdout,  "host: %s"

    print >> fdout,  "basePath: /v1"
    print >> fdout,  "schemes:"
    print >> fdout,  "  - http"
    print >> fdout,  "  - https"
    print >> fdout,  "consumes:"
    print >> fdout,  "  - application/json"
    print >> fdout,  "produces:"
    print >> fdout,  "  - application/json"
    print >> fdout,  "paths:"

    target = '.*p_uri_.*'
    tokens = text.split() # split on whitespace
    keyword = re.compile(target, re.IGNORECASE)

    for index in range( len(tokens) ):
        if re.search( 'p_uri_prefix', tokens[index] ):
            prefix = estract_value (tokens[index])
        elif re.search( 'p_uri_template', tokens[index] ):
            template = estract_value (tokens[index])
        elif re.search( 'p_method', tokens[index] ):
            method = estract_value (tokens[index])
            print >> fdout,  "  /%s%s:" % ( prefix, template )
            print >> fdout,  "    %s:" % ( method.lower() )

            if ( re.search ( '{' , template) ):
                p = template.split ('/')
                param = p[len(p) - 1].strip ('{}')
                print >> fdout,  "      parameters: "
                print >> fdout,  "        - name: " + param
                print >> fdout,  "          in: path"
                print >> fdout,  "          type: string"
                print >> fdout,  "          description: this is the description"
                print >> fdout,  "          required: true"

            elif ( method.lower() == "post" ):
                print >> fdout,  "      parameters: "
                print >> fdout,  "        - name: record"
                print >> fdout,  "          in: body"
                print >> fdout,  "          description: the JSON record to insert"
                print >> fdout,  "          schema:"
                print >> fdout,  "            type: object"
                print >> fdout,  "          required: true"

            print >> fdout,  "      responses: "
            print >> fdout,  "        200: "
            print >> fdout,  "          description: An array of products"



def estract_value(token):
    v = token.split ('=>')
    if len(v) > 1:
        return (v[1].strip('\t\n\r \'\"'))


if __name__ == "__main__":
   main(sys.argv[1:])
