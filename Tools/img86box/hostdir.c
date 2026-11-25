/***********************************************************************
 *
 * PROJECT:	  PCGEOS host tools
 * MODULE:	  img86box
 * FILE:	  hostdir.c
 *
 * DESCRIPTION:
 *	Host directory enumeration (see hostdir.h).
 *
 ***********************************************************************/
#include <stdlib.h>
#include <string.h>

#if defined(__WATCOMC__) && !defined(_LINUX)
# include <direct.h>
#else
# include <dirent.h>
#endif

#include "hostdir.h"

struct HostDir {
    DIR	    *dir;
};

HostDir *
HostDir_Open(const char *path)
{
    HostDir *hd;
    DIR	    *dir = opendir(path);

    if (dir == NULL) {
	return NULL;
    }
    hd = (HostDir *)malloc(sizeof(HostDir));
    if (hd == NULL) {
	closedir(dir);
	return NULL;
    }
    hd->dir = dir;
    return hd;
}

const char *
HostDir_Read(HostDir *hd)
{
    struct dirent *de;

    while ((de = readdir(hd->dir)) != NULL) {
	if (strcmp(de->d_name, ".") && strcmp(de->d_name, "..")) {
	    return de->d_name;
	}
    }
    return NULL;
}

void
HostDir_Close(HostDir *hd)
{
    closedir(hd->dir);
    free(hd);
}
