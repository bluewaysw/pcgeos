##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Ppds24 -- Makefile
# FILE: 	Makefile
# AUTHOR: 	God, Wed Apr  2 20:44:09 PST 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	ppds24ec.geo		create an error-checking version
#	ppds24.geo		create a non error-checking version
#	full			create both of the above, plus tags
#	part			create only the error-checking version
#	tags			create a tags file from all the sources
#	depend			generate source file dependencies
#
# DESCRIPTION:
#	This makefile was automatically generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.geode
#
#	DO NOT EDIT IT, AS YOU MAY LOSE YOUR CHANGES WHEN IT IS REGENERATED
#
#	$Id: Makefile.geode,v 1.4 92/01/03 20:17:45 johnm Exp $
#
###############################################################################

GEODE           = ppds24
LIBNAME         = print
PROTOCONST      = PRINT
OBJS            = ppds24Manager.obj
SRCS            = Job/Custom/customPPDS24.asm Page/pageEnd.asm\
                  Page/pageStartForceLength.asm\
                  Text/Font/fontIBMPPDSInfo.asm Text/textGetLineSpacing.asm\
                  Text/textLoadNoISOSymbolSet.asm Text/textPrintRaw.asm\
                  Text/textPrintStyleRun.asm Text/textPrintText.asm\
                  Text/textSetFont.asm Text/textSetLineSpacing.asm\
                  Text/textSetSymbolSet.asm ppds24ControlCodes.asm\
                  ppds24DriverInfo.asm ppds24Manager.asm ppds24Page.asm\
                  ppds24Text.asm ppds24generInfo.asm ppds24generwInfo.asm\
                  printcomAdmin.asm printcomDotMatrixBuffer.asm\
                  printcomEntry.asm printcomIBMJob.asm\
                  printcomIBMPPDS24Cursor.asm printcomIBMPPDS24Graphics.asm\
                  printcomIBMPPDS24Styles.asm printcomIBMPropDialog.asm\
                  printcomInfo.asm printcomNoColor.asm\
                  printcomNoEscapes.asm printcomStream.asm\
                  printcomTables.asm ppds24Constant.def
LOBJS           =

SUBDIRS         = Zoomer

#include	<geos.mk>		# system directory definitions
#include	<gpath.mk>		# set search paths for files

MAKEFILE	= Makefile
SYSMAKEFILE	= geode.mk

#if exists(local.mk)
#	include	"local.mk"
#else
#	include	<$(SYSMAKEFILE)>
#endif

#if 	exists($(DEPFILE))
#include	"$(DEPFILE)"
#endif

# Allow mkmf
