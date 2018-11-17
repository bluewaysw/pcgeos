##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epson24 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:39:53 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	epson24ec.geo		create an error-checking version
#	epson24.geo		create a non error-checking version
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

GEODE           = epson24
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = epson24Manager.obj
SRCS            = Color/Correct/correctInk.asm epson24ControlCodes.asm\
                  epson24DriverInfo.asm epson24Manager.asm\
                  epson24generInfo.asm epson24generwInfo.asm\
                  epson24lq1000Info.asm epson24lq1500Info.asm\
                  epson24lq2500Info.asm epson24lq500Info.asm\
                  epson24lq800Info.asm epson24lq900Info.asm\
                  printcomAdmin.asm printcomCountryDialog.asm\
                  printcomDotMatrixBuffer.asm printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomEpsonColor.asm\
                  printcomEpsonJob.asm printcomEpsonLQ1Cursor.asm\
                  printcomEpsonLQ1Graphics.asm printcomEpsonLQText.asm\
                  printcomEpsonStyles.asm printcomInfo.asm\
                  printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm epson24Constant.def
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
