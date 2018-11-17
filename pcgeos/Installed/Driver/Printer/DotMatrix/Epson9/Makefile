##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epson9 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:39:10 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	epson9ec.geo		create an error-checking version
#	epson9.geo		create a non error-checking version
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

GEODE           = epson9
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = epson9Manager.obj
SRCS            = Color/Correct/correctGamma30.asm\
                  Color/Correct/correctInk.asm epson9ControlCodes.asm\
                  epson9DriverInfo.asm epson9Manager.asm\
                  epson9dfx5000Info.asm epson9ex1000Info.asm\
                  epson9ex800Info.asm epson9fx185Info.asm\
                  epson9fx286eInfo.asm epson9fx85Info.asm\
                  epson9fx86eInfo.asm epson9generInfo.asm\
                  epson9generwInfo.asm epson9m1809Info.asm\
                  printcomAdmin.asm printcomCountryDialog.asm\
                  printcomDotMatrixBuffer.asm printcomDotMatrixPage.asm\
                  printcomEntry.asm printcomEpsonColor.asm\
                  printcomEpsonFXCursor.asm printcomEpsonFXGraphics.asm\
                  printcomEpsonFXText.asm printcomEpsonJob.asm\
                  printcomEpsonStyles.asm printcomInfo.asm\
                  printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm epson9Constant.def
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
