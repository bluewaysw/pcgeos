#####################################################################
#
# PROJECT:      Character Map
# MODULE:       Local makefile
# FILE:         local.mk
#
# AUTHOR:       Nathan Fiedler
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       NF      9/23/96         Initial version
#
# DESCRIPTION:
#       This adds additional flags to PMAKE, specifically to turn
#       off error checking. Also put our name in the geode rather
#       than Geoworks'.
#
#####################################################################
#
# Put our copyright message in geode (32 char. max.).
#
LINKFLAGS += -N "Blue Marsh Softworks, Rabe-Soft"
#
# Turn off error-checking.
#
# NO_EC = 1

#
# Include the system makefile.
#
#include <$(SYSMAKEFILE)>

