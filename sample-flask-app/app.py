from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    version = os.getenv('APP_VERSION', 'v1.0')
    return f'Hello from Flask! Version: {version}\n'

@app.route('/health')
def health():
    return 'OK', 200

@app.route('/version')
def version():
    return 'v3.0 - Updated via CI/CD!\n'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)