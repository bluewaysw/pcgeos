##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Star9 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:38:37 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	star9ec.geo		create an error-checking version
#	star9.geo		create a non error-checking version
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

GEODE           = star9
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = star9Manager.obj
SRCS            = Cursor/cursor1ScanlineFeed.asm\
                  Cursor/cursorConvert144.asm\
                  Cursor/cursorDotMatrixCommon.asm\
                  Cursor/cursorPrFormFeed72.asm\
                  Cursor/cursorPrLineFeedExe.asm\
                  Cursor/cursorSetCursorTab72.asm\
                  Text/Font/fontStarInfo.asm Text/textGetLineSpacing.asm\
                  Text/textLoadEpsonSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm UI/uiEval.asm\
                  UI/uiEval0ASFCountry.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm printcomAdmin.asm\
                  printcomDotMatrixBuffer.asm printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomEpsonJob.asm\
                  printcomEpsonStyles.asm printcomInfo.asm\
                  printcomNoColor.asm printcomNoEscapes.asm\
                  printcomStarSGGraphics.asm printcomStream.asm\
                  printcomTables.asm star9ControlCodes.asm star9Cursor.asm\
                  star9Dialog.asm star9DriverInfo.asm star9Manager.asm\
                  star9Text.asm star9generInfo.asm star9generwInfo.asm\
                  star9Constant.def star9.ui
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
