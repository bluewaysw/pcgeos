##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	VGA8 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:07:43 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	vga8ec.geo		create an error-checking version
#	vga8.geo		create a non error-checking version
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

GEODE           = vga8
LIBNAME         = video
PROTOCONST      = VIDEO
OBJS            = vga8Manager.obj
SRCS            = vga8Admin.asm vga8Chars.asm vga8DevInfo.asm\
                  vga8Dither.asm vga8EscTab.asm vga8GenChar.asm\
                  vga8Manager.asm vga8Output.asm vga8Palette.asm\
                  vga8Pointer.asm vga8Raster.asm vga8StringTab.asm\
                  vga8Tables.asm vga8Under.asm vga8Utils.asm\
                  vidcomChars.asm vidcomEntry.asm vidcomEscape.asm\
                  vidcomExclBounds.asm vidcomFont.asm vidcomInfo.asm\
                  vidcomLine.asm vidcomOutput.asm vidcomPalette.asm\
                  vidcomPolygon.asm vidcomPutLine.asm vidcomRaster.asm\
                  vidcomRegion.asm vidcomTables.asm vidcomUtils.asm\
                  vidcomXOR.asm vga8Constant.def vga8Macro.def\
                  vga8Variable.def
LOBJS           =

SUBDIRS         =
PRODUCTS	= 

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

#if exists(WIN_DEMO/$(DEPFILE))
#include "WIN_DEMO/$(DEPFILE)"
#endif

# Allow mkmf
