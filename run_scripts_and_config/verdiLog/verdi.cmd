verdiSetActWin -dock widgetDock_<Message>
simSetSimulator "-vcssv" -exec "simv_comprehensive" -args
debImport "-dbdir" "simv_comprehensive.daidir"
debLoadSimResult \
           /home/student/Documents/HONOURS_CBP_CARDIOEDGE/run_scripts_and_config/cardioedge_regression.fsdb
wvCreateWindow
wvRestoreSignal -win $_nWave2 "cardioedge_wave.rc" -overWriteAutoAlias on \
           -appendSignals on
verdiWindowResize -win $_Verdi_1 "330" "84" "900" "700"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiDockWidgetMaximize -dock windowDock_nWave_2
verdiSetActWin -win $_nWave2
wvZoomAll -win $_nWave2
verdiWindowResize -win $_Verdi_1 "790" "19" "800" "836"
wvZoomAll -win $_nWave2
wvScrollDown -win $_nWave2 6
wvScrollDown -win $_nWave2 22
wvSelectSignal -win $_nWave2 \
           {( "G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, \
           TC-04)" 1 )} 
wvScrollUp -win $_nWave2 7
wvScrollUp -win $_nWave2 2
wvSelectSignal -win $_nWave2 \
           {( "G3: VeeR EL2 CPU Core & ISA (TC-01, TC-02, TC-15, \
           TC-17)" 1 )} 
wvSetPosition -win $_nWave2 \
           {("G3: VeeR EL2 CPU Core & ISA (TC-01, TC-02, TC-15, TC-17)" 1)}
wvExpandBus -win $_nWave2
wvSelectSignal -win $_nWave2 \
           {( "G3: VeeR EL2 CPU Core & ISA (TC-01, TC-02, TC-15, \
           TC-17)" 4 )} 
wvScrollUp -win $_nWave2 11
wvSelectSignal -win $_nWave2 \
           {( "G3: VeeR EL2 CPU Core & ISA (TC-01, TC-02, TC-15, \
           TC-17)" 1 )} 
wvSetPosition -win $_nWave2 \
           {("G3: VeeR EL2 CPU Core & ISA (TC-01, TC-02, TC-15, TC-17)" 1)}
wvCollapseBus -win $_nWave2
wvSetPosition -win $_nWave2 \
           {("G3: VeeR EL2 CPU Core & ISA (TC-01, TC-02, TC-15, TC-17)" 1)}
wvShowOneTraceSignals -win $_nWave2 -signal \
           "/tb_cardioedge_comprehensive_soc/dut/ifu64_araddr\[31:0\]" -driver
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiSetActWin -win $_nWave2
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 9
wvSelectSignal -win $_nWave2 \
           {( "G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, \
           TC-04)" 7 )} 
wvSetCursor -win $_nWave2 4662790.310613 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 7)}
wvSetCursor -win $_nWave2 5680126.378383 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 10)}
wvSetCursor -win $_nWave2 10936362.728528 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 10)}
wvScrollUp -win $_nWave2 6
wvScrollDown -win $_nWave2 16
wvScrollUp -win $_nWave2 15
wvSelectSignal -win $_nWave2 \
           {( "G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, \
           TC-04)" 1 )} 
wvSetCursor -win $_nWave2 0.000000 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 1)}
wvSetCursor -win $_nWave2 339112.022590 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 1)}
wvZoom -win $_nWave2 0.000000 254334.016943
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvSetCursor -win $_nWave2 469077.122873 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 1)}
wvSetCursor -win $_nWave2 485113.947587 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 1)}
wvSetCursor -win $_nWave2 441012.679624 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 1)}
wvSetCursor -win $_nWave2 489123.153765 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 4)}
wvSetCursor -win $_nWave2 463063.313606 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 1)}
wvSetCursor -win $_nWave2 511173.787747 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 1)}
wvSetCursor -win $_nWave2 677555.844150 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 1)}
wvSetCursor -win $_nWave2 769767.586254 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 1)}
wvSetCursor -win $_nWave2 841933.297465 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 1)}
wvSetCursor -win $_nWave2 994283.132244 -snap \
           {("G4: AXI Interconnect S00 (IFU) & S01 (LSU) (TC-03, TC-04)" 1)}
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 38
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 3
wvSelectSignal -win $_nWave2 {( "G7: GPIO Subsystem (TC-06)" 1 )} 
wvSelectSignal -win $_nWave2 {( "G7: GPIO Subsystem (TC-06)" 2 )} 
wvZoomAll -win $_nWave2
wvSetCursor -win $_nWave2 2260061.576355 -snap {("G7: GPIO Subsystem (TC-06)" 2)}
wvSetCursor -win $_nWave2 1277426.108374 -snap {("G7: GPIO Subsystem (TC-06)" 2)}
wvSetCursor -win $_nWave2 4127068.965517 -snap {("G7: GPIO Subsystem (TC-06)" 1)}
wvSetCursor -win $_nWave2 3439224.137931 -snap {("G7: GPIO Subsystem (TC-06)" 2)}
wvSetCursor -win $_nWave2 12381206.896552 -snap \
           {("G7: GPIO Subsystem (TC-06)" 3)}
wvSetCursor -win $_nWave2 14248214.285714 -snap \
           {("G7: GPIO Subsystem (TC-06)" 2)}
wvSetCursor -win $_nWave2 18768337.438424 -snap \
           {("G7: GPIO Subsystem (TC-06)" 2)}
wvScrollDown -win $_nWave2 9
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 8
debExit
