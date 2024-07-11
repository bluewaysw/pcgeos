/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	PC GEOS					     
* 	MODULE:							     
* 	FILE:		math.c				     
*								     
*	AUTHOR:		jimmy lefkowitz				     
*								     
*	REVISION HISTORY:					     
*								     
*	Name	Date		Description			     
*	----	----		-----------			     
*	jimmy	6/14/94		Initial version			     
*								     
*	DESCRIPTION:  provide some standard calls into the math library
*								     
*	$Revision: 1.2 $
*							   	     
*********************************************************************/


#include <geos.h>
#include <math.h>
#include <stdio.h>
#include <Ansi/string.h>
#include <file.h>
#include <object.h>

/*********************************************************************
 *			srand
 *********************************************************************
 * SYNOPSIS: 	a routine to seed the random number generator
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/14/94		Initial version			     
 * 
 *********************************************************************/
void
srand(int   seed)
{
    FloatRandomize(RGIF_USE_SEED, seed);
}



/*********************************************************************
 *			pow
 *********************************************************************
 * SYNOPSIS: 	do an exponential
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS: replaced with math library version of pow
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/14/94		Initial version			     
 * 
 *********************************************************************/
#if 0
double pow(double x, double y)
{
    FloatIEEE64ToGeos80(&x);
    FloatIEEE64ToGeos80(&y);
    FloatExponential();
    FloatGeos80ToIEEE64(&x);
    return x;
}

/*********************************************************************
 *			exp
 *********************************************************************
 * SYNOPSIS: 	do an exponential
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/14/94		Initial version			     
 * 
 *********************************************************************/
double exp(double x)
{
    FloatIEEE64ToGeos80(&x);
    FloatExp();
    FloatGeos80ToIEEE64(&x);
    return x;
}

/*********************************************************************
 *			log
 *********************************************************************
 * SYNOPSIS: 	do an log
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/14/94		Initial version			     
 * 
 *********************************************************************/
#ifndef __HIGHC__
double log(double x)
{
    FloatIEEE64ToGeos80(&x);
    FloatLn();
    FloatGeos80ToIEEE64(&x);
    return x;
}
#endif

/*********************************************************************
 *			fmod
 *********************************************************************
 * SYNOPSIS: 	do a FloatMod
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	    	FloatMod is screwed, so just do it using other math
 *	    	so an divide and trunc, and then multiply the result
 *	    	times the divisor, and subtract that value from the
 *	    	numerator and we have the value we want
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/14/94		Initial version			     
 * 
 *********************************************************************/
double fmod(double x, double y)
{
    FloatIEEE64ToGeos80(&x);
    FloatDup();	    	    	/* we will need x twice, so dup it now */
    FloatIEEE64ToGeos80(&y);
    FloatDivide();
    FloatTrunc();   	    	
    FloatIEEE64ToGeos80(&y);
    FloatMultiply();
    FloatSub();
    FloatGeos80ToIEEE64(&x);
    return x;
}


/*********************************************************************
 *			fabs
 *********************************************************************
 * SYNOPSIS: 	do an absolute value
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/14/94		Initial version			     
 * 
 *********************************************************************/
double fabs(double x)
{
    FloatIEEE64ToGeos80(&x);
    FloatAbs();
    FloatGeos80ToIEEE64(&x);
    return x;
}


/*********************************************************************
 *			floor
 *********************************************************************
 * SYNOPSIS: 	do a floor function
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/14/94		Initial version			     
 * 
 *********************************************************************/
double floor(double x)
{
    FloatIEEE64ToGeos80(&x);
    FloatInt();
    FloatGeos80ToIEEE64(&x);
    return x;
}
#endif


/*********************************************************************
 *			atof
 *********************************************************************
 * SYNOPSIS: convert an ascii string to a float
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/14/94		Initial version			     
 * 
 *********************************************************************/
double _pascal atof(const char *string)
{
    double     retVal;

    FloatAsciiToFloat(FAF_PUSH_RESULT, strlen(string), string, NULL);
    FloatGeos80ToIEEE64(&retVal);
    return retVal;
}


/*********************************************************************
 *			ceil
 *********************************************************************
 * SYNOPSIS: 	do a ceiling function
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/14/94		Initial version			     
 * 
 *********************************************************************/
double ceil(double x)
{
    double  y;

    FloatIEEE64ToGeos80(&x);
    FloatTrunc();
    FloatGeos80ToIEEE64(&y);
    
    /* if the number was an integer already, so there was no change then
     * then number just gets returned, if the number was negative and
     * not an integer then just return the truncated number and if the
     * number was positive and not an integer add one to the truncated
     * number
     */
    if (x != y && x > 0.0)
    {
	y += 1;
    }
    return y;
}


/*********************************************************************
 *			modf
 *********************************************************************
 * SYNOPSIS: 	do a modulus returning both fractional and integer parts
 * CALLED BY:	OpMod
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	this routine deals with negative values by returning a
 * 	    	negative iptr value decremented by one so that when
 * 	    	OpMod calls this it ends up on the positive side of zero
 *	    	rather than the negative side
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	6/15/94		Initial version			     
 * 
 *********************************************************************/
double modf(double value, double *iptr)
{
    double  fractpart;

    FloatIEEE64ToGeos80(&value);
    FloatIntFrac();
    FloatGeos80ToIEEE64(&fractpart);
    FloatGeos80ToIEEE64(iptr);

    if (value < 0.0) 
    {
	(*iptr)--;
    }
    return fractpart;
}

/*
int fputc()
{
return 0;
}
*/


/*********************************************************************
 *			round
 *********************************************************************
 * SYNOPSIS:	Do a round to the specified number of places
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	eca	9/ 8/97  	Initial version
 * 
 *********************************************************************/
double
round(double x, word num)
{
	FloatIEEE64ToGeos80(&x);
	FloatRound(num);
	FloatGeos80ToIEEE64(&x);
	return(x);
}
