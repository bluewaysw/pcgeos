##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	PCCom2 (Sample GEOS application)
# FILE:		pccom2.gp
#
# AUTHOR:	Cassie Hartzog, Jan 20, 1994
#
# DESCRIPTION:	This file contains Geode definitions for the "PCCom2" sample
#		application. This file is read by the Glue linker to
#		build this application.
#
# RCS STAMP:
#	$Id: pccom2.gp,v 1.1 97/04/04 16:39:14 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name pccom2.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "PCCom2 Sample Application"
#
# Specify geode type: is an application, and will have its own thread started
# for it by the kernel.
#
type	appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the PCCom2ProcessClass, which is defined in pccom2.goc.
#
class	PCCom2ProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See pccom2.goc.
#
appobj	PCCom2App
#
# Token: this four-letter+integer name is used by GeoManager to locate the
# icon for this application in the token database. So that the token will
# be unique, the token id corresponds to the manufacturer ID of the program's
# author. Since this is a sample application, we use the manufacturer id of
# the SDK, which is 8.
#
tokenchars "SAMP"
tokenid 8
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on, 
# plus an additional amount for thread activity. To find the heapspace 
# for an application, use the Swat "heapspace" command.
#
heapspace 3847
#
# This application calls library code fixed or first written after the
# Zoomer release. Here we specify that the application expects to be
# running with Zoomer release libraries; this allows it to copy the
# necessary fixes from the relevant .ldf files into its own executable
# at compile time so that at runtime it will provide the fixed code for
# itself instead of refusing to run with the old libraries.
#
platform zoomer
#
# Libraries: list which libraries are used by the application.
# Note our use of "noload" for the pccom library. We use this library
# for a demonstration of how to load a library dynamically rather than
# automatically (see pccom2.goc). Use of the "library" directive without
# the "noload" keyword causes the application to load the specified library
# automatically on startup.
#
library	geos
library	ui
library pccom noload
#
# Exempt the pccom library from compile-time protocol checking since
# it did not exist at the time of the zoomer release and so will not
# be found in the zoomer platform file (.plt file).
#
exempt pccom
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource APPRESOURCE ui-object
resource INTERFACE ui-object

export	PCCom2TextClass


