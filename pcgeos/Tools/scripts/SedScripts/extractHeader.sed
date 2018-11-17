/COMMENT @/,/@$/{
	p
	/@$/q
}
/COMMENT }/,/}$/{
	p
	/}$/q
}
/^\*/,/^\*/{
p
:loop
n
p
/^\*/!bloop
q
}

