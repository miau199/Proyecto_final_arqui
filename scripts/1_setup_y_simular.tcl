# ==============================================================
# 1_setup_y_simular.tcl
# Ejecutar en la Tcl Console de Vivado con proyecto_final abierto:
#   source C:/vivadoProjects/proyecto_final/scripts/1_setup_y_simular.tcl
#
# - Mueve imem/dmem/program.mem a Design Sources (para poder sintetizar)
# - Agrega fpga_top.sv y basys3.xdc
# - Top de sintesis = fpga_top ; top de simulacion = riscv_tb
# - Lanza la simulacion de comportamiento (busca "RESULTADO: PASS")
# ==============================================================

set proj_dir [get_property DIRECTORY [current_project]]
set src $proj_dir/proyecto_final.srcs/sources_1/new
set sim $proj_dir/proyecto_final.srcs/sim_1/new
set con $proj_dir/proyecto_final.srcs/constrs_1/new

proc add_if_missing {fs path} {
  if {[llength [get_files -quiet -of_objects [get_filesets $fs] $path]] == 0} {
    add_files -norecurse -fileset $fs $path
  }
}

# 1. Quitar del proyecto las referencias viejas en sim_1 (los archivos se movieron)
foreach f {imem.sv dmem.sv program.mem} {
  set h [get_files -quiet -of_objects [get_filesets sim_1] "*/sim_1/new/$f"]
  if {[llength $h]} { remove_files -fileset sim_1 $h }
}

# 2. Design sources (nucleo + memorias + top de FPGA)
foreach f {riscv_pkg.sv alu.sv control_unit.sv imm_extend.sv reg_file.sv
           datapath.sv riscv_single_cycle.sv imem.sv dmem.sv program.mem fpga_top.sv} {
  add_if_missing sources_1 $src/$f
}

# 3. Constraints de la Basys 3
if {[llength [get_filesets -quiet constrs_1]] == 0} { create_fileset -constrset constrs_1 }
add_if_missing constrs_1 $con/basys3.xdc
set_property target_constrs_file $con/basys3.xdc [get_filesets constrs_1]

# 4. Testbench
add_if_missing sim_1 $sim/riscv_tb.sv

# 5. Tops y orden de compilacion
set_property top fpga_top [get_filesets sources_1]
set_property top riscv_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# 6. Simulacion de comportamiento
catch {close_sim -force -quiet}
launch_simulation
puts "\n>>> Revisa la Tcl Console: debe aparecer 'RESULTADO: PASS (33/33 ...)'"
puts ">>> Log completo: $proj_dir/proyecto_final.sim/sim_1/behav/xsim/simulate.log\n"
