##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epmx9 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:41:43 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	epmx9ec.geo		create an error-checking version
#	epmx9.geo		create a non error-checking version
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

GEODE           = epmx9
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = epmx9Manager.obj
SRCS            = Color/Correct/correctGamma20.asm UI/uiEval.asm\
                  UI/uiEval0ASFCountry.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm epmx9ControlCodes.asm epmx9Dialog.asm\
                  epmx9DriverInfo.asm epmx9Manager.asm epmx9mx100Info.asm\
                  epmx9mx80Info.asm printcomAdmin.asm\
                  printcomDotMatrixBuffer.asm printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomEpsonJob.asm\
                  printcomEpsonMXCursor.asm printcomEpsonMXGraphics.asm\
                  printcomEpsonMXText.asm printcomEpsonStyles.asm\
                  printcomInfo.asm printcomNoColor.asm\
                  printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm epmx9Constant.def epmx9.ui
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
