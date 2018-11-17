##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Oki9 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:40:48 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	oki9ec.geo		create an error-checking version
#	oki9.geo		create a non error-checking version
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

GEODE           = oki9
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = oki9Manager.obj
SRCS            = Styles/stylesGet.asm Styles/stylesSRBold.asm\
                  Styles/stylesSRItalic.asm Styles/stylesSRNLQ.asm\
                  Styles/stylesSRSubscript.asm\
                  Styles/stylesSRSuperscript.asm\
                  Styles/stylesSRUnderline.asm Styles/stylesSet.asm\
                  Styles/stylesTest.asm UI/uiEval.asm UI/uiEvalNoASF.asm\
                  UI/uiGetNoMain.asm UI/uiGetOptions.asm oki992Info.asm\
                  oki993Info.asm oki9ControlCodes.asm oki9Dialog.asm\
                  oki9DriverInfo.asm oki9Manager.asm oki9Styles.asm\
                  printcomAdmin.asm printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomHex0Stream.asm\
                  printcomIBMJob.asm printcomInfo.asm printcomNoColor.asm\
                  printcomNoEscapes.asm printcomOkiBuffer.asm\
                  printcomOkiCursor.asm printcomOkiGraphics.asm\
                  printcomOkiText.asm printcomTables.asm oki9Constant.def\
                  oki9.ui
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
