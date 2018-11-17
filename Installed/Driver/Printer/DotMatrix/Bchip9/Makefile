##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Bchip9 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:40:27 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	bchip9ec.geo		create an error-checking version
#	bchip9.geo		create a non error-checking version
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

GEODE           = bchip9
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = bchip9Manager.obj
SRCS            = Color/Correct/correctGamma20.asm\
                  Text/Font/fontEpsonMXInfo.asm Text/textGetLineSpacing.asm\
                  Text/textLoadBchipSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm bchip9ControlCodes.asm\
                  bchip9DriverInfo.asm bchip9Manager.asm bchip9Text.asm\
                  bchip9generInfo.asm bchip9generwInfo.asm\
                  printcomAdmin.asm printcomCountryDialog.asm\
                  printcomDotMatrixBuffer.asm printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomEpsonJob.asm\
                  printcomEpsonMXCursor.asm printcomEpsonMXGraphics.asm\
                  printcomEpsonStyles.asm printcomInfo.asm\
                  printcomNoColor.asm printcomNoEscapes.asm\
                  printcomStream.asm printcomTables.asm bchip9Constant.def
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
