#!/usr/bin/python3
import sys
import logging

# Log to stderr?
logging.basicConfig(stream=sys.stderr)

# Set working directory so the gnucash_rest and gnucash_simple modules can be found
sys.path.insert(0,"/var/www/gnucash-rest")
sys.path.insert(0,"/var/www/gnucash-rest/gnucash_rest")

# Load application via 
from gnucash_rest import app as application

# Set variables
application.connection_string = '/gnucash.gnucash'

