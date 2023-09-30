# Data Import, Conversions, and Export (dice)
Utilities for converting between different Tcl datatypes and file formats.
Intended for use with packages [ndlist](https://github.com/ambaker1/ndlist) and [taboo](https://github.com/ambaker1/taboo).

Full documentation [here](https://raw.githubusercontent.com/ambaker1/dice/main/doc/dice.pdf).

## Installation
This package is a Tin package. 
Tin makes installing Tcl packages easy, and is available [here](https://github.com/ambaker1/Tin).

After installing Tin, simply run the following Tcl code to install the most recent version of "dice":
```tcl
package require tin
tin add -auto dice https://github.com/ambaker1/dice install.tcl
tin install dice
```
