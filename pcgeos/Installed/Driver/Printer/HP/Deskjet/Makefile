##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Deskjet -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:35:33 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	deskjetec.geo		create an error-checking version
#	deskjet.geo		create a non error-checking version
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

GEODE           = deskjet
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = deskjetManager.obj
SRCS            = Color/Correct/correctGamma175.asm\
                  Color/Correct/correctGamma21.asm deskjetControlCodes.asm\
                  deskjetDriverInfo.asm deskjetManager.asm\
                  deskjetdjInfo.asm printcomAdmin.asm\
                  printcomDeskjetCursor.asm printcomDeskjetDialog.asm\
                  printcomDeskjetGraphics.asm printcomEntry.asm\
                  printcomInfo.asm printcomNoColor.asm\
                  printcomNoEscapes.asm printcomPCLBuffer.asm\
                  printcomPCLJob.asm printcomPCLPage.asm\
                  printcomPCLStream.asm printcomPCLStyles.asm\
                  printcomPCLText.asm printcomTables.asm\
                  deskjetConstant.def
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
