#include <stdio.h>
#include <a.out.h>
#include <sys/file.h>
#include <ctype.h>

char	    	*strings;

int
atox(register char  *cp)
{
    register int  n;
    
    if (*cp == '0' && cp[1] == 'x') {
	cp += 2;
    }
    n = 0;
    while (isxdigit(*cp)) {
	if (isdigit(*cp)) {
	    n = 16 * n + *cp - '0';
	} else if (islower(*cp)) {
	    n = 16 * n + *cp - 'a' + 10;
	} else {
	    n = 16 * n + *cp - 'A' + 10;
	}
	cp++;
    }
    return(n);
}

main(argc, argv)
    int	    argc;
    char    **argv;
{
    struct exec	    header;
    struct nlist    *cs;
    int	    	    i, j;
    FILE    	    *f;
    struct foo {
	long	    addr;
	char	    *name;
	long	    diff;
    }	    	    *ans, *cur;
    struct nlist    nl;

    f = fopen(argv[1], "r");
    if (f == NULL) {
	perror(argv[1]);
	exit(1);
    }
    fread(&header, sizeof(header), 1, f);
    fseek(f, N_STROFF(header), L_SET);
    i = getw(f);
    strings = malloc(i);
    fread(strings+4, i-4, 1, f);

    ans = (struct foo *)malloc(sizeof(struct foo) * (argc - 2));

    for (i = 2; i < argc; i++) {
	ans[i-2].addr = atox(argv[i]);
	ans[i-2].diff = 0x7fffffff;
	ans[i-2].name = 0;
    }

    i = header.a_syms / sizeof(struct nlist);
    fseek(f, N_SYMOFF(header), L_SET);

    while(i > 0) {
	fread(&nl, sizeof(nl), 1, f);
	switch (nl.n_type) {
	    case N_TEXT:
	    case N_TEXT|N_EXT:
		for (j = 2, cur = ans; j < argc; cur++, j++) {
		    if ((cur->addr >= nl.n_value) &&
			(cur->addr-nl.n_value <= cur->diff))
		    {
			cur->diff = cur->addr - nl.n_value;
			cur->name = nl.n_un.n_strx + strings;
		    }
		}
		break;
	}
	i--;
    }
    for (i = 2, cur = ans; i < argc; i++, cur++) {
	if (cur->name) {
	    printf("%s\n", cur->name);
	} else {
	    printf("nil\n");
	}
    }
}
