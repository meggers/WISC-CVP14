set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
set_operating_conditions NCCOM -library tcbn40lpbwptc
set_wire_load_mode top
set_wire_load_model -name TSMC512K_Lowk_Aggresive -library tcbn40lpbwptc

/* Top Level */
analyze -library WORK -format verilog {/filespace/people/m/mwiemer/ECE551/Project/WISC-CVP14/CVP14.v /filespace/people/m/mwiemer/ECE551/Project/WISC-CVP14/VectorRegFile.v /filespace/people/m/mwiemer/ECE551/Project/WISC-CVP14/ScalarRegFile.v /filespace/people/m/mwiemer/ECE551/Project/WISC-CVP14/OperandPicker.v /filespace/people/m/mwiemer/ECE551/Project/WISC-CVP14/InstructionDecode.v /filespace/people/m/mwiemer/ECE551/Project/WISC-CVP14/ALU.v}

/* Elaboration*/
elaborate CVP14 -architecture verilog -library WORK

/* Settings */

/* Compile */
compile -map_effort medium
report_area > area.txt

/* Write */
write -format verilog -output FIRST_synth.v


