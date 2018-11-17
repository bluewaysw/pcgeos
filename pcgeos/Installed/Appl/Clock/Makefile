##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Clock -- Makefile
# FILE: 	Makefile
# AUTHOR: 	, Mon Apr  7 13:20:43 PDT 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	clockec.geo		create an error-checking version
#	clock.geo		create a non error-checking version
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

GEODE           = clock
OBJS            = clock.obj clockApplication.obj clockLocationList.obj\
                  clockRegion.obj visAnalogClock.obj visClock.obj\
                  visDigitalClock.obj visHermanClock.obj\
                  visSkeletonClock.obj
SRCS            = clock.asm clockApplication.asm clockLocationList.asm\
                  clockRegion.asm visAnalogClock.asm visClock.asm\
                  visDigitalClock.asm visHermanClock.asm\
                  visSkeletonClock.asm clock.def clockRegion.def\
                  visAnalogClock.def visClock.def visDigitalClock.def\
                  visHermanClock.def visSkeletonClock.def analogClock.ui\
                  clock.ui digitalClock.ui hermanClock.ui skeletonClock.ui
LOBJS           =

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
