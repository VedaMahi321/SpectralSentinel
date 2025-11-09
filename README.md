# 🛰️ SpectralSentinel
### *Defense-Oriented Hyperspectral Band Optimization and Camouflage Target Detection Framework*

---

## 📖 Overview

**SpectralSentinel** is a MATLAB-based defense research project focusing on **hyperspectral band optimization** for **camouflage and target detection**.  
It integrates four major algorithms — **Fisher Criterion**, **Jeffries–Matusita (JM) Distance**, **Greedy Selection**, and **MOBS-TD (Multiobjective Band Selection for Target Detection)** — within an interactive MATLAB GUI called **Hyperspectral Control Room**.

The framework enables defense researchers and engineers to visualize, compare, and analyze the separability, redundancy, and detection performance of hyperspectral bands.  
It is a modular foundation for evolving toward **real-time, onboard spectral intelligence systems**.

---

## 🎯 Objectives

- Implement classical and multiobjective optimization-based band selection algorithms for hyperspectral imaging (HSI).  
- Provide a **graphical user interface (GUI)** for visualization, control, and export of results.  
- Evaluate each algorithm’s performance using **AUC metrics**, heatmaps, and Pareto analysis.  
- Develop a **defense-grade spectral analysis tool** capable of detecting camouflaged targets.  
- Prepare the framework for **real-time deployment** on edge computing and UAV platforms.

---

## 🧠 Background

### Hyperspectral Imaging in Defense
Hyperspectral Imaging (HSI) captures hundreds of contiguous spectral bands for each pixel, allowing detection of subtle material differences — even under camouflage.  
This spectral richness, however, causes:
- Redundant information across adjacent bands.
- Increased computational load.
- Reduced real-time feasibility.

Hence, **band optimization** is crucial for defense-oriented target detection systems — selecting only the most informative and uncorrelated bands.

---

## ⚙️ Implemented Algorithms

| Algorithm | Description | Characteristics |
|------------|--------------|----------------|
| **Fisher Criterion** | Measures separability between target and background classes using mean and variance. | Fast, statistical baseline. |
| **Jeffries–Matusita (JM) Distance** | Measures statistical divergence between class distributions. | Strong spectral separability metric. |
| **Greedy Selection** | Iteratively selects bands maximizing incremental AUC improvement. | Slower but locally optimal. |
| **MOBS-TD** | Multiobjective Band Selection (Entropy, Redundancy, Separability). Uses Pareto dominance and WSIS scoring. | Advanced optimization; high accuracy. |

---

## 🧩 MOBS-TD Framework

### Multiobjective Formulation

Each candidate band subset \( X \) is optimized with respect to three competing objectives:

\[
\max f_1(X) = Entropy(X), \quad \max f_2(X) = Separability(X), \quad \min f_3(X) = Redundancy(X)
\]

where:
- **Entropy** measures the information content.
- **Separability** quantifies target–background discrimination.
- **Redundancy** penalizes correlated spectral bands.

### Optimization Loop
The algorithm evolves a population of band subsets using:
- **Pareto dominance ranking**  
- **WSIS (Weighted Solution Importance Score)**  
- **MSR (Mean Spectral Response)** evaluation  
- **Mutation and crossover** to maintain diversity.

---

## 🔄 Pseudocode (Simplified)

```text
Initialize population of random band subsets
For each iteration:
    For each subset:
        Compute Entropy, Separability, and Redundancy
        Update non-dominated Pareto repository
    Perform mutation/crossover
    Compute WSIS score for diversity control
End
Select final subset maximizing Mean Spectral Response (MSR)
