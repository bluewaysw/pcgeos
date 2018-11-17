##############################################################################
#
# 	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Text File Editor
# FILE: 	local.mk
# AUTHOR: 	Don Reeves, Apr  8, 1994
#
#	$Id: local.mk,v 1.1 97/04/04 16:54:50 newdeal Exp $
#
###############################################################################
#
# Define the features to include:
#	SPELL_CONTROL	= include spell-check feature (which requires Spell
#	    	    	  library, something not on the Zoomer)
#
ASMFLAGS	+= -DSPELL_CONTROL
UICFLAGS	+= -DSPELL_CONTROL

ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

# Define SEND_CONTROL during linking if it's not a NIKE or PIZZA version
LINKFLAGS += $(.TARGET:H:NNIKE:NPIZZA:NPENELOPE:S/^/-DSEND_CONTROL/:X\\[-DSEND_CONTROL\\]*)

# Read and write checking.  It's a good thing.
ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK

#include <$(SYSMAKEFILE)>
