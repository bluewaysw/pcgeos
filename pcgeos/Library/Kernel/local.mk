##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Kernel -- Special Makefile Definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 16, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/16/89		Initial Revision
#	JDM	93.04.29	Added Profiling version support.
#
# DESCRIPTION:
#	Kernel special makefile definitions.
#
#	$Id: local.mk,v 1.1 97/04/05 01:15:40 newdeal Exp $
#
###############################################################################

ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#
# The kernel needs to use I/O instructions for some strange reason...
#
ASMFLAGS	+= -i

#
#	The target is geos.geo
#
GEODE		= geos

#if $(PRODUCT) == "NDO2000"
#else
# GPC additions
#ASMFLAGS	+= -DGPC -DGPC_ONLY
#UICFLAGS	+= -DGPC -DGPC_ONLY
#LINKFLAGS	+= -DGPC -DGPC_ONLY
#endif

ASMFLAGS += -DSIMPLE_RTL_SUPPORT
LINKFLAGS += -DSIMPLE_RTL_SUPPORT

#include    "$(SYSMAKEFILE)"

PCXREFFLAGS     += -sgeos.sym

#
# If the target is Profile then specify each of the profiling conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[Profile\\]/*:S|Profile| -DANALYZE_WORKING_SET=TRUE -DRECORD_MESSAGES=TRUE -DRECORD_MODULE_CALLS=TRUE |g)

#full		:: Profile

#
# If the target is "Bullet" then specify each of the Bullet conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[Bullet\\]/*:S|Bullet| -DHARDWARE_TYPE=BULLET |g)

#full            :: Bullet

#
# If the target is "XIP" then specify each of the XIP conditional
# compilation directives on the command line for the assembler.
#
#ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE -DEMM_XIP=1 -DMAPPING_PAGE_SIZE=0x4000 -DMAPPING_PAGE_ADDRESS=0xc800 -DPHYSICAL_PAGE_TO_USE_FOR_READING_RESOURCES=4|g)
#
# MAPPING_PAGE_ADDRESS and PHYSICAL_PAGE_TO_USE_FOR_READING_RESOURCES are now
# read from loaderVars
#

ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP|-DEMM_XIP=1 -DMAPPING_PAGE_SIZE=0x8000|g)

#
# For RESPDEMOXIP, MAPPING_PAGE_SIZE is grabbed from respxip.def
#
ASMFLAGS	+= $(.TARGET:X\\[RESPDEMOXIP\\]/*:S|RESPDEMOXIP|-DEMM_XIP=1|g)

#full		:: XIP

#
# If the target is "ZOOMXIP" then specify each of the XIP conditional
#
ASMFLAGS	+= $(.TARGET:X\\[ZoomerXIP\\]/*:S|ZoomerXIP|-DMAPPING_PAGE_SIZE=0x8000|g)

#full		:: ZoomerXIP

#
# If the target is "REDWOOD" then specify each of the Redwood conditional
# compilation directives on the command line for the assembler.  (Comment
# back in when we need the Redwood stuff again)
#
#ASMFLAGS	+= $(.TARGET:X\\[REDWOOD\\]/*:S|REDWOOD| -DHARDWARE_TYPE=REDWOOD -DKERNEL_EXECUTE_IN_PLACE=FALSE |g)
#
#full            :: REDWOOD

#
# If the target is "REDXIP" then specify each of the RedwoodXIP conditional
# compilation directives on the command line for the assembler.  (Comment
# back in when we need the Redwood stuff again)
#
#ASMFLAGS	+= $(.TARGET:X\\[REDXIP\\]/*:S|REDXIP| -DHARDWARE_TYPE=REDWOOD -DKERNEL_EXECUTE_IN_PLACE=TRUE |g)
#
#full            :: REDWOOD_XIP


#
# If the target is "BULLXIP" then specify each of the XIP conditional
#
ASMFLAGS	+= $(.TARGET:X\\[BulletXIP\\]/*:S|BulletXIP|-DMAPPING_PAGE_SIZE=0x8000|g)

#full		:: BulletXIP


#
# If the target is "JediXIP" then specify each of the XIP conditional
#
ASMFLAGS	+= $(.TARGET:X\\[JediXIP\\]/*:S|JediXIP|-DMAPPING_PAGE_SIZE=0x8000|g)

#full		:: JediXIP


#
# If the target is "GulliverXIP" then specify each of the XIP conditional
# (MAPPING_PAGE_SIZE is set in gullxip.def)
#
#ASMFLAGS	+= $(.TARGET:X\\[GulliverXIP\\]/*:S|GulliverXIP| |g)

#full		:: GulliverXIP


#
# If the target is "DWP" then specify each of the DWP conditional
# compilation directives on the command line for the assembler.
#

#full            :: DWP


#
# If the target is "DOVEDEMOXIP" then specify each of the XIP conditionals
#
ASMFLAGS	+= $(.TARGET:X\\[DOVEDEMOXIP\\]/*:S|DOVEDEMOXIP|-DEMM_XIP=1 -DMAPPING_PAGE_SIZE=0x8000|g)


#full		:: DOVEDEMOXIP DOVEXIP

#
# For DBCS version, make sure we have DBCS-specific LDF
#
LINKFLAGS	+= $(.TARGET:X\\[DBCS\\]/*:S|DBCS|-l|g)
