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
#	setup file for microsoft tools.
#
# 	$Id: msc.mk,v 1.1 97/04/04 14:20:31 newdeal Exp $
#
##############################################################################

#
# This is a temporary fix so that pmake can find stuff like assert.h.
# The problem here is that if you have some other version of Borland
# installed (or have it installed in a different directory), then
# this won't be correct.  But for now...
#
.PATH.h		: $(SystemDrive)/msdev/include

CC		?= cl
AS		?= cl -c
TOOLLINK	?= link
TOOLLIB		?= lib -nologo
LIBTARGETS	 = -OUT:$(.TARGET:S%/%\\%g) $(win32OBJS)

#
# Flags for cl that are okay for both compiling and linking.
#
#	-nologo	- turn off that microsoft copyright stuff
#
CFLAGS_COMMON	?= -nologo

#
# Extra flags for cl to specify the machine type (all targets are in a .md
# directory) and where to place the result.  Under NT, this DOES NOT WORK
# for the final link.
# 
CFLAGS		+= $(CFLAGS_COMMON) -Fo$(.TARGET) $(.INCLUDES) \
                   -I$(.TARGET:H) -I. $(XCFLAGS) -Zi -Yd -W3

#
# Flags to pass to cl WHEN LINKING.
#
CLINKFLAGS	+= -debug:full -debugtype:both $(CFLAGS_COMMON) -out:$(.TARGET) $(XCFLAGS)

