#
#	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# Things for setting the search path and other things appropriately for the
# type of GEODE or whatnot being made. SUBDIR is set to the subdirectory of
# the ROOT_DIR in which the installed source for things of this type resides
# (e.g. $(APPL_DIR)).
#
# This sets the following variables:
#
#	INSTALL_DIR	The directory in which this whatnot is installed
#	DEVEL_DIR	The root of the current development tree.
#	KINCPATHS	-I flags for the kernel .def files
#	INCPATHS	-I flags for the .def files for this whatnot
#
# The path for the .def suffix is set to contain:
#	- the uninstalled Include dir for this development tree
#	- the installed Include directory
#	- the installed Library directory
#	- the installed source directory for this whatnot
#
# The path for the .asm suffix is set to the installed source directory for
# this whatnot.
#
#
#	NOTE that '.' is not always checked first and is necessary in the
#	search paths.
#
#	NOTE: DO NOT DEFINE A PATH FOR .h FILES HERE. It hoses things
#	in Tools. The path for .h files for geodes is defined in geode.mk
#
#	$Id: gpath.mk,v 1.1 97/04/04 14:24:18 newdeal Exp $
#

#
# PMake doesn't need the . here, but MASM does, silly thing...
#
#	If NO_LIBRARIES is defined then don't use it to give masm more command
#	line room
#

.PATH.def	: . $(INSTALL_DIR) \
		  $(DEVEL_DIR)/Include $(INCLUDE_DIR) \
		  $(DEVEL_DIR)/Include/Internal $(INCLUDE_DIR)/Internal \
		  $(DEVEL_DIR)/Include/Objects $(INCLUDE_DIR)/Objects \
		  $(DEVEL_DIR)/Include/Objects/Text \
		  $(INCLUDE_DIR)/Objects/Text \
		  $(DEVEL_DIR)/Include/Objects/SSheet \
		  $(INCLUDE_DIR)/Objects/SSheet

.PATH.goh	: . $(INSTALL_DIR) \
		  $(DEVEL_DIR)/CInclude $(CINCLUDE_DIR) \
		  $(DEVEL_DIR)/CInclude/Objects $(CINCLUDE_DIR)/Objects \
		  $(DEVEL_DIR)/CInclude/Objects/Text \
		  $(CINCLUDE_DIR)/Objects/Text \
		  $(DEVEL_DIR)/CInclude/Objects/FlatFile \
		  $(CINCLUDE_DIR)/Objects/FlatFile

.PATH.asm	: . $(INSTALL_DIR)

.PATH.c		: . $(INSTALL_DIR)

.PATH.goc	: . $(INSTALL_DIR)
