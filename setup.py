import os
from setuptools import setup

setup(
    name="mbi",
    version="0.0.1",
    author="Diego Aldarondo",
    author_email="diegoaldarondo@g.harvard.edu",
    install_requires=[
        "numpy>=1.14.1",
        "h5py>=2.7.1",
        "matplotlib",
        "clize>=4.0.3",
        "keras>=2.2.2"
    ]
)
