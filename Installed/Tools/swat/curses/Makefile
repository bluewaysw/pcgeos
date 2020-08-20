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

MACHINES	= linux
MAKEFILE	= Makefile
NAME		= curses
SYSMAKEFILE	= tool.mk
TYPE		= library

#if	!defined(linux)
DEFTARGET	= linux
#else
DEFTARGET	= linux
#endif

MISRCS          = addch.c addstr.c box.c clear.c clrtobot.c clrtoeol.c\
                  cr_put.c cr_tty.c curses.c curses.h delch.c deleteln.c\
                  delwin.c egetstr.c endwin.c erase.c fullname.c getch.c\
                  getstr.c id_subwins.c idlok.c initscr.c insch.c\
                  insertln.c longname.c move.c mvprintw.c mvscanw.c mvwin.c\
                  newwin.c overlay.c overwrite.c printw.c putchar.c \
                  refresh.c scanw.c scroll.c scrollnow.c standout.c \
                  toucholap.c touchwin.c tstp.c unctrl.c dosmode.asm

linuxSRCS	= $(MISRCS) linux.md/
linuxOBJS      	= addch.o \
		  addstr.o \
		  box.o \
		  clear.o \
		  clrtobot.o \
                  clrtoeol.o \
		  cr_put.o \
		  cr_tty.o \
		  curses.o \
		  delch.o \
                  deleteln.o \
		  delwin.o \
		  egetstr.o \
		  endwin.o \
		  erase.o \
                  fullname.o \
		  getch.o \
		  getstr.o \
		  idsubwin.o \
		  idlok.o \
                  initscr.o \
		  insch.o \
		  insertln.o \
		  longname.o \
		  move.o \
                  mvprintw.o \
		  mvwin.o \
		  newwin.o \
		  overlay.o \
                  overwrt.o \
		  printw.o \
		  putchar.o \
		  refresh.o \
		  scroll.o \
                  scrolnow.o \
		  standout.o \
		  tucholap.o \
		  touchwin.o \
                  unctrl.o  

linuxLIBS       =


#if exists(local.mk)
#include	"local.mk"
#else
#include	<$(SYSMAKEFILE)>
#endif

#if	exists(linux.md/dependencies.mk)
#include	"linux.md/dependencies.mk"
#endif


# Allow mkmf
