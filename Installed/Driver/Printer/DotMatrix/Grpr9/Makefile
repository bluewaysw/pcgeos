##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Grpr9 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:46:20 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	grpr9ec.geo		create an error-checking version
#	grpr9.geo		create a non error-checking version
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

GEODE           = grpr9
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = grpr9Manager.obj
SRCS            = Styles/stylesGet.asm Styles/stylesSRBold.asm\
                  Styles/stylesSRCondensed.asm Styles/stylesSRDblWidth.asm\
                  Styles/stylesSRNLQ.asm Styles/stylesSROverline.asm\
                  Styles/stylesSRSubSuperScript.asm\
                  Styles/stylesSRUnderline.asm Styles/stylesSet.asm\
                  Styles/stylesTest.asm Text/Font/fontIBMGrprInfo.asm\
                  Text/textGetLineSpacing.asm\
                  Text/textLoadNoISOSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm grpr9ControlCodes.asm\
                  grpr9DriverInfo.asm grpr9Manager.asm grpr9Styles.asm\
                  grpr9Text.asm grpr9grprInfo.asm grpr9pp1Info.asm\
                  printcomAdmin.asm printcomDotMatrixBuffer.asm\
                  printcomDotMatrixPage.asm printcomEntry.asm\
                  printcomEpsonColor.asm printcomEpsonFXGraphics.asm\
                  printcomEpsonMXCursor.asm printcomIBMJob.asm\
                  printcomInfo.asm printcomNoEscapes.asm\
                  printcomPaperOnlyDialog.asm printcomStream.asm\
                  printcomTables.asm grpr9Constant.def grpr9.ui
LOBJS           =

SUBDIRS         = JEDI Zoomer

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
