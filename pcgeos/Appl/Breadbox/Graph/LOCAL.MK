#####################################################################
#
# Copyright (C) 1996 Blue Marsh Softworks -- All Rights Reserved.
#
# PROJECT:       COMP 413 Software Engineering Project
# MODULE:        Local makefile
# FILE:          local.mk
#
# AUTHOR:        Nathan Fiedler
#
# REVISION HISTORY:
#      Name     Date      Description
#      ----     ----      -----------
#       NF      03/07/96  Initial version
#
# DESCRIPTION:
#      This adds additional flags to PMAKE, specifically to turn
#      on linker fix-ups and turn off error checking.
#
#####################################################################

#
# Turn off error-checking.
# Include system makefile.
#
NO_EC = 1
#include <$(SYSMAKEFILE)>

