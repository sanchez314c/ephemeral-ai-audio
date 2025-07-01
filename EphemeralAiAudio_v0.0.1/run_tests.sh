#!/bin/bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ./conda_env

echo "Running EVA test suite..."
python -m pytest tests/ -v --tb=short

echo ""
echo "Running demo..."
python demo.py
