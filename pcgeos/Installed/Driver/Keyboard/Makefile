##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Keyboard -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:21:06 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	keyboardec.geo		create an error-checking version
#	keyboard.geo		create a non error-checking version
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

GEODE           = keyboard
LIBNAME         = kbd
PROTOCONST      = KEYBOARD
OBJS            = keyboard.obj
SRCS            = keyboard.asm keyboardHotkey.asm keyboardInit.asm\
                  keyboardProcess.asm keyboardStrings.asm keyboardUtils.asm\
                  keyboardConstant.def keyboardGeode.def keyboardMacro.def\
                  keyboardVariable.def kmapUS.def kmapUSDBCS.def
LOBJS           =

SUBDIRS         = Canadian DBCS Danish Dutch Dvorak French GDI German\
                  Italian Norwegian Portuguese Spanish Swedish Tandy1000\
                  Toshiba UK

PRODUCTS	= DBCS

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
