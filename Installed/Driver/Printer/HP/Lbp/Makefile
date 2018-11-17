##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Lbp -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:35:54 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	lbpec.geo		create an error-checking version
#	lbp.geo		create a non error-checking version
#	full			create both of the above, plus tags
#	part			create only the error-checking version
#	tags			create a tags file from all the sources
#	depend			generate source file dependencies
#
# DESCRIPTION:
#	This makefile was automatically generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.geode
#
#	DO NOT EDIT IT, AS YOU MAY LOSE YOUR CHANGES WHEN IT IS REGENERATED
#
#	$Id: Makefile.geode,v 1.4 92/01/03 20:17:45 johnm Exp $
#
###############################################################################

GEODE           = lbp
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = lbpManager.obj
SRCS            = capsl2Info.asm capsl3Info.asm lbpControlCodes.asm\
                  lbpDriverInfo.asm lbpManager.asm printcomASFOnlyPage.asm\
                  printcomAdmin.asm printcomCapslCursor.asm\
                  printcomCapslDialog.asm printcomCapslGraphics.asm\
                  printcomCapslJob.asm printcomCapslStyles.asm\
                  printcomCapslText.asm printcomDotMatrixBuffer.asm\
                  printcomEntry.asm printcomHexStream.asm printcomInfo.asm\
                  printcomNoColor.asm printcomNoEscapes.asm\
                  printcomTables.asm lbpConstant.def
LOBJS           =

SUBDIRS         = Zoomer

#include	<geos.mk>		# system directory definitions
#include	<gpath.mk>		# set search paths for files

MAKEFILE	= Makefile
SYSMAKEFILE	= geode.mk

#if exists(local.mk)
#	include	"local.mk"
#else
#	include	<$(SYSMAKEFILE)>
#endif

#if 	exists($(DEPFILE))
#include	"$(DEPFILE)"
#endif

# Allow mkmf
