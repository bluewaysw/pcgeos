##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Preflf -- Makefile
# FILE: 	Makefile
# AUTHOR: 	, Mon Apr  7 21:10:43 PDT 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	preflfec.geo		create an error-checking version
#	preflf.geo		create a non error-checking version
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

GEODE           = preflf
OBJS            = preflf.obj
SRCS            = preflf.asm preflfDialog.asm preflfFontItemGroup.asm\
                  preflfMinuteValue.asm preflfSameBooleanGroup.asm\
                  preflfWidthValue.asm preflf.def preflfDialog.def\
                  preflfFontItemGroup.def preflfMinuteValue.def\
                  preflfSameBooleanGroup.def preflfWidthValue.def preflf.ui
LOBJS           =

LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = preflf
SUBDIRS         = Art

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
