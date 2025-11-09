============================
 HYPERSPECTRAL CONTROL ROOM
============================

This folder integrates your MATLAB MOBS-TD code with a Streamlit GUI.

---------------------------------
1. Run in MATLAB directly
---------------------------------
1) Open MATLAB
2) cd into this folder:
   D:\MOBS-TD-Hyperspectral-Band-Selection-main\MOBS-TD-Hyperspectral-Band-Selection-main
3) In MATLAB command window:
   [bands, auc] = run_mobs_td('hydice_urban_162.mat', 10);

---------------------------------
2. Run interactive GUI (Streamlit)
---------------------------------
1) Open Command Prompt
2) cd into this folder:
   D:\MOBS-TD-Hyperspectral-Band-Selection-main\MOBS-TD-Hyperspectral-Band-Selection-main
3) Install packages (once):
   pip install streamlit scikit-learn matplotlib numpy
4) Run:
   streamlit run control_room.py
5) Adjust parameters on sidebar and click "Run Analysis".
   Use "MOBS-TD (MATLAB)" to call the real MATLAB algorithm.

---------------------------------
3. Connect MATLAB to Python (one-time)
---------------------------------
In MATLAB command window:
   cd('D:\MATLAB 2023\extern\engines\python')
   system('python setup.py install')

Then in Python you can test:
   import matlab.engine
   eng = matlab.engine.start_matlab()
   x = eng.sqrt(49.0)
   print(x)
   eng.quit()
