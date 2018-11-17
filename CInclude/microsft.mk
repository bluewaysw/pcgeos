##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	System Makefiles
# MODULE:	Geode creation
# FILE: 	geode.mk
# AUTHOR: 	Adam de Boor, August 31, 1992
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/31/92		Initial Revision
#
# DESCRIPTION:
#	This is a makefile that sets variables for using MSC 7.0
#	or later. It is included by geos.mk when it has been copied to
#	compiler.mk in the INCLUDE directory.
#
#	$Id: microsft.mk,v 1.1 97/04/04 15:59:11 newdeal Exp $
#
###############################################################################
#
# Where the compiler-specific include files are located
#
#if !defined(_COMPILER_MK_)
_COMPILER_MK_  = 1

COMPILER_INCLUDE_DIR	= -IT:\C700\INCLUDE
#
# Path to the compiler itself
#

# XCCOMFLAGS is intended to be filled on the command-line
#
#   -D__GEOS__ added to identify PC/GEOS usage.
#
#	-c: suppress link
#	-Zi full debug info
#	-AL: LARGE memory model
#
CPP		?= T:\c700\bin\cl.exe -E
CCOM		?= T:\c700\BIN\cl.exe
CCOM_MODEL	?= -AL
CCOMFLAGS	+= -D__GEOS__ -c -Zi $(CCOM_MODEL) $(.INCLUDES) $(COMPILER_INCLUDE_DIR) $(XCCOMFLAGS) -Gs

GOCFLAGS	+= -cm

#
# Arguments to give to MAKEDPND to invoke the compiler for generating
# dependencies.
#
COMPILER_DEPENDS	= CPP MICROSOFT7 $(CPP) $(CCOMFLAGS)

#
# Rules for creating object files with this compiler.
#
.C.EBJ		:
	$(CCOM) -DDO_ERROR_CHECKING $(CCOMFLAGS) -o$(.TARGET) $(.IMPSRC)

.C.OBJ		:
	$(CCOM) $(CCOMFLAGS) -o$(.TARGET) $(.IMPSRC)


#endif
