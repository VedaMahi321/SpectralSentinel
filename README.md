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

**SpectralSentinel** is a MATLAB-based research and visualization framework for **hyperspectral band optimization** focused on **defense and camouflage target detection**.  

It integrates **four core algorithms** into a unified GUI — the **Hyperspectral Control Room**:
- **Fisher Criterion**  
- **Jeffries–Matusita (JM) Distance**  
- **Greedy Band Selection**  
- **MOBS-TD (Multiobjective Band Selection for Target Detection)**  

The framework enables **spectral separability**, **redundancy control**, and **detection performance visualization**, while exporting **timestamped, reproducible reports and figures** automatically.

---

## 🧭 Motivation

Conventional RGB or multispectral systems are unreliable under camouflage and spectral similarity.  
Hyperspectral imaging (HSI) captures fine spectral differences but produces large, redundant datasets.  

**SpectralSentinel** bridges this gap by:
- Selecting the **most informative spectral bands**.  
- Minimizing **redundancy and noise**.  
- Maximizing **class separability and detection reliability**.  
- Supporting **defense-grade real-time analysis and deployment**.  

---

## ⚙️ Key Features

- 🖥️ MATLAB GUI: **Hyperspectral Control Room**
- 🔬 Four algorithms integrated: Fisher, JM, Greedy, MOBS-TD
- 🔧 Adjustable parameters:
  - **SNR (5–40 dB)**
  - **Spectral Shift (−0.2 → 0.2)**
  - **Band Count (`k`)**
  - **Preselection Count (`m`)**
- 📊 Real-time visualizations: heatmaps, band importance, Pareto fronts
- 🧾 Auto-export of `.mat` data and figures
- 🕒 Timestamped results (e.g., `results_2025-11-08_213419.mat`)
- 💽 Fully compatible with MATLAB R2021b and newer

---

## 🖥️ Graphical User Interface (GUI)

The GUI provides a single control hub for experiment setup, algorithm execution, and visual analytics.

<p align="center">
  <img src="MOBS-TD-(MATLAB)_20251108_213419_ui-snapshot.png" width="90%" alt="Hyperspectral Control Room GUI"/>
</p>

### 🔹 Interface Components
1. **Algorithm Selector** — Fisher, JM, Greedy, or MOBS-TD  
2. **Sliders** — Control SNR and spectral shift  
3. **Input Fields** — Enter total bands (B), selection (k), and preselect (m)  
4. **Run Analysis** — Execute selected algorithm  
5. **Heatmap Panel** — Displays detection intensity  
6. **Band Scores Panel** — Importance ranking  
7. **Pareto Plot** — Separability vs redundancy trade-offs  
8. **Log Console** — Shows runtime progress  

---

## ▶️ How to Run

### Step 1 — Clone the Repository
```bash
git clone https://github.com/VedaPrakashM/SpectralSentinel.git
cd SpectralSentinel
Step 2 — Add Project to MATLAB Path
matlab
Copy code
addpath(genpath(pwd));
Step 3 — Launch the GUI
matlab
Copy code
control_room_matlab
Step 4 — Configure and Run
Parameter	Example Value
Algorithm	MOBS-TD (MATLAB)
Total Bands	80
Select k	10
Preselect m	30
SNR	20 dB
Shift	0.05

Click Run Analysis to begin.

Step 5 — Output Files
After completion, results are saved automatically:

scss
Copy code
MOBS-TD-(MATLAB)_20251108_213419_heatmap.png
MOBS-TD-(MATLAB)_20251108_213419_bands.png
MOBS-TD-(MATLAB)_20251108_213419_pareto.png
figure_combined_MOBS-TD-(MATLAB)_20251108_213419.png
📊 Example Outputs
Fisher Criterion
<p align="center"> <img src="Fisher_20251108_212831_heatmap.png" width="48%" alt="Fisher Heatmap"/> <img src="Fisher_20251108_212831_bands.png" width="48%" alt="Fisher Bands"/> </p>
Jeffries–Matusita Distance
<p align="center"> <img src="JM_20251108_212847_heatmap.png" width="48%" alt="JM Heatmap"/> <img src="JM_20251108_212847_bands.png" width="48%" alt="JM Bands"/> </p>
Greedy Selection
<p align="center"> <img src="Greedy_20251108_213117_heatmap.png" width="48%" alt="Greedy Heatmap"/> <img src="Greedy_20251108_213117_bands.png" width="48%" alt="Greedy Bands"/> </p>
MOBS-TD (MATLAB)
<p align="center"> <img src="MOBS-TD-(MATLAB)_20251108_213419_heatmap.png" width="48%" alt="MOBS Heatmap"/> <img src="MOBS-TD-(MATLAB)_20251108_213419_bands.png" width="48%" alt="MOBS Bands"/> </p>
🧮 Algorithm Summary
Algorithm	Approach	Strength	Limitation
Fisher	Variance-based separability	Fast, simple baseline	Ignores redundancy
JM Distance	Probabilistic divergence	High separability	More compute
Greedy	AUC-based iterative selection	Balanced, effective	Slower on high-dim data
MOBS-TD	Multiobjective Pareto optimization	Pareto-optimal, balanced	High runtime

🧠 Theoretical Background — MOBS-TD
Objective Functions:

max
⁡
𝑓
1
(
𝑋
)
=
𝐸
𝑛
𝑡
𝑟
𝑜
𝑝
𝑦
(
𝑋
)
,
max
⁡
𝑓
2
(
𝑋
)
=
𝑆
𝑒
𝑝
𝑎
𝑟
𝑎
𝑏
𝑖
𝑙
𝑖
𝑡
𝑦
(
𝑋
)
,
min
⁡
𝑓
3
(
𝑋
)
=
𝑅
𝑒
𝑑
𝑢
𝑛
𝑑
𝑎
𝑛
𝑐
𝑦
(
𝑋
)
maxf 
1
​
 (X)=Entropy(X),maxf 
2
​
 (X)=Separability(X),minf 
3
​
 (X)=Redundancy(X)
Each candidate subset

𝑋
=
[
𝑏
1
,
𝑏
2
,
.
.
.
,
𝑏
𝑘
]
X=[b 
1
​
 ,b 
2
​
 ,...,b 
k
​
 ]
evolves through a Pareto-based Particle Swarm Optimization (PSO) process.

Fitness Components
Entropy (E): Information content

Redundancy (R): Penalizes correlated features

Separability (S): Measures spectral class distinction

Key Functions
WSIS (Weighted Solution Importance Score): Ranks Pareto-optimal sets

MSR (Mean Spectral Response): Used for final subset selection

📂 Repository Structure
bash
Copy code
SpectralSentinel/
├── control_room_matlab.m        # GUI Main File
├── main.m                       # MOBS-TD Core Script
├── save_analysis_outputs.m      # Timestamped export
├── fisher_scores.m              # Fisher Criterion
├── jm_distance.m                # JM Distance Calculation
├── greedy_selection.m           # Greedy Band Selection
├── simulate_detection.m         # Target Detection Simulation
├── helper_functions/            # Utility and Plot Scripts
├── results/                     # Auto-saved Figures and Data
├── report/                      # LaTeX Report Files
└── README.md                    # Documentation
🧾 Performance Summary
Algorithm	AUC	Runtime (s)	Remarks
Fisher	0.956	0.8	Fast, reliable baseline
JM Distance	0.959	1.3	High separability
Greedy	0.918	4.2	Balanced trade-off
MOBS-TD	0.956	130	Pareto-optimal, multiobjective

🧭 Future Scope
⚙️ FPGA/GPU acceleration for onboard processing

🚁 UAV integration for real-time hyperspectral monitoring

🤖 Reinforcement learning-based adaptive band selection

🌡️ Multimodal fusion (HSI + Thermal + LiDAR) for enhanced defense analytics

🔐 Integration with defense simulation frameworks (MATLAB/Simulink)

📚 References
X. Sun et al., “MOBS-TD: Multiobjective Band Selection With Ideal Solution Optimization Strategy for Hyperspectral Target Detection,” IEEE JSTARS, 2024.

C.-I. Chang, Hyperspectral Data Exploitation: Theory and Applications, Wiley, 2007.

D. Landgrebe, “Hyperspectral Image Data Analysis,” IEEE Signal Processing Magazine, 2002.

📜 License
This project is released under the MIT License.
You may reuse, modify, or extend it for academic and research purposes with proper citation.

🔗 Repository Link
🌐 GitHub: https://github.com/VedaPrakashM/SpectralSentinel

<p align="center"><b>SpectralSentinel — Empowering Real-Time Defense Through Spectral Intelligence</b></p>
✅ What This Version Includes
Full GUI overview with image

Step-by-step setup & execution

Example configurations and output filenames

Visual outputs for all four algorithms

Theoretical background for MOBS-TD

Performance table and future roadmap

Author credentials (Roll No: 22SP2031, NITK Surathkal)

Proper citations and academic license compliance

yaml
Copy code
