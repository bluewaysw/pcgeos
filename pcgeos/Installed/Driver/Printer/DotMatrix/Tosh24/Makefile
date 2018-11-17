##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Tosh24 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:40:15 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	tosh24ec.geo		create an error-checking version
#	tosh24.geo		create a non error-checking version
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

GEODE           = tosh24
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = toshiba24Manager.obj
SRCS            = Styles/stylesGet.asm Styles/stylesSRBold.asm\
                  Styles/stylesSRCondensed.asm Styles/stylesSRDblWidth.asm\
                  Styles/stylesSRItalic.asm Styles/stylesSRNLQ.asm\
                  Styles/stylesSRShadow.asm Styles/stylesSRUnderline.asm\
                  Styles/stylesSet.asm Styles/stylesTest.asm\
                  Text/Font/fontToshibaInfo.asm Text/textGetLineSpacing.asm\
                  Text/textLoadNoISOSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm UI/uiEval.asm\
                  UI/uiEval1ASFCountry.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm printcomAdmin.asm\
                  printcomDotMatrixBuffer.asm printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomEpsonJob.asm\
                  printcomHex0Stream.asm printcomInfo.asm\
                  printcomNoColor.asm printcomNoEscapes.asm\
                  printcomTables.asm printcomToshibaCursor.asm\
                  printcomToshibaGraphics.asm toshiba24ControlCodes.asm\
                  toshiba24Dialog.asm toshiba24DriverInfo.asm\
                  toshiba24Manager.asm toshiba24Styles.asm\
                  toshiba24Text.asm toshiba24p321Info.asm\
                  toshiba24p351Info.asm toshiba24Constant.def toshiba24.ui
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
