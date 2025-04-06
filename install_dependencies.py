#!/usr/bin/env python3
import subprocess
import sys

def install_dependencies():
    print("Installing required dependencies...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
        print("Dependencies installed successfully!")
    except subprocess.CalledProcessError:
        print("Error installing dependencies. Please try running 'pip install -r requirements.txt' manually.")
        return False
    return True

if __name__ == "__main__":
    install_dependencies() 