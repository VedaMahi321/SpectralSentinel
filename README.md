# 🛰️ SpectralSentinel
**Defense-Oriented Hyperspectral Band Optimization & Camouflage Target Detection**

---

## 🧑‍🎓 Author & Academic Details

**Name:** Veda Prakash Mohanarangan  
**Roll Number:** 22SP2031  
**Programme:** M.Tech – Signal Processing and Machine Learning (SPML)  
**Department:** Electronics and Communication Engineering (ECE)  
**Institution:** National Institute of Technology Karnataka (NITK), Surathkal  
**Course:** EC861 – Image Processing and Computer Vision  
**Date:** November 2025

---

## 🚀 Project Overview

**SpectralSentinel** is a MATLAB-based research and development framework for **hyperspectral band optimization**, designed for defense applications such as **camouflage detection** and **target identification**. The project integrates four band-selection strategies into an interactive GUI (Hyperspectral Control Room):

- **Fisher Criterion** (statistical separability)  
- **Jeffries–Matusita (JM) Distance** (class divergence)  
- **Greedy Selection** (iterative AUC-driven selection)  
- **MOBS-TD** (Multiobjective Band Selection for Target Detection — entropy, redundancy, separability)

The repository includes scripts to run experiments, generate detection heatmaps, band-score plots, Pareto fronts, and timestamped exports for reproducible reporting.

---

## 🔍 Why this matters (Defense context)

HSI provides per-pixel spectral signatures across many bands. Camouflaged targets often evade RGB/visual sensors but can be distinguished spectrally. However, hundreds of bands mean redundancy, higher compute, and slower real-time performance. Band selection reduces dimensionality while preserving detection reliability — essential for UAVs, edge compute, and tactical systems.

---

## ✨ Key Features

- MATLAB GUI: **Hyperspectral Control Room** — set SNR/shift, select algorithm, run analysis  
- Implements Fisher, JM, Greedy, and MOBS-TD methods  
- Automatic exports: `heatmap`, `bands`, `pareto`, `figure_combined` images with timestamps  
- Saves `.mat` results (`results_YYYYMMDD_HHMMSS.mat`, `last_result.mat`, `report_data.mat`) for reproducibility  
- Code structured for easy extension to real-time or hardware acceleration

---

## 📐 Quick Math (high level)

- **Fisher score** per band \(b\):
  \[
  J_b = \frac{(\mu_{1,b}-\mu_{2,b})^2}{\sigma_{1,b}^2 + \sigma_{2,b}^2}
  \]

- **JM Distance** (two-class):
  \[
  JM = 2(1 - e^{-B}),\quad B=\frac{1}{8}(\mu_1-\mu_2)^T\Sigma^{-1}(\mu_1-\mu_2)+\dots
  \]

- **MOBS-TD Objectives**:
  \[
  \max E(X),\quad \max S(X),\quad \min R(X)
  \]
  (Entropy, Separability, Redundancy)

---

## 🧾 Pseudocode (MOBS-TD summary)

```text
Initialize population of candidate band subsets
For iteration = 1..MaxIter:
    For each candidate:
        Compute Entropy, Separability, Redundancy
        Update Pareto repository (non-dominated solutions)
    Apply grid-based ranking (WSIS) to preserve diversity
    Select leaders and update candidate positions (PSO-like + mutate/crossover)
End
Compute MSR for repository; select final subset(s)
