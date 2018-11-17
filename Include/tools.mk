##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PMake System Library -- Simple Tools makefile
# FILE: 	tools.mk
# AUTHOR: 	Adam de Boor, May 30, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	MAKETOOL    	    	Create a Sun and an ISI version of a single
#	    	    	    	tool. Target is base name. Sources are
#	    	    	    	all objects and libraries required. Creates
#	    	    	    	the target (as sun binary) and $(.TARGET).isi
#	    	    	    	(an isi binary)
#	MAKESUN	    	    	Create a Sun binary of the given name
#	MAKEISI	    	    	Create an ISI binary of the given name
#	INSTALL	    	    	Install both sun and isi binaries in
#	    	    	    	/usr/public using INSTALLFLAGS
#	INSTALLSUID 	    	Install a tool that must be setuid to root as
#	    	    	    	for INSTALL
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/30/89		Initial Revision
#
# DESCRIPTION:
#	Include file for the creation of tools. This thing (so far) deals
#	only with the creation of sun and isi versions from the same
#	set of object files.
#
#	$Id: tools.mk,v 1.1 97/04/04 14:24:53 newdeal Exp $
#
###############################################################################


#ifdef sun
SUNREMOTE	= 
ISIREMOTE	= on lithium
#else
SUNREMOTE	= on promethium
ISIREMOTE	= 
#endif

CC		= gcc -O
INSTALLFLAGS	?=

MAKETOOL	: .USE .NOEXPORT
	$(SUNREMOTE) $(CC) $(CFLAGS) $(.LIBS) -o $(.TARGET) \
	    $(.ALLSRC) < /dev/null
	$(ISIREMOTE) $(CC) $(CFLAGS) $(.LIBS) -o $(.TARGET).isi \
	    $(.ALLSRC) < /dev/null

MAKESUN		: .USE .NOEXPORT
	$(SUNREMOTE) $(CC) $(CFLAGS) $(.LIBS) -o $(.TARGET) \
	    $(.ALLSRC) < /dev/null

MAKEISI		: .USE .NOEXPORT
	$(ISIREMOTE) $(CC) $(CFLAGS) $(.LIBS) -o $(.TARGET).isi \
	    $(.ALLSRC) < /dev/null

INSTALL		: .USE .NOEXPORT
	for i in $(.ALLSRC); do
	    install -c $(INSTALLFLAGS) $i /n/silicon/public/$i
	    install -c $(INSTALLFLAGS) $i.isi /n/lithium/public/$i
	done

INSTALLSUID	: .USE .NOEXPORT
	for i in $(.ALLSRC); do
	    install -c -m 4555 -o root -g wheel $(INSTALLFLAGS) \
		$i /n/silicon/public/$i
	    install -c -m 4555 -o root -g wheel $(INSTALLFLAGS) \
		$i.isi /n/lithium/public/$i
	done


#
# Check in the installed directory for .c, .h and .y files too...
#
.PATH.c		: $(INSTALL_DIR)
.PATH.h		: $(INSTALL_DIR)
.PATH.y		: $(INSTALL_DIR)

#if empty(CFLAGS:M$(.INCLUDES\))
CFLAGS		+= $(.INCLUDES)
#endif
