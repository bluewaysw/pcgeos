/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	PC GEOS					     
* 	MODULE:							     
* 	FILE:		mymath.h				     
*								     
*	AUTHOR:		jimmy lefkowitz				     
*								     
*	REVISION HISTORY:					     
*								     
*	Name	Date		Description			     
*	----	----		-----------			     
*	jimmy	7/12/94		Initial version			     
*								     
*	DESCRIPTION:						     
*								     
*	$Id: mymath.h,v 1.1 98/10/05 12:54:22 martin Exp $
*							   	     
*********************************************************************/
extern void 	    srand(int seed);
extern long 	    rand(void);
#if 0
/* Added to global math library 3/9/2000 */
extern double       pow(double base, double exp);
extern double	    log(double base);
extern double	    fmod(double x, double y);
extern double	    fabs(double x);
extern double	    ceil(double x);
extern double	    floor(double x);
extern double 	    exp(double x);
#endif
extern double	    modf(double value, double *iptr);
extern double	    round(double x, word num);
