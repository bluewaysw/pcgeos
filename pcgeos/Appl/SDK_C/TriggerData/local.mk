######################################################################
#
#	Copyright (c) Geoworks 1992 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	SDK_C/TriggerData
# FILE:		local.mk
#
# AUTHOR:	Jenny Greenwood, 22 Jan 1994
#
# DESCRIPTION:
#	Local makefile for TriggerData sample application.
#	$Id: local.mk,v 1.1 97/04/04 16:37:54 newdeal Exp $
#
######################################################################
#
# The geode name and the name of the compiled .geo file are set separately,
# but it is wise to make them the same so the geode name is obvious from the
# name of the .geo file. The default name for the .geo file would be the
# downcased name of the main directory for this application (Triggerd on
# the PC, TriggerData on UNIX). Let's say we want both the .geo file and
# the geode to have a name different from that default. In order to name
# the geode "trigdata" and the .geo file "trigdata.geo", we take three steps.
# Steps 1 and 2 name the .geo file; step 3 names the geode:
# 
#	1. We create a local.mk file for the application which
#	   contains the following lines:
#
#		GEODE	= trigdata
#		#include <$(SYSMAKEFILE)>
#
#	2. We name the .gp file "trigdata.gp".
#	3. In the .gp file we set the permanent name of the geode
#	   to "trigdata" with the line 
#
#		name trigdata.app
#
#	   ("app" since trigdata is an application).
#	   

GEODE	= trigdata

#include <$(SYSMAKEFILE)>
