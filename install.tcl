package require tin 1.0
tin depend ndlist 0.2
set dir [tin mkdir -force iou 0.1]
file copy pkgIndex.tcl iou.tcl README.md LICENSE $dir
