##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	VidMem -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:09:27 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	vidmemec.geo		create an error-checking version
#	vidmem.geo		create a non error-checking version
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

GEODE           = vidmem
UI_TO_RDFS      =
CMYK            = cmykCluster.asm cmykColor.asm cmykColorRaster.asm\
                  cmykDither.asm cmykEntry.asm cmykEscTab.asm\
                  cmykGenChar.asm cmykManager.asm cmykPalette.asm\
                  cmykRaster.asm cmykTables.asm cmykUtils.asm\
                  cmykConstant.def cmykMacro.def cmykVariable.def
CLR24           = clr24Chars.asm clr24Color.asm clr24Entry.asm\
                  clr24EscTab.asm clr24GenChar.asm clr24Manager.asm\
                  clr24Output.asm clr24Palette.asm clr24Tables.asm\
                  clr24Constant.def clr24Macro.def clr24Variable.def
CLR4            = clr4Chars.asm clr4Color.asm clr4Entry.asm clr4EscTab.asm\
                  clr4GenChar.asm clr4Manager.asm clr4Output.asm\
                  clr4Palette.asm clr4Raster.asm clr4Tables.asm\
                  clr4Utils.asm clr4Constant.def clr4Macro.def\
                  clr4Variable.def
CLR8            = clr8Color.asm clr8Dither.asm clr8Entry.asm clr8EscTab.asm\
                  clr8GenChar.asm clr8Manager.asm clr8Palette.asm\
                  clr8Raster.asm clr8Tables.asm clr8Utils.asm\
                  clr8Constant.def clr8Macro.def clr8Variable.def
MAIN            = mainDevInfo.asm mainMain.asm mainManager.asm\
                  mainTables.asm mainVariable.def
MONO            = monoCluster.asm monoEntry.asm monoEscTab.asm\
                  monoEscape.asm monoGenChar.asm monoManager.asm\
                  monoPalette.asm monoRaster.asm monoTables.asm\
                  monoUtils.asm monoConstant.def monoMacro.def\
                  monoVariable.def
OBJS            =

COMMON          = vidmemConstant.def vidmemGeode.def vidmemGlobal.def\
                  vidmemInclude.def vidmemMacro.def vidmemResource.def\
                  vidmemVariable.def
LIBNAME         = video
PROTOCONST      = VIDEO
LOBJS           =
MODULES         = CMYK Clr24 Clr4 Clr8 Main Mono
CMODULES        =
SRCS            = $(CMYK) $(CLR24) $(CLR4) $(CLR8) $(MAIN) $(MONO)\
                  $(COMMON)
#SUBDIRS         = CMYK Clr24 Clr4 Clr8 DBCS JEDI Main Mono PIZZA

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

#if 	exists(DBCS/$(DEPFILE))
#include	"DBCS/$(DEPFILE)"
#endif

# Allow mkmf
