/***********************************************************************
 *
 * PROJECT:       META
 * FILE:          METAINT.h
 *
 * DESCRIPTION:   Declarations shared between META's modules
 *
 * AUTHOR:        Marcus Gr”ber
 *
 ***********************************************************************/

RGBColorAsDWord _pascal My_GrMapColorIndex(GStateHandle gs,Color c);
void _Meta_optimizedLine(GStateHandle gs,sword x1,sword y1,sword x2,sword y2);
Boolean _Meta_optimizedPolyline(GStateHandle gs,Point *p,word np,Boolean close);

/* Type-independent minimum, maximum, absolute value: */
#define min(a,b) ((a)<(b)?(a):(b))
#define max(a,b) ((a)>(b)?(a):(b))
#define abs(a)   (((a)>0)?(a):-(a))

