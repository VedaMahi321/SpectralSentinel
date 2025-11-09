import streamlit as st
import numpy as np
import matplotlib.pyplot as plt
from hyperspectral_engine import (
    generate_synthetic_scene,
    fisher_scores,
    jm_distance,
    greedy_selection,
    simulate_detection,
    pareto_front,
)
# from mobs_td_bridge import run_mobs_td  # Uncomment when MATLAB ready

st.set_page_config(page_title="Hyperspectral Control Room", layout="wide")

st.markdown(
    """
    <h2 style='text-align:center; color:#FFB703;'>Hyperspectral Control Room</h2>
    <p style='text-align:center; color:gray;'>Defense-Oriented Hyperspectral Band Optimization for Camouflage and Target Detection</p>
    """,
    unsafe_allow_html=True,
)

st.sidebar.header("Sensor & Algorithm Controls")
algorithm = st.sidebar.selectbox(
    "Algorithm", ["Fisher", "JM", "Greedy", "MOBS-TD (MATLAB)"]
)
snr = st.sidebar.slider("Noise (SNR dB)", 5, 40, 20)
shift = st.sidebar.slider("Spectral Shift", -0.1, 0.1, 0.0)
num_bands = st.sidebar.slider("Total Bands", 40, 120, 80)
subset_size = st.sidebar.slider("Select Bands (k)", 5, 20, 10)

if st.sidebar.button("Run Analysis"):
    st.info("Generating hyperspectral cube ...")
    cube, mask = generate_synthetic_scene(B=num_bands, snr_db=snr, shift=shift)
    X = cube.reshape(-1, num_bands)
    y = mask.reshape(-1)

    if algorithm == "Fisher":
        scores = fisher_scores(X, y)
        selected = np.argsort(scores)[-subset_size:]
        auc = 0.0
        score_label = "Fisher Score"

    elif algorithm == "JM":
        scores = jm_distance(X, y)
        selected = np.argsort(scores)[-subset_size:]
        auc = 0.0
        score_label = "JM Distance"

    elif algorithm == "Greedy":
        Xtr, Xv = X[:len(X)//2], X[len(X)//2:]
        ytr, yv = y[:len(y)//2], y[len(y)//2:]
        selected, auc = greedy_selection(Xtr, ytr, Xv, yv, k=subset_size)
        scores = np.zeros(num_bands)
        scores[selected] = 1
        score_label = f"Greedy (AUC={auc:.3f})"

    else:  # MATLAB MOBS-TD
        st.warning("Running MATLAB MOBS-TD backend ... please wait.")
        from mobs_td_bridge import run_mobs_td
        selected, auc = run_mobs_td(
            r"D:\MOBS-TD-Hyperspectral-Band-Selection-main\MOBS-TD-Hyperspectral-Band-Selection-main",
            "hydice_urban_162.mat",
            subset_size,
        )
        scores = np.zeros(num_bands)
        for b in selected:
            if b < num_bands:
                scores[b] = 1
        score_label = f"MOBS-TD (AUC={auc:.3f})"

    st.success("Analysis complete!")

    # Plot results
    heatmap, det_auc = simulate_detection(cube, selected, mask)
    redundancy = np.random.rand(num_bands)
    pareto_idx = pareto_front(scores, redundancy)

    c1, c2 = st.columns(2)
    with c1:
        st.subheader("Detection Heatmap")
        fig, ax = plt.subplots()
        im = ax.imshow(heatmap, cmap="turbo")
        fig.colorbar(im)
        st.pyplot(fig)

    with c2:
        st.subheader("Selected Bands")
        fig, ax = plt.subplots()
        ax.plot(scores, color="white")
        for b in selected:
            ax.axvline(b, color="cyan", alpha=0.6)
        ax.set_title(score_label)
        st.pyplot(fig)

    st.subheader("Pareto Front")
    fig, ax = plt.subplots()
    ax.scatter(redundancy, scores, c="gray")
    ax.plot(redundancy[pareto_idx], scores[pareto_idx], color="lime")
    ax.set_xlabel("Redundancy")
    ax.set_ylabel("Separability")
    st.pyplot(fig)

    st.markdown(
        f"""
        **Selected Bands:** {selected.tolist()}  
        **Algorithm:** {algorithm}  
        **Frame AUC:** {det_auc:.3f}
        """
    )
else:
    st.info("Set parameters on the left and click *Run Analysis* to begin.")
