##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Eplx9 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:44:52 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	eplx9ec.geo		create an error-checking version
#	eplx9.geo		create a non error-checking version
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

GEODE           = eplx9
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = eplx9Manager.obj
SRCS            = Color/Correct/correctInk.asm UI/uiEval.asm\
                  UI/uiEval1ASFCountry.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm eplx9ControlCodes.asm eplx9Dialog.asm\
                  eplx9DriverInfo.asm eplx9Manager.asm eplx9fx100Info.asm\
                  eplx9fx80Info.asm eplx9jx80Info.asm eplx9lx80Info.asm\
                  printcomAdmin.asm printcomDotMatrixBuffer.asm\
                  printcomDotMatrixPage.asm printcomEntry.asm\
                  printcomEpsonColor.asm printcomEpsonFXGraphics.asm\
                  printcomEpsonFXText.asm printcomEpsonJob.asm\
                  printcomEpsonMXCursor.asm printcomEpsonStyles.asm\
                  printcomInfo.asm printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm eplx9Constant.def eplx9.ui
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
