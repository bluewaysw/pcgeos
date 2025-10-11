#
#	BMP-Tools Library by Rabe-Soft
#	Rainer Bettsteller, Magdeburg, Germany
#	Adapted for free PC/GEOS project 01/2024 - 10/2025
#

# NO_EC = 1


#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L bmptools


# XCCOMFLAGS = -zc -zu

# Create a Copyrigth-notice
LINKFLAGS += -N "Made by RABE-Soft 01/2000-10/25"


