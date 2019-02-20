##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	curses -- makefile
# FILE: 	makefile
# AUTHOR: 	Adam de Boor, Sun Jun  7 17:48:30 PDT 1992
#
# TARGETS:
#		curses.lib		386|DOS-Extender library
#		test.exp		test program #1
#		test2.exp		test program #2 (scrolling)
#		test3.exp		test program #3 (input)
#
# DESCRIPTION:
#		Makefile for creating the DOS version of the curses library.
#
#	$Id: makefile,v 1.5 94/07/25 18:55:55 jimmy Exp $
#
###############################################################################


.SUFFIXES	: .OBJ .ASM .C

MISRCS          = addch.c addstr.c box.c clear.c clrtobot.c clrtoeol.c\
                  cr_put.c cr_tty.c curses.c curses.h delch.c deleteln.c\
                  delwin.c egetstr.c endwin.c erase.c fullname.c getch.c\
                  getstr.c id_subwins.c idlok.c initscr.c insch.c\
                  insertln.c longname.c move.c mvprintw.c mvscanw.c mvwin.c\
                  newwin.c overlay.c overwrite.c printw.c putchar.c\
                  refresh.c scanw.c scroll.c scrollnow.c standout.c \
                  toucholap.c touchwin.c tstp.c unctrl.c dos.c dosmode.asm

OBJS          	= addch.obj addstr.obj box.obj clear.obj clrtobot.obj \
                  clrtoeol.obj cr_put.obj cr_tty.obj curses.obj delch.obj \
                  deleteln.obj delwin.obj egetstr.obj endwin.obj erase.obj \
                  fullname.obj getch.obj getstr.obj idsubwin.obj idlok.obj \
                   initscr.obj insch.obj insertln.obj longname.obj move.obj \
                  mvprintw.obj mvwin.obj newwin.obj overlay.obj \
                  overwrt.obj printw.obj refresh.obj scroll.obj \
                  scrolnow.obj standout.obj tucholap.obj touchwin.obj \
                  unctrl.obj dos.obj dosmode.obj

NAME		= curses

CC		= hc386
CFLAGS		= -fsoft -g -I. -I..\..\include -IT:\phar386\includes -Heol=10
AS		= 386asm
AFLAGS		= -twocase -I T:\phar386\includes\ # trailing space reqd
LINK		= 386link

.c.obj	:
	$(CC) -c $(CFLAGS) $<
.asm.obj:
	$(AS) $(AFLAGS) -o $@ $<

curses.lib : $(OBJS)
	386lib @curses.lbc

$(OBJS)		: curses.h curses.ext

test.exp	: test.obj curses.lib
	$(LINK) @test.lnk

test2.exp	: test2.obj curses.lib
	$(LINK) @test2.lnk

test3.exp	: test3.obj curses.lib
	$(LINK) @test3.lnk
