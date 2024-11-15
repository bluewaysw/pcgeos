##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat Stub -- Makefile stuff
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jul 26, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/26/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for Swat stub
#
#	$Id: local.mk,v 2.7 96/12/04 19:40:53 brianc Exp $
#
###############################################################################

#
# Special definition of places to find include files since geos.mk doesn't
# give the kernel as a source and we need it...
#
INCDIRS		= . $(INSTALL_DIR) \
                  $(DEVEL_DIR)/Library/Kernel $(LIBRARY_DIR)/Kernel \
                  $(DEVEL_DIR)/Include $(INCLUDE_DIR)/Internal $(INCLUDE_DIR)


.PATH.def	: $(INCDIRS)

#
# The rpc.def file is generated from rpc.h via a sed script. This is to make
# sure the stub and Swat are speaking the same language... The ordering of
# the two sources is important -- the .sed file *must* come first.
#
#.SUFFIXES	: .sed
#.PATH.h		: .. $(INSTALL_DIR:H)
#.PATH.sed	: $(INSTALL_DIR)
#rpc.def		: rpc.sed rpc.h     	    	    	    	    .NOTMAIN
#	sed -f $(.ALLSRC) > $(.TARGET)

#
# Prevent normal geode things from being done in geode.mk
#
GSUFF		= exe
#undef GEODE
NO_EC		= si, senor

#
# Remove $(.INCLUDES) from the MASMFLAGS so we don't pass too many -I flags to
# poor, helpless, feckless MASM.
#
# Use the directory in which the object will be going to define an upper-case
# symbol indicating the stub type. E.g. Low/kernel.obj generates a -DLOW.
# Default to -DLOWMEM if target not in a subdir (e.g. dependencies.mk)
#
ASMFLAGS        := -i $(INCDIRS:S|^|-I|g) $(ASMFLAGS:N*.INCLUDES*) \
		-D`perl -e "print uc '$(SUBDIRS)'"` -DPRODUCT_GEOS32
#                   "-D`expr $(.TARGET) : '\([^/]*\)/' \| LOWMEM : '\(LOWMEM\)' | tr a-z A-Z`"


ASMFLAGS	+= -DFULL_EXECUTE_IN_PLACE

#ifdef DBCS
ASMFLAGS	+= -2 -DDO_DBCS -DPRODUCT=DBCS
#endif

#ifdef DOVE
ASMFLAGS	+= -2 -DDO_DBCS -DPRODUCT=DOVE
#endif

#.asm.obj	:
#	cd $(.TARGET:H)
#	$(MASM) $(MASMFLAGS) $(.IMPSRC:N/*:S|^|../|) $(.IMPSRC:M/*) \
#	    -o $(.TARGET:T)

#
# Define the targets and their sources...
#
STUBS		:= $(SUBDIRS:S|$|/swat.exe|g) 
all		: $(STUBS)

$(STUBS)	: $(OBJS:S|^|$(.TARGET:H)/|g)  	    	    LINK 

$(SUBDIRS)	: $(.TARGET:S|$|/swat.exe|)

#
# Include the proper system makefile
#
#include    <$(SYSMAKEFILE)>

#
# Need to mangle the dependencies a bit here. We don't generate .eobj files
# and we need to make a .obj file for each stub type.
#
EXTRADEP	: .USE
	mv $(.TARGET) dep.foo.$$$$
	sed -e '/\.eobj \\/d' dep.foo.$$$$ | \
	    awk '
	BEGIN {
	    numtypes=split("$(SUBDIRS)",types," ")
	}
	$2 == ":" {
	    for (i = 1; i < numtypes; i++) {
	    	printf "%s/%s \\\n", types[i], $1
	    }
	    printf "%-15s :", sprintf("%s/%s", types[numtypes], $1)
	    for (i = 3; i <= NF; i++) {
	    	printf " %s", $i
	    }
	    printf "\n"
	}
	$2 != ":" { print }' > $(.TARGET)
	rm -f dep.foo.$$$$

$(DEPFILE)	: EXTRADEP

