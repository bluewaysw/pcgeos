##############################################################################
#
#       Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:     PC GEOS
# FILE:        gdi.gp
#
# AUTHOR:      Todd Stumpf
#
#
#       $Id: gdi.gp,v 1.1 97/04/04 18:04:09 newdeal Exp $
#
##############################################################################
#
# Specify the geode's permanent name
#
name	gdi.lib
#
# Specify the type of geode
#
type library, single

#
# Define the library entry point
#
#  There is none.

#
# Import definitions from the kernel
#
library geos
#
# Desktop-related things
#
longname        "Generic Device Interface Lib"
tokenchars      "GDIL"
tokenid         0

#
# Specify alternate resource flags for anything non-standard
#
nosort
resource InfoResource		fixed	code	read-only
resource CallbackCode		fixed	code	read-only
resource ShutdownCode		fixed	code	read-only
resource PowerCode		fixed	code	read-only
resource MonitorCode		fixed	code	read-only

#
# Library Routines
#
export GDIPointerInit
export GDIPointerInfo
export GDIPointerRegister
export GDIPointerUnregister
export GDIPointerShutdown

export GDIKeyboardInit
export GDIKeyboardInfo
export GDIKeyboardRegister
export GDIKeyboardGetKey
export GDIKeyboardUnregister
export GDIKeyboardShutdown

export GDIPowerInit
export GDIPowerInfo
export GDIPowerShutdown
export GDIPowerRegister
export GDIPowerUnregister
export GDIPowerGet
export GDIPowerSet

export GDISMMonitorSystem
export GDISMGenerateState
export GDISMRemoveMonitor

export	GDIKeyboardPassHotkey
export	GDIKeyboardCancelHotkey
export	GDIKeyboardAddHotkey
export  GDIKeyboardDelHotkey
export  GDIKeyboardCheckHotkey

export	GDISMGetExclusive
export	GDISMReleaseExclusive







