/*
 * Copyright (c) 1987 Regents of the University of California.
 * All rights reserved.  The Berkeley software License Agreement
 * specifies the terms and conditions for redistribution.
 *
 *
 *
 *	$Id: print.c,v 1.2 92/12/06 15:21:18 chrisb Exp $
 */

#ifndef lint
static char sccsid[] = "@(#)print.c	1.1 (Berkeley) 3/16/87";
#endif not lint

#include "ctags.h"
#include <sys/types.h>
#include "compat/file.h"
#include "compat/string.h"
#include "compat/stdlib.h"

extern char	searchar;		/* ex search character */

/*
 * getline --
 *	get the line the token of interest occurred on,
 *	prepare it for printing.
 */
void
getline(void)
{
	register long	saveftell;
	register int	c,
			cnt;
	register char	*cp;

	saveftell = ftell(inf);
	(void)fseek(inf,lineftell,L_SET);
	if (xflag)
		for (cp = lbuf;GETC(!=,'\n');*cp++ = c);
	/*
	 * do all processing here, so we don't step through the
	 * line more than once; means you don't call this routine
	 * unless you're sure you've got a keeper.
	 */
	else for (cnt = 0,cp = lbuf;GETC(!=,EOF) && cnt < ENDLINE;++cnt) {
		if (c == (int)'\\') {		/* backslashes */
			if (cnt > ENDLINE - 2)
				break;
			*cp++ = '\\'; *cp++ = '\\';
			++cnt;
		}
		else if (c == (int)searchar) {	/* search character */
			if (cnt > ENDLINE - 2)
				break;
			*cp++ = '\\'; *cp++ = c;
			++cnt;
		}
		else if (c == (int)'\n') {	/* end of keep */
			*cp++ = '$';		/* can find whole line */
			break;
		}
		else
			*cp++ = c;
	}
	*cp = EOS;
	(void)fseek(inf,saveftell,L_SET);
}

/*
 * put_entries --
 *	write out the tags
 */
void
put_entries(register NODE *node)
{
	extern FILE	*outf;		/* ioptr for tags file */
	extern int	vflag;		/* -v: vgrind style output */

	if (node->left)
		put_entries(node->left);
	if (vflag)
		printf("%s %s %d\n",
		    node->entry,node->file,(node->lno + 63) / 64);
	else if (xflag)
		printf("%-16s%4d %-16s %s\n",
		    node->entry,node->lno,node->file,node->pat);
	else if (node->lno == 0)
		/*
		 * Special hack to allow files themselves to be taggable.
		 * If the line number is 0, make the "search pattern" be just
		 * "1", no search character or anything. This will cause
		 * vi and emacs to just go to that line number -- chrisb
		 */
		fprintf(outf,"%s\t%s\t1\n", node->entry,node->file);
	else
		fprintf(outf,"%s\t%s\t%c^%s%c\n",
		    node->entry,node->file,searchar,node->pat,searchar);
	if (node->right)
		put_entries(node->right);
}

char *
savestr(char *str)
{
	register u_int	len;
	register char	*space;
	char	*malloc();

	len = strlen(str) + 1;
	if (!(space = malloc((u_int)len))) {
		/*
		 * should probably free up the tree, here,
		 * we're just as likely to fail here as we
		 * are when getting the NODE structure
		 */
		fputs("ctags: no more space.\n",stderr);
		exit(1);
	}
	bcopy(str,space,len);
	return(space);
}
