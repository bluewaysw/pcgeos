##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PScript -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:47:08 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	pscriptec.geo		create an error-checking version
#	pscript.geo		create a non error-checking version
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

GEODE           = pscript
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = pscriptManager.obj
SRCS            = Color/Correct/correctInk.asm Color/colorGetFormat.asm\
                  Color/colorSetNone.asm adobeLJ2cartf35Info.asm\
                  adobeLJ2cartfTC1Info.asm adobeLJ2cartfTC2Info.asm\
                  appleLW2NTf35Info.asm appleLWf13Info.asm hpLJ4psInfo.asm\
                  hpLJColorf35Info.asm ibm4019f17Info.asm\
                  ibm4019f39Info.asm ibm4079f35Info.asm ibm4216f43Info.asm\
                  necColor40f17Info.asm necColorf35Info.asm\
                  printcomEntry.asm printcomInfo.asm printcomNoStyles.asm\
                  printcomNoText.asm printcomPScriptDialog.asm\
                  printcomPScriptJob.asm printcomStream.asm\
                  printcomTables.asm pscriptAdmin.asm\
                  pscriptControlCodes.asm pscriptCursor.asm\
                  pscriptDriverInfo.asm pscriptGraphics.asm\
                  pscriptManager.asm pscriptPDL.asm pscriptPage.asm\
                  pscriptProlog.asm pscriptTables.asm pscriptUtils.asm\
                  pscriptgenerCf35Info.asm pscriptgenerf13Info.asm\
                  pscriptgenerf17Info.asm pscriptgenerf35Info.asm\
                  pscriptgenerf39cartInfo.asm qmsColorScriptf35Info.asm\
                  qmsPS410f43Info.asm pscriptConstant.def\
                  pscriptInclude.def pscriptMacro.def pscriptResource.def\
                  pscriptVariable.def
LOBJS           =

SUBDIRS         = JEDI RESPONDER Zoomer

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
