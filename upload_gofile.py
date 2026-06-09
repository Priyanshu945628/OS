import urllib.request
import json
import os
import sys
import subprocess

# 1. Get the ISO file
out_dir = "out"
if not os.path.exists(out_dir):
    os.makedirs(out_dir)

iso_files = [f for f in os.listdir(out_dir) if f.endswith(".iso")]
if not iso_files:
    print("Error: No ISO file found in out/")
    sys.exit(1)
iso_path = os.path.join(out_dir, iso_files[0])
print(f"Found ISO file: {iso_path}")

# 2. Get server
print("Fetching Gofile server...")
try:
    req = urllib.request.Request("https://api.gofile.io/servers", headers={"User-Agent": "Mozilla/5.0"})
    res = urllib.request.urlopen(req)
    servers_data = json.loads(res.read().decode('utf-8'))
    server = servers_data['data']['servers'][0]['name']
    print(f"Using Gofile server: {server}")
except Exception as e:
    print(f"Failed to fetch server: {e}")
    sys.exit(1)

# 3. Upload file using curl
upload_url = f"https://{server}.gofile.io/uploadFile"
print(f"Uploading to {upload_url}...")
cmd = ["curl", "-s", "-H", "User-Agent: Mozilla/5.0", "-F", f"file=@{iso_path}", upload_url]
p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
stdout, stderr = p.communicate()
if p.returncode != 0:
    print(f"Upload failed: {stderr}")
    sys.exit(1)

try:
    upload_res = json.loads(stdout)
except Exception as e:
    print(f"Failed to parse upload response: {stdout}")
    sys.exit(1)

if upload_res.get('status') != 'ok':
    print(f"Upload error: {upload_res}")
    sys.exit(1)

data = upload_res['data']
guest_token = data['guestToken']
parent_folder = data['parentFolder']
download_page = data['downloadPage']

print(f"Upload successful!")
print(f"Download Page: {download_page}")
print(f"Guest Token: {guest_token}")
print(f"Parent Folder ID: {parent_folder}")

# 4. Fetch the folder contents to retrieve the direct download link
print("Retrieving folder contents to get direct download link...")
contents_url = f"https://api.gofile.io/contents/{parent_folder}"
req_contents = urllib.request.Request(
    contents_url,
    headers={"User-Agent": "Mozilla/5.0", "Authorization": f"Bearer {guest_token}"}
)
try:
    res_contents = urllib.request.urlopen(req_contents)
    contents_data = json.loads(res_contents.read().decode('utf-8'))
    print("Folder Contents API Response:")
    print(json.dumps(contents_data, indent=2))
    
    # Extract the direct link from the children
    children = contents_data['data']['children']
    for child_id, child_info in children.items():
        if child_info.get('type') == 'file':
            print(f"File info keys: {list(child_info.keys())}")
            link = child_info.get('link') or child_info.get('downloadUrl') or child_info.get('url')
            if link:
                print("==========================================================")
                print("AEGISOS DIRECT DOWNLOAD LINK:")
                print(link)
                print("==========================================================")
            else:
                constructed_link = f"https://{server}.gofile.io/download/{child_id}/{child_info['name']}"
                print("==========================================================")
                print("AEGISOS CONSTRUCTED DIRECT DOWNLOAD LINK:")
                print(constructed_link)
                print("==========================================================")
except Exception as e:
    print(f"Error fetching folder contents: {e}")
