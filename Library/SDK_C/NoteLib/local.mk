##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	SDK
# FILE: 	local.mk
# AUTHOR: 	Ed Ballot, July 31 1996
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	EB	7/31/96    	Initial version
#
# DESCRIPTION:
#	local makefile for NoteLib sample library
#
#	$Id: local.mk,v 1.1 97/04/07 10:44:01 newdeal Exp $
#
###############################################################################

# If you don't want to type "pmake lib", you can tell Glue
# and LDF file is desireable by adding the -l flag
#LINKFLAGS += -l

# Tell Goc the name of the library that was specified with @deflib
# (See notelib.goh)
GOCFLAGS  += -L notelib

#include <$(SYSMAKEFILE)>

