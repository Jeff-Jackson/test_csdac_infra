import requests
import sys
import os

def send_report(access_token, room_id, file_name, message):
    if not os.path.isfile(file_name):
        print(f"Error: File '{file_name}' not found.")
        sys.exit(1)

    with open(file_name, 'rb') as file:
        files = {'files': file}
        url = 'https://webexapis.com/v1/messages'
        headers = {
            'Authorization': f'Bearer {access_token}'
        }
        data = {
            'roomId': room_id,
            'text': message
        }

        try:
            response = requests.post(url, headers=headers, data=data, files=files)
            print(f"Response Status Code: {response.status_code}")
            print(f"Response Content: {response.content}")
            response.raise_for_status()
        except requests.exceptions.RequestException as e:
            print("Error: Failed to send the message!")
            print(f"Details: {e}")
            sys.exit(1)

        print("Message sent successfully!")

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python send_report.py <access_token> <room_id> <file_name> <message>")
        sys.exit(1)

    access_token = sys.argv[1]
    room_id = sys.argv[2]
    file_name = sys.argv[3]
    message = sys.argv[4]

    send_report(access_token, room_id, file_name, message)