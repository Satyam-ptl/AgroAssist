import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'AgroAssist_Backend.settings')

from AgroAssist_Backend.wsgi import application

app = application
