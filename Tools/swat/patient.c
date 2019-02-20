/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Generic Patient Manipulation
 * FILE:	  patient.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Patient_ByName	    Find a Patient of the given name
 *	Patient_Continue    Continue the machine in a manner appropriate to
 *	    	    	    the current state of things (Use Ibm_Continue).
 *	Patient_Step	    Step by a source line (commented out)
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Utility functions for dicking with patients (many are commented
 *	out until they become useful...)
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: patient.c,v 4.4 96/06/13 17:18:45 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "break.h"
#include "cmd.h"
#include "event.h"
#include "private.h"
#include "sym.h"
#include "type.h"


Lst	    	patients = (Lst)NULL;
Patient	    	kernel;
Patient	    	loader;


/***********************************************************************
 *				PatientHasName
 ***********************************************************************
 * SYNOPSIS:	    See if a patient has a desired name
 * CALLED BY:	    INTERNAL via Lst_Find
 * RETURN:	    0 if it does.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 3/88	Initial Revision
 *
 ***********************************************************************/
static int
PatientHasName(Patient patient, char *name)
{
    return (strcmp(patient->name, name));
}

/***********************************************************************
 *				Patient_ByName
 ***********************************************************************
 * SYNOPSIS:	    Locate a particular patient by its name
 * CALLED BY:	    GLOBAL (Sym_Lookup, e.g.)
 * RETURN:	    The Patient or NullPatient if none exists.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Does a Lst_Find on patients...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/15/88	Initial Revision
 *
 ***********************************************************************/
Patient
Patient_ByName(char *name)
{
    LstNode 	ln;

    ln = Lst_Find(patients, (LstClientData)name, PatientHasName);

    if (ln != NILLNODE) {
	return((Patient)Lst_Datum(ln));
    } else if (Ibm_MaybeUnignore(name)) {
	return(Patient_ByName(name));
    } else {
	return(NullPatient);
    }
}
