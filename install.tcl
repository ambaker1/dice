package require tin 1.0
tin depend ndlist 0.2
set dir [tin mkdir -force tio 0.1]
file copy pkgIndex.tcl tio.tcl README.md LICENSE $dir
