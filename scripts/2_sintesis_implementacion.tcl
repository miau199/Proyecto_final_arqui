# ==============================================================
# 2_sintesis_implementacion.tcl
# Ejecutar DESPUES de que la simulacion de PASS:
#   source C:/vivadoProjects/proyecto_final/scripts/2_sintesis_implementacion.tcl
#
# Sintesis -> Implementacion -> Bitstream, y guarda reportes de
# utilizacion, timing y potencia en proyecto_final/reportes/
# (tarda unos minutos; la GUI queda ocupada mientras tanto)
# ==============================================================

set proj_dir [get_property DIRECTORY [current_project]]
set rpt $proj_dir/reportes
file mkdir $rpt
catch {close_sim -force -quiet}

# Sintesis
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
  error "La sintesis fallo. Revisa Messages / synth_1 runme.log"
}
open_run synth_1 -name synth_1
report_utilization    -file $rpt/synth_utilization.rpt
report_timing_summary -file $rpt/synth_timing_summary.rpt
close_design

# Implementacion + bitstream
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
  error "La implementacion fallo. Revisa Messages / impl_1 runme.log"
}
open_run impl_1
report_utilization    -file $rpt/impl_utilization.rpt
report_timing_summary -file $rpt/impl_timing_summary.rpt
report_power          -file $rpt/impl_power.rpt
report_clocks         -file $rpt/impl_clocks.rpt

set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
puts "\n>>> Implementacion terminada. WNS (setup) = $wns ns (debe ser >= 0)"
puts ">>> Reportes en: $rpt"
puts ">>> Bitstream:   [get_property DIRECTORY [get_runs impl_1]]/fpga_top.bit"
puts ">>> Para programar: Open Hardware Manager -> Open Target -> Auto Connect -> Program Device\n"
