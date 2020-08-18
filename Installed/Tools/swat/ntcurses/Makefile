##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	ntcurses -- Makefile
# FILE: 	Makefile
# AUTHOR: 	Adam de Boor, Thu Jan 20 20:45:46 PST 1994
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
#
# DESCRIPTION:
#	This makefile was automatically generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.tool
#
#	DO NOT EDIT IT, AS YOU MAY LOSE YOUR CHANGES WHEN IT IS REGENERATED
#
#	$Id: Makefile.tool,v 1.4 92/01/03 20:18:13 johnm Exp $
#
###############################################################################


#include	<geos.mk>
#include	<gpath.mk>

MACHINES	= win32
MAKEFILE	= Makefile
NAME		= ntcurses
SYSMAKEFILE	= tool.mk
TYPE		= library

#if	!defined(linux)
DEFTARGET	= win32
#endif

MISRCS          = attrib.c \
                  beep.c \
                  charadd.c \
                  chardel.c \
                  charget.c \
                  charins.c \
                  charpick.c \
                  clrtobot.c \
                  clrtoeol.c \
                  endwin.c \
                  initscr.c \
                  linedel.c \
                  lineins.c \
                  longname.c \
                  move.c \
                  mvcursor.c \
                  newwin.c \
                  ntio.c \
                  options.c \
                  overlay.c \
                  prntscan.c \
                  refresh.c \
                  setmode.c \
                  setterm.c \
                  stradd.c \
                  strget.c \
                  tabsize.c \
                  termmisc.c \
                  unctrl.c \
                  winclear.c \
                  windel.c \
                  winerase.c \
                  winmove.c \
                  winscrol.c \
                  wintouch.c

win32SRCS       = $(MISRCS) win32.md/
win32OBJS       = win32.md/attrib.obj \
                  win32.md/beep.obj \
                  win32.md/charadd.obj \
                  win32.md/chardel.obj \
                  win32.md/charget.obj \
                  win32.md/charins.obj \
                  win32.md/charpick.obj \
                  win32.md/clrtobot.obj \
                  win32.md/clrtoeol.obj \
                  win32.md/endwin.obj \
                  win32.md/initscr.obj \
                  win32.md/linedel.obj \
                  win32.md/lineins.obj \
                  win32.md/longname.obj \
                  win32.md/move.obj \
                  win32.md/mvcursor.obj \
                  win32.md/newwin.obj \
                  win32.md/ntio.obj \
                  win32.md/options.obj \
                  win32.md/overlay.obj \
                  win32.md/prntscan.obj \
                  win32.md/refresh.obj \
                  win32.md/setmode.obj \
                  win32.md/setterm.obj \
                  win32.md/stradd.obj \
                  win32.md/strget.obj \
                  win32.md/tabsize.obj \
                  win32.md/termmisc.obj \
                  win32.md/unctrl.obj \
                  win32.md/winclear.obj \
                  win32.md/windel.obj \
                  win32.md/winerase.obj \
                  win32.md/winmove.obj \
                  win32.md/winscrol.obj \
                  win32.md/wintouch.obj

win32LIBS       =


#if exists(local.mk)
#include	"local.mk"
#else
#include	<$(SYSMAKEFILE)>
#endif

#if	exists(win32.md/dependencies.mk)
#include	"win32.md/dependencies.mk"
#endif


# Allow mkmf
