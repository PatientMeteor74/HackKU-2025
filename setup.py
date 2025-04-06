from setuptools import setup, find_packages

setup(
    name="HackKU-2025",
    version="0.1",
    packages=find_packages(),
    install_requires=[
        "flask==2.0.1",
        "joblib==1.1.0",
        "numpy==1.21.2", 
        "pandas==1.3.3",
        "scikit-learn==1.0.0",
    ],
) 