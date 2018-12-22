##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Compress -- Makefile
# FILE: 	Makefile
# AUTHOR: 	, Wed Apr 16 17:15:06 PDT 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	compressec.geo		create an error-checking version
#	compress.geo		create a non error-checking version
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

GEODE           = compress
OBJS            = compressManager.obj
SRCS            = compressIO.asm compressMain.asm compressManager.asm\
                  compressConstant.def compressMacro.def\
                  compressVariable.def
LOBJS           = 

LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = compress
SUBDIRS         =

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
