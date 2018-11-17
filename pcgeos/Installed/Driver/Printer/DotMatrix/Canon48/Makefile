##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Canon48 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:42:38 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	canon48ec.geo		create an error-checking version
#	canon48.geo		create a non error-checking version
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

GEODE           = canon48
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = canon48Manager.obj
SRCS            = Color/Correct/correctGamma175.asm\
                  Color/Correct/correctGamma21.asm\
                  Text/Font/fontCanonBJInfo.asm\
                  Text/Font/fontIBMPPDSInfo.asm Text/textGetLineSpacing.asm\
                  Text/textLoadNoISOSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm UI/uiEval.asm\
                  UI/uiEval12ASFSymbol.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm canon48ControlCodes.asm\
                  canon48Dialog.asm canon48DriverInfo.asm\
                  canon48Manager.asm canon48Text.asm canon48bj10eInfo.asm\
                  canon48execjetInfo.asm canon48generInfo.asm\
                  canon48generwInfo.asm printcomAdmin.asm\
                  printcomCanonBJCursor.asm printcomCanonBJGraphics.asm\
                  printcomDotMatrixBuffer.asm printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomEpsonJob.asm\
                  printcomIBMPPDS24Styles.asm printcomInfo.asm\
                  printcomNoColor.asm printcomNoEscapes.asm\
                  printcomStream.asm printcomTables.asm canon48Constant.def\
                  canon48.ui
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
