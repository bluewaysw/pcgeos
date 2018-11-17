##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Citoh9 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:40:04 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	citoh9ec.geo		create an error-checking version
#	citoh9.geo		create a non error-checking version
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

GEODE           = citoh9
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = citoh9Manager.obj
SRCS            = Color/Correct/correctInk.asm Text/Font/fontCitohInfo.asm\
                  Text/textGetLineSpacing.asm\
                  Text/textLoadNoISOSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm UI/uiEval.asm\
                  UI/uiEval0ASFCountry.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm citoh9ControlCodes.asm\
                  citoh9DMPInfo.asm citoh9Dialog.asm citoh9DriverInfo.asm\
                  citoh9IWriter2Info.asm citoh9Manager.asm citoh9Text.asm\
                  citoh9generInfo.asm citoh9generwInfo.asm\
                  printcomAdmin.asm printcomCitohColor.asm\
                  printcomCitohCursor.asm printcomCitohGraphics.asm\
                  printcomDotMatrixBuffer.asm printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomEpsonJob.asm\
                  printcomEpsonStyles.asm printcomHex0Stream.asm\
                  printcomInfo.asm printcomNoEscapes.asm printcomTables.asm\
                  citoh9Constant.def citoh9.ui
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
