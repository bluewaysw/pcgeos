/***********************************************************************
 *
 * PROJECT:	  PCGEOS host tools
 * MODULE:	  img86box
 * FILE:	  hostdir.h
 *
 * DESCRIPTION:
 *	Host directory enumeration. Kept apart from the FatFs code
 *	because both the host headers and FatFs define a DIR type.
 *
 ***********************************************************************/
#ifndef _HOSTDIR_H_
#define _HOSTDIR_H_

typedef struct HostDir HostDir;

extern HostDir	    *HostDir_Open(const char *path);
/* returns the next name (not "." or "..") or NULL at the end */
extern const char   *HostDir_Read(HostDir *dir);
extern void	    HostDir_Close(HostDir *dir);

#endif /* _HOSTDIR_H_ */
