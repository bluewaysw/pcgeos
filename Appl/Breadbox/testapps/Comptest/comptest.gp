##############################################################################
#
# PROJECT:      
# FILE:         COMPTEST.GP
#               Copyright (c) by RABE-Soft 06/2024
#
# AUTHOR:       Rainer Bettsteller
#
##############################################################################


# *************** Informationen fÅr Glue *************** #

name        compt.app
type        appl, process, single
class       CompProcessClass
appobj      CompApp

longname    "Compress Test"
tokenchars  "SAMP"
tokenid     8


# *************** Libraries *************** #
# Eigene Libraries mÅssen mit "exempt mylib" von der Suche
# in den Platformdateien ausgenommen werden 

library	geos
library	ansic
library	ui
library	math
library compress


# *************** Resourcen *************** #
# Bsp: resource DATARESOURCE lmem read-only shared data

resource	AppResource ui-object
resource	Interface ui-object
resource	MenuResource ui-object
resource	DataResource lmem read-only shared
resource	DataResource2 lmem read-only shared
resource	DataResource3 lmem read-only shared


# *************** Exportierte Klassen und Routinen *************** #
# Bsp: export SOMEROUTINE



# *********** end of file COMPTEST.GP *******************


