#!/bin/bash
# Update OS packages
yum update -y

# Install Python3 and pip
amazon-linux-extras enable python3
yum install -y python3
python3 -m ensurepip --upgrade
pip3 install --upgrade pip

# Create app directory
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# Create Python REST API
cat <<EOF > app.py
from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return "Hello from private EC2!"

@app.route('/health')
def health():
    return "ok"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Install Flask
pip3 install Flask==2.3.2

# Run the app in background
nohup python3 app.py > /home/ec2-user/app.log 2>&1 &