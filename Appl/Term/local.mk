##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	GeoComm -- special definitions
# FILE: 	local.mk
# AUTHOR: 	brianc, 10/21/91
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	brianc	10/21/91	Initial Revision
#
# DESCRIPTION:
#	Special definitions for GeoComm
#
#	$Id: local.mk,v 1.1 97/04/04 16:56:17 newdeal Exp $
#
###############################################################################

#
# Define the Bullet-specific version
#
#ASMFLAGS	+= -DBULLET
#UICFLAGS	+= -DBULLET

ASMFLAGS	+= -wunref -wunref_local
LINKFLAGS	+= -Wunref

ASMFLAGS 	+= -DREAD_CHECK -DWRITE_CHECK

PCXREF		+= -sRESPONDER/termec.sym

#include    <$(SYSMAKEFILE)>

#######################################################################
#
#	Dependencies for product-specific include files
#
#######################################################################

#
# All modules depend on RESPINCLUDES files. Each module has its own
# dependency line so that individual files to be included for a
# particular module can be added easily without affecting the others.
#
# For the list of files to be included in RESPINCLUDES, see
# termInclude.def 
# 
RESPINCLUDES	= 	foam.def viewer.def contlog.def\
			Internal/Resp/vp.def Internal/Resp/vpmisc.def\
			Internal/Resp/eci_oem.def datarec.def\
			accpnt.def sysstats.def Internal/gstate.def
RESPONDER/Main.eobj \
RESPONDER/Main.obj	: $(RESPINCLUDES)

RESPONDER/Serial.eobj \
RESPONDER/Serial.obj	: $(RESPINCLUDES)

RESPONDER/Screen.eobj \
RESPONDER/Screen.obj	: $(RESPINCLUDES)

RESPONDER/Utils.eobj \
RESPONDER/Utils.obj	: $(RESPINCLUDES)

RESPONDER/Script.eobj \
RESPONDER/Script.obj	: $(RESPINCLUDES)

RESPONDER/FSM.eobj \
RESPONDER/FSM.obj	: $(RESPINCLUDES)

RESPONDER/File.eobj \
RESPONDER/File.obj	: $(RESPINCLUDES)

