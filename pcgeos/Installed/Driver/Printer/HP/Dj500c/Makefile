##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Dj500c -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:37:14 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	dj500cec.geo		create an error-checking version
#	dj500c.geo		create a non error-checking version
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

GEODE           = dj500c
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = dj500cManager.obj
SRCS            = Color/Correct/correctDJ500C.asm dj500cControlCodes.asm\
                  dj500cDriverInfo.asm dj500cInfo.asm dj500cManager.asm\
                  nccCMYInfo.asm pjxl300Info.asm printcomAdmin.asm\
                  printcomDeskjetCCursor.asm printcomDeskjetCMYGraphics.asm\
                  printcomDeskjetDialog.asm printcomEntry.asm\
                  printcomInfo.asm printcomNoColor.asm\
                  printcomNoEscapes.asm printcomNoStyles.asm\
                  printcomNoText.asm printcomPCLBuffer.asm\
                  printcomPCLJob.asm printcomPCLPage.asm\
                  printcomPCLStream.asm printcomTables.asm\
                  dj500cConstant.def
LOBJS           =

SUBDIRS         = Pizza

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
