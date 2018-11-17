###########################################################################
#
#	Copyright (c) Global PC 1999.  All rights reserved.
#	GLOBAL PC CONFIDENTIAL
#
# REVISION HISTORY:
#	Name	Date		Description
#	-----	----		------------
#	chr	1/24/99		Initial revision
#
# 	Local makefile for JS library.
#
# DESCRIPTION:
#
# 	$Id$
#
############################################################################

#include <$(SYSMAKEFILE)>

XCCOMFLAGS = -I$(CINCLUDE_DIR)/JS -Z -d -O -WDE -OW
#XCCOMFLAGS += -DCOMPILE_OPTION_PROFILING_ON
#LINKFLAGS += -DCOMPILE_OPTION_PROFILING_ON 
#LINKFLAGS += -DGEOS_MAPPED_MALLOC

