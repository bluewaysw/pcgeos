##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	QuietJet -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:36:18 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	quietjetec.geo		create an error-checking version
#	quietjet.geo		create a non error-checking version
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

GEODE           = quietjet
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = quietjetManager.obj
SRCS            = Cursor/cursorConvert192.asm Cursor/cursorPCLCommon.asm\
                  Cursor/cursorSetCursorPCL.asm Graphics/graphicsCommon.asm\
                  Graphics/graphicsPCLScanline.asm\
                  Graphics/graphicsPrintSwathPCL.asm Styles/stylesGet.asm\
                  Styles/stylesSRBold.asm Styles/stylesSRNLQ.asm\
                  Styles/stylesSRUnderline.asm Styles/stylesSet.asm\
                  Styles/stylesTest.asm Text/Font/fontQuietjetInfo.asm\
                  Text/textGetLineSpacing.asm\
                  Text/textLoadNoISOSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm UI/uiEval.asm\
                  UI/uiEvalQuietjet.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm printcomAdmin.asm\
                  printcomDotMatrixBuffer.asm printcomEntry.asm\
                  printcomInfo.asm printcomNoColor.asm\
                  printcomNoEscapes.asm printcomPCLJob.asm\
                  printcomPCLPage.asm printcomPCLStream.asm\
                  printcomTables.asm qjetInfo.asm qjetplusInfo.asm\
                  quietjetControlCodes.asm quietjetCursor.asm\
                  quietjetDialog.asm quietjetDriverInfo.asm\
                  quietjetGraphics.asm quietjetManager.asm\
                  quietjetStyles.asm quietjetText.asm quietjetConstant.def\
                  quietjet.ui
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
