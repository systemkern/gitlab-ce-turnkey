import requests
import json
import os


user = "root"
pwd = os.environ['GITLAB_ROOT_PASSWORD']

gitlab_external_url = os.environ['GITLAB_ROOT_URL']
login_url=gitlab_external_url+"/oauth/token"


loginRequest = {
    "grant_type" : "password",
    "username": user,
    "password" : pwd,
}
raw_response = requests.post(login_url, data = loginRequest)
if raw_response.status_code != 200:
    print("Login to "+gitlab_external_url+" failed with status code:"+str(raw_response.status_code))
    print(raw_response.text)
    exit(1)

response = json.loads(raw_response.text)
# expecting {
#   "access_token" : "",
#   "refresh_token" : "",
#   "token_type" : "",
#   "created_at" : "",
# }

assert response.get("access_token") is not None

print("Smoke test successful")
