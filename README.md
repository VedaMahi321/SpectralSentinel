# 🛰️ SpectralSentinel
### *Defense-Oriented Hyperspectral Band Optimization and Camouflage Target Detection Framework*

---

## 🧑‍🎓 Author and Academic Details

**Name:** Veda Prakash Mohanarangan  
**Roll Number:** 22SP2031  
**Programme:** M.Tech – Signal Processing and Machine Learning (SPML)  
**Department:** Electronics and Communication Engineering (ECE)  
**Institution:** National Institute of Technology Karnataka (NITK), Surathkal  
**Course:** EC861 – Image Processing and Computer Vision  
**Guide:** Prof. Amareswararao Kavuri  
**Date:** November 2025  

---

## 📘 Overview

**SpectralSentinel** is a MATLAB-based research and visualization framework for **hyperspectral band optimization** designed for **defense applications** — especially **camouflage and target detection**.  

It integrates **four major algorithms** into a single interactive GUI, the **Hyperspectral Control Room**:
- **Fisher Criterion**  
- **Jeffries–Matusita (JM) Distance**  
- **Greedy Band Selection**  
- **MOBS-TD (Multiobjective Band Selection for Target Detection)**

The system enables spectral analysis, redundancy control, and detection performance visualization with **automatic report export** and **timestamped result storage**.

---

## 🧭 Motivation

Traditional RGB or multispectral systems struggle under camouflage or spectral similarity.  
Hyperspectral imaging provides fine-grained spectral detail — but high dimensionality introduces **redundancy**, **noise**, and **computational overhead**.

**SpectralSentinel** addresses this by:
- Selecting **informative** and **non-redundant** spectral bands.  
- Enhancing **target separability** and **reducing processing time**.  
- Supporting **defense-grade real-time analysis**.

---

## ⚙️ Key Features

- 🎛️ MATLAB GUI: **Hyperspectral Control Room**  
- 💡 Four algorithms: Fisher, JM, Greedy, MOBS-TD  
- 🔧 Adjustable parameters:
  - Signal-to-Noise Ratio (SNR: 5–40 dB)
  - Spectral Shift (−0.2 → 0.2)
  - Band Count (`k`) and Preselection Count (`m`)
- 📊 Real-time progress logging and result visualization  
- 🧾 Automatic export of figures and `.mat` results  
- 🕒 Timestamped filenames for reproducibility  
- 💽 Compatible with MATLAB R2021b and newer  

---

## 🖥️ Graphical User Interface (GUI)

<p align="center">
  <img src="MOBS-TD-(MATLAB)_20251108_213419_ui-snapshot.png" width="90%" alt="Hyperspectral Control Room GUI"/>
</p>

### 🔹 Interface Components

1. **Algorithm Selector** — Fisher, JM, Greedy, or MOBS-TD  
2. **Sliders** — Control SNR and spectral shift  
3. **Input Fields** — Total bands (B), selected bands (k), preselect (m)  
4. **Run Analysis** — Execute and visualize progress  
5. **Heatmap Panel** — Target detection intensity  
6. **Band Scores Panel** — Band importance ranking  
7. **Pareto Front Plot** — Trade-off visualization  
8. **Log Console** — Runtime messages and status  

---

## ▶️ How to Run

### Step 1 — Clone the Repository
```bash
git clone https://github.com/VedaPrakashM/SpectralSentinel.git
cd SpectralSentinel
