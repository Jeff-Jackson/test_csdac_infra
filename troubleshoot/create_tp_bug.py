import requests
import json
import xml.etree.ElementTree as ET
import sys


def find_existing_bug(api_url, api_token, bug_details):
    search_endpoint = f"{api_url}/Bugs?access_token={api_token}"
    headers = {
        "Content-Type": "application/json",
    }
    query = {
        "where": f"(Name eq '{bug_details['Name']}') and (Project.Id eq {bug_details['Project']['Id']}) and (Team.Id eq {bug_details['Team']['Id']})"
    }
    response = requests.get(search_endpoint, headers=headers, params=query)

    if response.status_code == 200:
        try:
            root = ET.fromstring(response.text)
            for bug in root.findall('Bug'):
                bug_id = bug.attrib.get('Id')
                bug_url = f"https://targetprocess.cisco.com/RestUI/Board.aspx#page=board/5705303923866084483&appConfig=eyJhY2lkIjoiQjY4MzJDQkRCRkJCMkYzQzBENDQ4NzVEMDc1NUQ2OEIifQ==&searchPopup=bug/{bug_id}"
                return bug_id, bug_url
        except ET.ParseError:
            print("Failed to parse XML response")
    return None, None

def upload_attachment(api_token, file_path, general_id):
    upload_endpoint = f"https://targetprocess.cisco.com/UploadFile.ashx"
    params = {'access_token': api_token}
    data = {'generalid': general_id}

    with open(file_path, 'rb') as f:
        files = {'file': (file_path, f, "multipart/form-data")}
        
        response = requests.post(upload_endpoint, data=data, params=params, files=files)

        if response.status_code == 200:
            return response.text 
        else:
            print("Error uploading file:", response.status_code, response.text)
            return None


def create_bug_in_targetprocess(api_url, api_token, bug_data, file_path=None):
    existing_bug_id, existing_bug_url = find_existing_bug(api_url, api_token, bug_data)

    if existing_bug_id:
        bug_details_url = f"{api_url}/Bugs/{existing_bug_id}?access_token={api_token}"
        response = requests.get(bug_details_url)
        
        if response.status_code == 200:
            try:
                root = ET.fromstring(response.text)
                entity_state = root.find(".//EntityState")
                if entity_state is not None:
                    state_name = entity_state.attrib.get('Name')
                    if state_name != "Done":
                        print(f"Existing bug found with state: {state_name} \nBug ID :{existing_bug_id}\nBug URL : {existing_bug_url}")
                        return existing_bug_id, existing_bug_url
            except ET.ParseError:
                print("Failed to parse XML response")

    endpoint = f"{api_url}/Bugs?access_token={api_token}"
    headers = {
        "Content-Type": "application/json",
    }
    response = requests.post(endpoint, headers=headers, data=json.dumps(bug_data))
    
    if response.status_code == 201:
        try:
            root = ET.fromstring(response.text)
            bug_id = root.attrib.get('Id')
            bug_url = f"https://targetprocess.cisco.com/RestUI/Board.aspx#page=board/5705303923866084483&appConfig=eyJhY2lkIjoiQjY4MzJDQkRCRkJCMkYzQzBENDQ4NzVEMDc1NUQ2OEIifQ==&searchPopup=bug/{bug_id}"
            print("Bug created successfully")
            print(f"BUG ID :{bug_id} \nBUG URL: {bug_url}")
            if file_path:
                upload_attachment(api_token, file_path, bug_id)

            return bug_id, bug_url
        except ET.ParseError:
            print("Failed to parse XML response")
            return None, None
    else:
        print("Failed to create bug")
        print(f"Response Code: {response.status_code}")
        print(f"Response Text: {response.text}")
        return None, None


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: create_tp_bug.py <api_token> <description> <file_path.xxx>")
        sys.exit(1)

    api_token = sys.argv[1]
    description = sys.argv[2]
    file_path = sys.argv[3]
    API_URL = "https://targetprocess.cisco.com/api/v1"
    TEAM_ID = 622137  


    bug_details = {
        "Name": "cdCSDAC - Investigate differences found between cdCSDAC and FMC",
        "Description": description,
        "Project": {"Id": 644669}, 
        "Team": {"Id": TEAM_ID}
    }

    create_bug_in_targetprocess(API_URL, api_token, bug_details, file_path )
