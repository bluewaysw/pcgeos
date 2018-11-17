##############################################################################
#
# 	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE: 	patient.tcl
# AUTHOR: 	Joon Song, Aug 29, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	Joon	8/29/93   	Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: patient.tcl,v 1.2 97/04/29 19:54:23 dbaumann Exp $
#
###############################################################################

[defcommand patient-default {{patient {}}} top.support
{Usage:
    patient-default [<patient>]

Examples:
    "patient-default motif"	- makes "motif" the patient-default
    "patient-default"		- print the name of current patient-default

Synopsis:
    Specifies the default patient.

Notes:
    * Some commands which need a patient argument may use the patient-default
      if no patient is specified.  (e.g. send, run)

See also:
    send, run, sym-default
}
{
    global defaultPatient

    if {[null $patient]} {
	if {![null $defaultPatient]} {
	    echo $defaultPatient
	}
    } else {
	var defaultPatient $patient
    }
}]
