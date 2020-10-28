/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Tools
MODULE:		Win32 support library
FILE:		registry.c

AUTHOR:		Jacob A. Gabrielson, Nov 18, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jacob	11/18/96   	Initial version

DESCRIPTION:
	Common Registry routines.

	$Id: registry.c,v 1.1 97/04/17 17:57:39 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>

#include <compat/windows.h>
#include <stdio.h>

typedef int	Boolean;
#include "winutil.h"


/***********************************************************************
 *				Registry_FindStringValueInternal
 ***********************************************************************
 *
 * SYNOPSIS:	    Return the value of Key in the registry.
 * CALLED BY:	    (GLOBAL)
 * RETURN:	    return TRUE if successful, else FALSE
 * SIDE EFFECTS:    Set dataBuffer to the value of Key in the registry.
 *		    Assumes value is a string.
 *		    Set Buffer to Nil if not found.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ron	11/18/96   	Initial Revision
 *
 ***********************************************************************/
Boolean
Registry_FindStringValueInternal (const char *regPath, /* something like
						  * "Software\\Geoworks" */
				  const char *regKey,  /* like "ROOT_DIR" */
				  unsigned char *dataBuffer, /* allocated 
							      * space to 
							      * get result */
				  long buflen) 	      /* length of buffer */
{
    HKEY	geosKey;
    DWORD	result;		/* was the operation a success? */
    DWORD	valueType;	/* temp used in ReqQueryValueEx */
    DWORD	dataSize;	/* stores how much data was read. */

    dataBuffer[0] = 0;

    /*
     * Check to see if we have a registry setting.
     */
    result = RegOpenKeyEx(HKEY_CURRENT_USER,
			  regPath,
			  0,
			  KEY_ALL_ACCESS,
			  &geosKey);
    if (result != ERROR_SUCCESS) {
	return FALSE;
    }

    result = RegQueryValueEx(geosKey,
			     regKey,
			     0,
			     &valueType,
			     NULL,
			     &dataSize);

    if ((result != ERROR_SUCCESS) || (valueType != REG_SZ) 
	|| (dataSize > buflen)) {

	RegCloseKey(geosKey);
	return FALSE;
    }

    result = RegQueryValueEx(geosKey,
			     regKey,
			     0,
			     &valueType,
			     dataBuffer,
			     &dataSize);
    if (result != ERROR_SUCCESS) {
	RegCloseKey(geosKey);
	return FALSE;
    }

    return TRUE;
}	/* End of Registry_FindStringValueInternal.	*/


#define REG_RETRIES 4
/***********************************************************************
 *				Registry_FindStringValue
 ***********************************************************************
 *
 * SYNOPSIS:	    Wrapper fn to try it twice to avoid reg problem
 * CALLED BY:	    (GLOBAL)
 * RETURN:	    return TRUE if successful, else FALSE
 * SIDE EFFECTS:    Set dataBuffer to the value of Key in the registry.
 *		    Assumes value is a string.
 *		    Set Buffer to Nil if not found.
 *
 * STRATEGY:	    Registry has been failing sometimes, but works on
 *		    subsequent calls.  Haven't figured it out, but this
 *		    should hopefully get rid of the problem
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ron	11/18/96   	Initial Revision
 *
 ***********************************************************************/
Boolean
Registry_FindStringValue (const char *regPath, /* something like
						* "Software\\Geoworks\\Swat" */
			  const char *regKey,  /* something like "SWATHOME" */
			  unsigned char *dataBuffer, /* allocated space to 
						      * get result */
			  long buflen) 	      /* length of buffer */
{
    Boolean	retVal;
    int		loops;

    for (loops = 1; loops <= REG_RETRIES; loops++) {
	retVal = Registry_FindStringValueInternal(regPath, regKey, 
						  dataBuffer, buflen);
	if (retVal == TRUE) {
	    return TRUE;
	}
    }
    return FALSE;
}	/* End of Registry_FindStringValue.	*/



/***********************************************************************
 *				Registry_UpdateStringValue
 ***********************************************************************
 *
 * SYNOPSIS:	    Set the value of Key in the registry.
 * CALLED BY:	    (GLOBAL)
 * RETURN:	    void
 * SIDE EFFECTS:    
 *	Creates itermediate paths if they don't exist.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jacob	11/18/96   	Initial Revision
 *
 ***********************************************************************/
Boolean
Registry_UpdateStringValue (const char *regPath, 
			    const char *regKey, 
			    unsigned char *dataBuffer)
{
    HKEY	geosKey;
    DWORD	result;		/* was the operation a success? */
    DWORD	valueType =REG_SZ;
    DWORD	dataSize;	/* how much data was read. */

    /*
     * Check to see if we have a registry setting.
     */
    result = RegCreateKey(HKEY_CURRENT_USER,
			  regPath,
			  &geosKey);
    if (result != ERROR_SUCCESS) {
	return FALSE;
    }

    dataSize = strlen((char *) dataBuffer) + 1;

    result = RegSetValueEx(geosKey,
			   regKey,
			   0,
			   valueType,
			   dataBuffer,
			   dataSize);

    RegCloseKey(geosKey);

    if (result != ERROR_SUCCESS) {
	return FALSE;
    } 

    return TRUE;
}	/* End of Registry_UpdateStringValue.	*/


/***********************************************************************
 *				Registry_FindDWORDValue
 ***********************************************************************
 *
 * SYNOPSIS:	    Return the value of Key in the registry.
 * CALLED BY:	    (GLOBAL)
 * RETURN:	    Return the value of Key in the registry.
 *		    Assumes value is a dword.
 *		    Set Buffer to Nil if not found.
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ron	11/18/96   	Initial Revision
 *
 ***********************************************************************/
Boolean
Registry_FindDWORDValue (const char *regPath,  /* something like
						* "Software\\Geoworks\\Swat" */
			 const char *regKey,   /* something like "SWATHOME" */
			 long *longval)  /* allocated space to 
					  * get result */
{
    HKEY	geosKey;
    DWORD	result;		/* was the operation a success? */
    DWORD	valueType;	/* temp used in ReqQueryValueEx */
    DWORD	dataSize;	/* stores how much data was read. */
    DWORD	dw;
    /*
     * Check to see if we have a registry setting.
     */
    *longval = dw = 0;
    result = RegOpenKeyEx(HKEY_CURRENT_USER,
			  regPath,
			  0,
			  KEY_ALL_ACCESS,
			  &geosKey);
    if (result != ERROR_SUCCESS) {
	return FALSE;
    }

    result = RegQueryValueEx(geosKey,
			     regKey,
			     0,
			     &valueType,
			     NULL,
			     &dataSize);

    if ((result != ERROR_SUCCESS) || (valueType != REG_DWORD) 
	|| (dataSize > sizeof(dw))) {

	RegCloseKey(geosKey);
	return FALSE;
    }

    result = RegQueryValueEx(geosKey,
			     regKey,
			     0,
			     &valueType,
			     (unsigned char*)&dw,
			     &dataSize);

    RegCloseKey(geosKey);

    if (result != ERROR_SUCCESS) {
	return FALSE;
    }

    *longval = dw;

    return TRUE;
}	/* End of Registry_FindDWORDValue.	*/


/***********************************************************************
 *				Registry_UpdateDWORDValue
 ***********************************************************************
 *
 * SYNOPSIS:	    Set the value of Key in the registry.
 * CALLED BY:	    (GLOBAL)
 * RETURN:	    void
 * SIDE EFFECTS:    
 *	Creates itermediate paths if they don't exist.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jacob	11/18/96   	Initial Revision
 *
 ***********************************************************************/
Boolean
Registry_UpdateDWORDValue (const char *regPath, 
			   const char *regKey, 
			   long *longval)
{
    HKEY	geosKey;
    DWORD	result;		/* was the operation a success? */
    DWORD	valueType =REG_DWORD;
    DWORD	dataSize;	/* how much data was read. */
    DWORD	dw;

    dw = *longval;

    /*
     * Check to see if we have a registry setting.
     */
    result = RegCreateKey(HKEY_CURRENT_USER,
			  regPath,
			  &geosKey);
    if (result != ERROR_SUCCESS) {
	return FALSE;
    }

    dataSize = sizeof(dw);

    result = RegSetValueEx(geosKey,
			   regKey,
			   0,
			   valueType,
			   (unsigned char*)&dw,
			   dataSize);

    RegCloseKey(geosKey);

    if (result != ERROR_SUCCESS) {
	return FALSE;
    }

    return TRUE;
}	/* End of Registry_UpdateDWORDValue. */
