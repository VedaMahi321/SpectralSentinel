import numpy as np
from sklearn.metrics import roc_auc_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

# ===============================================
# HYPERSPECTRAL ENGINE — Simulation + Algorithms
# ===============================================

def generate_synthetic_scene(H=100, W=100, B=80, snr_db=20, shift=0.0):
    """Generate a synthetic hyperspectral cube and target mask."""
    np.random.seed(42)
    noise_power = 10 ** (-snr_db / 10)
    background = np.random.normal(0.5, 0.1, (H, W, B))
    target = np.random.normal(0.6 + shift, 0.1, (H, W, B))

    mask = np.zeros((H, W))
    cx, cy, r = H // 2, W // 2, 10
    for i in range(H):
        for j in range(W):
            if (i - cx) ** 2 + (j - cy) ** 2 < r ** 2:
                mask[i, j] = 1
                background[i, j, :] = target[i, j, :]

    noise = np.random.normal(0, np.sqrt(noise_power), (H, W, B))
    cube = np.clip(background + noise, 0, 1)
    return cube, mask


def fisher_scores(X, y):
    """Compute Fisher score per band."""
    scores = []
    for b in range(X.shape[1]):
        xb = X[:, b]
        mean1 = xb[y == 1].mean() if np.any(y == 1) else 0
        mean0 = xb[y == 0].mean()
        var1 = xb[y == 1].var() if np.any(y == 1) else 1.0
        var0 = xb[y == 0].var()
        score = ((mean1 - mean0) ** 2) / (var1 + var0 + 1e-8)
        scores.append(score)
    return np.array(scores)


def jm_distance(X, y):
    """Compute Jeffries–Matusita distance for each band."""
    jm = []
    for b in range(X.shape[1]):
        xb = X[:, b]
        mean1 = xb[y == 1].mean()
        mean0 = xb[y == 0].mean()
        var1 = xb[y == 1].var() + 1e-6
        var0 = xb[y == 0].var() + 1e-6
        bh = (1/8) * ((mean1 - mean0) ** 2) / ((var1 + var0) / 2) + \
             0.5 * np.log(((var1 + var0) / 2) / np.sqrt(var1 * var0))
        jm.append(2 * (1 - np.exp(-bh)))
    return np.array(jm)


def greedy_selection(X_train, y_train, X_val, y_val, k=10):
    """Greedy band subset selection using validation AUC."""
    selected, remaining = [], list(range(X_train.shape[1]))
    best_score = 0
    while len(selected) < k:
        best_band, best_auc = None, 0
        for b in remaining:
            subset = selected + [b]
            clf = RandomForestClassifier(n_estimators=40)
            clf.fit(X_train[:, subset], y_train)
            probs = clf.predict_proba(X_val[:, subset])[:, 1]
            auc = roc_auc_score(y_val, probs)
            if auc > best_auc:
                best_auc, best_band = auc, b
        selected.append(best_band)
        remaining.remove(best_band)
        best_score = best_auc
    return selected, best_score


def simulate_detection(cube, selected_bands, mask):
    """Simulate detection heatmap using RandomForest classification."""
    H, W, B = cube.shape
    X = cube.reshape(-1, B)
    y = mask.reshape(-1)
    X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.3, stratify=y)
    clf = RandomForestClassifier(n_estimators=60)
    clf.fit(X_train[:, selected_bands], y_train)
    probs = clf.predict_proba(X_val[:, selected_bands])[:, 1]
    auc = roc_auc_score(y_val, probs)
    y_pred = clf.predict_proba(X[:, selected_bands])[:, 1]
    heatmap = y_pred.reshape(H, W)
    return heatmap, auc


def pareto_front(scores, redundancy):
    """Compute Pareto front approximation (simplified)."""
    idx = np.argsort(scores)
    pareto = []
    for i in idx:
        if len(pareto) == 0 or redundancy[i] <= redundancy[pareto[-1]]:
            pareto.append(i)
    return np.array(pareto)
