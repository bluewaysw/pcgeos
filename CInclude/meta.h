/***********************************************************************
 *
 * PROJECT:       Meta
 * FILE:          meta.h
 * DESCRIPTION:   GString/GrObj meta layer common definitions
 *
 * AUTHOR:        Marcus Groeber
 *
 ***********************************************************************/

#ifndef __META_H
#define __META_H

/* masks for conversion options */
#define SETTINGS_DOTEXT       1         /* convert text objects? */
#define SETTINGS_CREATE_GROBJ 2         /* create GrObjs, not GString */
#define SETTINGS_OPT_SPLINES  4         /* attempt to create splines? */
#define SETTINGS_DOARCS       32768     /* convert elliptical arcs? */

/* maximum number of points in a polyline */
#define MAX_POINTS 4096

WWFixedAsDWord _export _pascal rad(sword dx,sword dy);
WWFixedAsDWord _export _pascal phi(sword dx,sword dy);

/*
 * prototypes for "meta" drawing commands
 */
void _export _pascal
Meta_SetLineColor(ColorFlag flag,word redOrIndex,word green,word blue);

void _export _pascal
Meta_SetAreaColor(ColorFlag flag,word redOrIndex,word green,word blue);

void _export _pascal Meta_SetFillRule(RegionFillRule windingRule);
void _export _pascal Meta_SetLineStyle(LineStyle ls);
void _export _pascal Meta_SetLineWidth(WWFixedAsDWord lw);
void _export _pascal Meta_SetAreaFill(SystemDrawMask sdm);
void _export _pascal Meta_SetLineFill(SystemDrawMask sdm);

void _export _pascal
Meta_SetScaling(sword w_x1,sword w_y1,sword w_x2,sword w_y2,
                word g_x,word g_y);

WWFixedAsDWord _export _pascal Meta_GetScaling(void);

void _export _pascal Meta_SetClipRect(sword x1,sword y1,sword x2,sword y2);

void _export _pascal
Meta_SetPatternBack(ColorFlag flag,word redOrIndex,word green,word blue);

void _export _pascal Meta_SetTransparency(Boolean flag);

void _export _pascal Meta_Line(sword x1,sword y1,sword x2,sword y2);
void _export _pascal Meta_Polyline(Point *p,word np);
void _export _pascal Meta_Polygon(Point *p,word np,Boolean in,Boolean edges);

void _export _pascal
Meta_Rect(sword x1,sword y1,sword x2,sword y2,Boolean in,Boolean edges);

void _export _pascal
Meta_Ellipse(sword cex,sword cey,sword rx,sword ry,sword angle,
             Boolean in,Boolean edges);

void _export _pascal
Meta_EllipticalArc(sword cex,sword cey,sword rx,sword ry,sword angle,
                   sword as,sword ae,ArcCloseType act,
                   Boolean in,Boolean edges);

void _export _pascal
Meta_ArcThreePoint(Point *p,ArcCloseType act,Boolean in,Boolean edges);

void _export _pascal Meta_BeginPath(void);
void _export _pascal Meta_EndPath(Boolean in,Boolean edges);

void _export _pascal Meta_TextAt(int x,int y,char *s,WWFixedAsDWord size,sword angle);

word _export _pascal Meta_Start(
  word settings,GStateHandle gs,optr body,VMFileHandle vmf);
int _export _pascal Meta_End(void);

#endif
