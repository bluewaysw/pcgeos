##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	VGA -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:07:30 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	vgaec.geo		create an error-checking version
#	vga.geo		create a non error-checking version
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

GEODE           = vga
LIBNAME         = video
PROTOCONST      = VIDEO
OBJS            = vgaManager.obj
SRCS            = vgaAdmin.asm vgaDevInfo.asm vgaEscTab.asm vgaManager.asm\
                  vgaPalette.asm vgaStringTab.asm vgaTables.asm\
                  vgacomChars.asm vgacomGenChar.asm vgacomOutput.asm\
                  vgacomPalette.asm vgacomPointer.asm vgacomRaster.asm\
                  vgacomTables.asm vgacomUtils.asm vidcomChars.asm\
                  vidcomDither.asm vidcomEntry.asm vidcomEscape.asm\
                  vidcomExclBounds.asm vidcomFont.asm vidcomInfo.asm\
                  vidcomLine.asm vidcomOutput.asm vidcomPalette.asm\
                  vidcomPolygon.asm vidcomPutLine.asm vidcomRaster.asm\
                  vidcomRegion.asm vidcomTables.asm vidcomUnder.asm\
                  vidcomUtils.asm vidcomXOR.asm vgaConstant.def
LOBJS           =

SUBDIRS         = DBCS PIZZA

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
