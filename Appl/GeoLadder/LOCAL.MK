##############################################################################
#
# Copyright (c) 2010 by YoYu-Productions
#
# PROJECT:      GeoLadder
# MODULE:       Local Makefile
# FILE:         LOCAL.MK
#
# AUTHOR:       Andreas Bollhalder
#
##############################################################################


# ::: XGOCFLAGS ::: (will be passed to the GOC preprozessor)

# Do not create an EC version
# NO_EC = 1
NO_EC = 1


# ::: XCCOMFLAGS ::: (will be passed to the C compiler)

# Generics
# -d     Reduces the size of the dgroup by merging duplicate strings.
# -dc    Compile the stings of the the code into the code segment instead
#        the dgroup.
XCCOMFLAGS += -d -dc

# Used instruction set
# -1     186
# -2     286 (recommended)
# -3     386 (possibly problematic with SWAT)
# -4     ??? (used by Rainer in R-Basic)
# -1- -2- -3-    8086
XCCOMFLAGS += -2

# Speed and size (no garanties !!!)
# -b-    Make enums size of byte instead of int
# -O     Optimize for jumps
# -Ob    Remove dead code (needed for -Oe)
# -Oc    Optimize locally
# -Oe    Global register allocation (required for -Ob)
# -Og    Optimize globally
# -Ol    Optimize loops
# -Op    Copy propagation
# -Os    Optimize for size
# -O1    Optimize for size
# -Z     Suppress redundant loads
#        Good size reduction with
#          -O -Os -Z
#        Minor size reduction with
#          -Ol -d
XCCOMFLAGS += -O -Op -Os -Z


# ::: LINKFLAGS ::: (will be passed to the GLUE linker)

# Set the copyrigth notice
LINKFLAGS += -N ©2010\20by\20YoYu-Productions

#include <$(SYSMAKEFILE)>


# End of LOCAL.MK
