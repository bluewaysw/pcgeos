##############################################################################
#
# PROJECT:  PC GEOS
# MODULE:    Mouse Drivers - IntelliMouse-style PS/2 3-button wheel mice
# FILE:      imps2.gp
#
# AUTHORS:
# MeyerK, 2021/08
# JP, 03/07
# Gene Anderson, early 2000s
# ?
#
# Parameters file for: imps2.geo
#
##############################################################################

# Specify permanent name first
name  imps2.drvr

# Specify geode type
type  driver, single

# Import kernel routine definitions
library  geos

# Desktop-related things
longname "Intellimouse PS/2 Wheel Mouse"
tokenchars "MOUS"
tokenid 0

# Define resources other than standard discardable code
resource Resident fixed code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming

ifdef PRODUCT_GEOS2X
platform geos20
endif
