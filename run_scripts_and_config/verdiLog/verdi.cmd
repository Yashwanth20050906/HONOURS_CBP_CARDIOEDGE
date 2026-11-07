verdiSetActWin -dock widgetDock_<Message>
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
simSetSimulator "-vcssv" -exec \
           "/home/student/Documents/HONOURS_CBP_CARDIOEDGE/run_scripts_and_config/simv" \
           -args
debImport "-dbdir" \
          "/home/student/Documents/HONOURS_CBP_CARDIOEDGE/run_scripts_and_config/simv.daidir"
debLoadSimResult \
           /home/student/Documents/HONOURS_CBP_CARDIOEDGE/run_scripts_and_config/cardioedge_vip_sync.fsdb
wvCreateWindow
verdiSetActWin -win $_nWave2
srcHBSelect "tb_cardioedge_uvm_soc.adc_vif" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBDrag -win $_nTrace1
wvSetPosition -win $_nWave2 {("adc_vif(adc_if)" 0)}
wvRenameGroup -win $_nWave2 {G1} {adc_vif(adc_if)}
wvAddSignal -win $_nWave2 "/tb_cardioedge_uvm_soc/adc_vif/clk" \
           "/tb_cardioedge_uvm_soc/adc_vif/rst_n" \
           "/tb_cardioedge_uvm_soc/adc_vif/sample_in\[11:0\]" \
           "/tb_cardioedge_uvm_soc/adc_vif/sample_valid" \
           "/tb_cardioedge_uvm_soc/adc_vif/irq_sample" \
           "/tb_cardioedge_uvm_soc/adc_vif/irq_overrun"
wvSetPosition -win $_nWave2 {("adc_vif(adc_if)" 0)}
wvSetPosition -win $_nWave2 {("adc_vif(adc_if)" 6)}
wvSetPosition -win $_nWave2 {("adc_vif(adc_if)" 6)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetCursor -win $_nWave2 5028379.034483 -snap {("adc_vif(adc_if)" 4)}
verdiSetActWin -win $_nWave2
