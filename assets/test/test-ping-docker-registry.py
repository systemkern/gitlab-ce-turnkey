import requests
import json
import os


#gitlab_external_url = os.environ['GITLAB_ROOT_URL']
#docker_registry_external_url = os.environ['DOCKER_REGISTRY_EXTERNAL_URL']
docker_registry_external_url = "http://localhost:5050"
ping_url=docker_registry_external_url+"/v2"


raw_response = requests.get(ping_url)
if raw_response.status_code != 200:
    print("Get request to "+ping_url+" failed with status code:"+str(raw_response.status_code))
    print(raw_response.text)
    exit(1)

print(raw_response.text)
