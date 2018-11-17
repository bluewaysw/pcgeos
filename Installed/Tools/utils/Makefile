##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	nmkmf -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Jacob A. Gabrielson, Tue Feb 25 21:23:17 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	all			create the tool for all possible architectures
#	install			create and install for all architectures
#	depend			generate dependencies for all architectures
#	sparc                   create tool for sparc
#	installsparc            create and install tool for sparc
#	dependsparc             generate dependencies for sparc
#	win32                   create tool for win32
#	installwin32            create and install tool for win32
#	dependwin32             generate dependencies for win32
#
# DESCRIPTION:
#	This makefile was automatically generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.tool
#
#	DO NOT EDIT IT, AS YOU MAY LOSE YOUR CHANGES WHEN IT IS REGENERATED
#
#	$Id: Makefile.tool,v 1.5 96/09/05 15:58:56 jacob Exp $
#
###############################################################################


#include	<geos.mk>
#include	<gpath.mk>

MACHINES	=  sparc win32
MAKEFILE	= Makefile
NAME		= utils
SYSMAKEFILE	= tool.mk
TYPE		= library

#if	defined(sun) && defined(sparc)
DEFTARGET	= sparc
#elif	defined(sun)
DEFTARGET	= sun3
#elif   defined(isi)
DEFTARGET	= isi
#else
DEFTARGET	= win32
#endif

MISRCS          = fileargs.c \
                  fileUtil.c \
                  geode.c \
                  hash.c \
                  localize.c \
                  malErr.c \
                  malloc.c \
                  memAl.c \
                  memAlLkd.c \
                  memFree.c \
                  memInfo.c \
                  memLock.c \
                  memRAl.c \
                  memRAlLk.c \
                  memUtils.c \
                  objSwap.c \
                  printf.c \
                  stClose.c \
                  stCreate.c \
                  stDest.c \
                  stDup.c \
                  stEnt.c \
                  stEntNL.c \
                  stHash.c \
                  stIndex.c \
                  stLook.c \
                  stLookNL.c \
                  stReloc.c \
                  stSearch.c \
                  sttab.c \
                  vmAl.c \
                  vmAlRd.c \
                  vmAlUnas.c \
                  vmAttach.c \
                  vmAttr.c \
                  vmClose.c \
                  vmDetach.c \
                  vmDirty.c \
                  vmEmpty.c \
                  vmFAl.c \
                  vmFFree.c \
                  vmFind.c \
                  vmFree.c \
                  vmGVers.c \
                  vmHeader.c \
                  vmInfo.c \
                  vmLock.c \
                  vmMapBlk.c \
                  vmModUID.c \
                  vmOpen.c \
                  vmSetRel.c \
                  vmUpdate.c


sparcSRCS       = $(MISRCS) sparc.md/
sparcOBJS       = sparc.md/fileargs.o \
                    sparc.md/fileUtil.o \
                    sparc.md/geode.o \
                    sparc.md/hash.o \
                    sparc.md/localize.o \
                    sparc.md/malErr.o \
                    sparc.md/malloc.o \
                    sparc.md/memAl.o \
                    sparc.md/memAlLkd.o \
                    sparc.md/memFree.o \
                    sparc.md/memInfo.o \
                    sparc.md/memLock.o \
                    sparc.md/memRAl.o \
                    sparc.md/memRAlLk.o \
                    sparc.md/memUtils.o \
                    sparc.md/objSwap.o \
                    sparc.md/printf.o \
                    sparc.md/stClose.o \
                    sparc.md/stCreate.o \
                    sparc.md/stDest.o \
                    sparc.md/stDup.o \
                    sparc.md/stEnt.o \
                    sparc.md/stEntNL.o \
                    sparc.md/stHash.o \
                    sparc.md/stIndex.o \
                    sparc.md/stLook.o \
                    sparc.md/stLookNL.o \
                    sparc.md/stReloc.o \
                    sparc.md/stSearch.o \
                    sparc.md/stTab.o \
                    sparc.md/vmAl.o \
                    sparc.md/vmAlRd.o \
                    sparc.md/vmAlUnas.o \
                    sparc.md/vmAttach.o \
                    sparc.md/vmAttr.o \
                    sparc.md/vmClose.o \
                    sparc.md/vmDetach.o \
                    sparc.md/vmDirty.o \
                    sparc.md/vmEmpty.o \
                    sparc.md/vmFAl.o \
                    sparc.md/vmFFree.o \
                    sparc.md/vmFind.o \
                    sparc.md/vmFree.o \
                    sparc.md/vmGVers.o \
                    sparc.md/vmHeader.o \
                    sparc.md/vmInfo.o \
                    sparc.md/vmLock.o \
                    sparc.md/vmMapBlk.o \
                    sparc.md/vmModUID.o \
                    sparc.md/vmOpen.o \
                    sparc.md/vmSetRel.o \
                    sparc.md/vmUpdate.o
sparcLIBS       =

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/fileargs.obj \
                    win32.md/fileUtil.obj \
                    win32.md/geode.obj \
                    win32.md/hash.obj \
                    win32.md/localize.obj \
                    win32.md/malErr.obj \
                    win32.md/malloc.obj \
                    win32.md/memAl.obj \
                    win32.md/memAlLkd.obj \
                    win32.md/memFree.obj \
                    win32.md/memInfo.obj \
                    win32.md/memLock.obj \
                    win32.md/memRAl.obj \
                    win32.md/memRAlLk.obj \
                    win32.md/memUtils.obj \
                    win32.md/objSwap.obj \
                    win32.md/printf.obj \
                    win32.md/stClose.obj \
                    win32.md/stCreate.obj \
                    win32.md/stDest.obj \
                    win32.md/stDup.obj \
                    win32.md/stEnt.obj \
                    win32.md/stEntNL.obj \
                    win32.md/stHash.obj \
                    win32.md/stIndex.obj \
                    win32.md/stLook.obj \
                    win32.md/stLookNL.obj \
                    win32.md/stReloc.obj \
                    win32.md/stSearch.obj \
                    win32.md/sttab.obj \
                    win32.md/vmAl.obj \
                    win32.md/vmAlRd.obj \
                    win32.md/vmAlUnas.obj \
                    win32.md/vmAttach.obj \
                    win32.md/vmAttr.obj \
                    win32.md/vmClose.obj \
                    win32.md/vmDetach.obj \
                    win32.md/vmDirty.obj \
                    win32.md/vmEmpty.obj \
                    win32.md/vmFAl.obj \
                    win32.md/vmFFree.obj \
                    win32.md/vmFind.obj \
                    win32.md/vmFree.obj \
                    win32.md/vmGVers.obj \
                    win32.md/vmHeader.obj \
                    win32.md/vmInfo.obj \
                    win32.md/vmLock.obj \
                    win32.md/vmMapBlk.obj \
                    win32.md/vmModUID.obj \
                    win32.md/vmOpen.obj \
                    win32.md/vmSetRel.obj \
                    win32.md/vmUpdate.obj
win32LIBS       =


SUBDIRS         = CVS

#if exists(local.mk)
#include	"local.mk"
#else
#include	<$(SYSMAKEFILE)>
#endif

#if	exists(sparc.md/dependencies.mk)
#include	"sparc.md/dependencies.mk"
#endif

#if	exists(win32.md/dependencies.mk)
#include	"win32.md/dependencies.mk"
#endif


# Allow mkmf
