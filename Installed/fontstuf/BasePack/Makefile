##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Font Creation
# FILE: 	Makefile
# AUTHOR: 	Adam de Boor, Jul 24, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/24/89		Initial Revision
#
# DESCRIPTION:
#	Makefile for creating PC/GEOS fonts from Macintosh fonts
#
#	$Id: Makefile,v 1.2 91/09/03 22:31:21 adam Exp $
#
###############################################################################

#include    <geos.mk>
#include    <gpath.mk>

#
# Mark the important things as files being included so their paths make it
# into .INCLUDES
#
.INCLUDES	: .def 

#
# Define the fonts that can be made
#
FONTS       	= University Bison Berkeley Roma LED \
		  Sans Mono Roman SymbolPS \
		  Broadway Cooper Glypha Vivaldi Zapf_Chancery \
		  Bodoni Century_Schoolbook Copperplate Eurostile \
		  EuroExt Frutiger Old_English STENCIL \
                  pr_10cpi pr_12cpi pr_15cpi pr_16cpi pr_17cpi pr_20cpi \
                  pr_serif


#
# Define the versions of tools to use (allows user to override w/uninstalled
# version).
#
NIM2PC		?= nim2pc
NIMFLAGS	?= -w

# Our three new suffixes.
# .mac is the raw font data uploaded from the Mac.
# .nim is the raw Nimbus font data uploaded from the PC.
# .fnt is the final PC/GEOS font file
#
.SUFFIXES	: .mac .nim .xbm
#
# Tell PMake to search in all the font source directories for the files
#
.PATH		: $(FONTS:S|^|$(CURRENT_DIR)/Src/|g) \
		  $(FONTS:S|^|$(INSTALL_DIR)/Src/|g) \
                  $(CURRENT_DIR)/Src/Printer \
                  $(INSTALL_DIR)/Src/Printer

#
# Path to .def files included by printer fonts
#
.PATH.def	: $(CURRENT_DIR)/Src/Printer \
                  $(INSTALL_DIR)/Src/Printer


# By default, make all the fonts
#
all		: $(FONTS:S|$|.fnt|g)

# Make the generated .asm file for the font depend on all the raw component
# files in the proper directory (pmake will search through all the
# source directories, but will only find those in the proper one since
# they're the only ones that will begin with the font name...). 

$(FONTS:Npr_*:S|$|.asm|g) : $(.TARGET:R)*.nim $(.TARGET:R)*.xbm $(.TARGET:R)*.mac

#
# For everything but Bison and LED, we can just run $(NIM2PC) w/o flags to
# create the .asm file for Esp.
# The printer fonts are also ignored because they are not generated from
# nimbus stuff, the are already in .asm files
#
$(FONTS:NBison*:NLED*:Npr_*:S|$|.asm|g) :
	$(NIM2PC) $(NIMFLAGS) $(.ALLSRC)
	...
#if defined (REMOVE)
	rm -f *$(.TARGET:R)*.asm
	rm -f *$(.TARGET:R)*.def
#endif
	rm -f *$(.TARGET:R)*.sym *$(.TARGET:R)*.tcl *$(.TARGET:R)*.obj

#
# Remove .sym, .tcl and .obj files for printer fonts, but NOT .asm and .def
#
$(FONTS:Mpr_*:S|$|.asm|g)	:
	...
	rm -f *$(.TARGET:R)*.sym *$(.TARGET:R)*.tcl *$(.TARGET:R)*.obj

#
# Most fonts begin with character 32. Bison begins with character 0.
# Bison 13 contains only the single character "*".
#
Bison.asm :
	$(NIM2PC) $(NIMFLAGS) -f0 $(.ALLSRC:N*13*) -f42 -l42 $(.ALLSRC:M*13*)
	...
#if defined (REMOVE)
	rm -f *$(.TARGET:R)*.asm
	rm -f *$(.TARGET:R)*.def
#endif
	rm -f *$(.TARGET:R)*.sym *$(.TARGET:R)*.tcl *$(.TARGET:R)*.obj

#
# LED is a sparse font, containing comma, dot, -, 0 through 9, E, r and o.
# Also, to keep the average width usable, the default character is 0.
#
LED.asm	:
	$(NIM2PC) $(NIMFLAGS) -z48 -f44 -l114 $(.ALLSRC)
	...
#if defined (REMOVE)
	rm -f *$(.TARGET:R)*.asm
	rm -f *$(.TARGET:R)*.def
#endif
	rm -f *$(.TARGET:R)*.sym *$(.TARGET:R)*.tcl *$(.TARGET:R)*.obj

# No mkmf
