##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PMake System Library
# FILE: 	tool.mk
# AUTHOR: 	Tim Bradley, September 5, 1996
#
# DESCRIPTION:
#	setup file for borland tools.
#
# 	$Id: borland.mk,v 1.1 97/04/04 14:20:30 newdeal Exp $
#
##############################################################################

#
# This is a temporary fix so that pmake can find stuff like assert.h.
# The problem here is that if you have some other version of Borland
# installed (or have it installed in a different directory), then
# this won't be correct.  But for now...
#
.PATH.h		: $(SystemDrive)/bc5/include $(SystemDrive)/bc45/include

CC		?= bcc32
AS		?= bcc32 -c
TOOLLIB		?= tlib
TOOLLINK	?= $(CC)

LIBTARGETS	= $(.TARGET:S%/%\\%g) $(win32OBJS:S/^/-+ /g:S%/%\\%g)

#
# Flags for bcc32 that are okay for both compiling and linking.
#
# 	-v	- turn debugging info on (like -g in Unix)
#	-g255	- allow max. # of warnings
#	-a4	- align to 4-byte boundaries (needed in some apps)
#	-w	- turn on all warnings
#       -w-sig  - turn off "Conversion may lose significant digits"
# 		  (which is actually useful in general, but there
#		  are too many existing warnings of this type
#		  that would be hard to fix now)
#       -w-bbf  - turn off "Bit fields must be signed or unsigned int",
#		  which we also get copious amounts of
#
CFLAGS_COMMON	=  -v -g255 -a4 -w -w-sig -w-bbf

#
# Extra flags for bcc32 to specify the machine type (all targets are in a .md
# directory) and where to place the result.  Under NT, this DOES NOT WORK
# for the final link.
# 
CFLAGS		+= $(CFLAGS_COMMON) -o$(.TARGET) $(.INCLUDES) \
                   -I$(.TARGET:H) -I. $(XCFLAGS)

#
# Flags to pass to bcc32 WHEN LINKING.
#
CLINKFLAGS	+=  $(CFLAGS_COMMON) -e$(.TARGET) $(XCFLAGS)
