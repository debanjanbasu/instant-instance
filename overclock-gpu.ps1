#!/usr/bin/env pwsh

cd "C:\Program Files\NVIDIA Corporation\NVSMI"
.\nvidia-smi --auto-boost-default=0
.\nvidia-smi -ac "5001,1590"
