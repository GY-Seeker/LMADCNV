#!/bin/bash

# 检查并安装R
echo "Checking for R installation..."
if ! command -v R &> /dev/null
then
    echo "R is not installed. Installing R..."
    sudo apt update
    sudo apt install -y r-base
else
    echo "R is already installed."
fi

# 安装R包
echo "Installing R packages..."
Rscript -e "install.packages('BiocManager', repos='https://cloud.r-project.org')"
Rscript -e "BiocManager::install('DNAcopy')"

# 检查并安装Python
echo "Checking for Python installation..."
if ! command -v python3 &> /dev/null
then
    echo "Python is not installed. Installing Python..."
    sudo apt update
    sudo apt install -y python3 python3-pip
else
    echo "Python is already installed."
fi

# 安装Python包
echo "Installing Python packages..."
pip3 install --upgrade pip
pip3 install numpy pandas scikit-image scipy biopython pysam pyod pythresh rpy2

echo "All packages installed successfully!"
