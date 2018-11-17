##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epson48 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:45:37 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	epson48ec.geo		create an error-checking version
#	epson48.geo		create a non error-checking version
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

GEODE           = epson48
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = epson48Manager.obj
SRCS            = Color/Correct/correctGamma175.asm\
                  Color/Correct/correctGamma20.asm\
                  Color/Correct/correctInk.asm UI/uiEval.asm\
                  UI/uiEval12ASFCountry.asm UI/uiGetNoMain.asm\
                  UI/uiGetOptions.asm epson48ControlCodes.asm\
                  epson48Dialog.asm epson48DriverInfo.asm\
                  epson48Manager.asm epson48bjc800Info.asm\
                  epson48bjc800MInfo.asm epson48sq1170Info.asm\
                  epson48sq870Info.asm epson48stylus800Info.asm\
                  printcomAdmin.asm printcomDotMatrixBuffer.asm\
                  printcomDotMatrixPage.asm printcomEntry.asm\
                  printcomEpsonColor.asm printcomEpsonJob.asm\
                  printcomEpsonLQ2Cursor.asm printcomEpsonLQ4Graphics.asm\
                  printcomEpsonLQText.asm printcomEpsonStyles.asm\
                  printcomInfo.asm printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm epson48Constant.def epson48.ui
LOBJS           =

SUBDIRS         = JEDI Pizza Zoomer

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
