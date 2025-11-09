import matlab.engine

def run_mobs_td(matlab_folder, mat_file, num_bands=10):
    """
    Call MATLAB MOBS-TD implementation and return (selected_bands, auc).
    """
    print("Starting MATLAB engine ...")
    eng = matlab.engine.start_matlab()
    eng.cd(matlab_folder, nargout=0)
    print(f"Running run_mobs_td('{mat_file}', {num_bands}) ...")

    selected, auc = eng.run_mobs_td(mat_file, float(num_bands), nargout=2)
    eng.quit()

    selected = [int(x) for x in list(selected)]
    auc = float(auc)
    print(f"Selected bands: {selected}, AUC={auc:.3f}")
    return selected, auc
