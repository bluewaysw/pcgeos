##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Eprx9 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:41:32 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	eprx9ec.geo		create an error-checking version
#	eprx9.geo		create a non error-checking version
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

GEODE           = eprx9
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = eprx9Manager.obj
SRCS            = Color/Correct/correctGamma30.asm UI/uiEval.asm\
                  UI/uiEval0ASFCountry.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm eprx9ControlCodes.asm eprx9Dialog.asm\
                  eprx9DriverInfo.asm eprx9Manager.asm eprx9rx100Info.asm\
                  eprx9rx80Info.asm printcomAdmin.asm\
                  printcomDotMatrixBuffer.asm printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomEpsonFXGraphics.asm\
                  printcomEpsonJob.asm printcomEpsonRXCursor.asm\
                  printcomEpsonRXText.asm printcomEpsonStyles.asm\
                  printcomInfo.asm printcomNoColor.asm\
                  printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm eprx9Constant.def eprx9.ui
LOBJS           =

SUBDIRS         =

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
