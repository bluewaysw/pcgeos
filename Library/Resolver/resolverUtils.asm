COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Socket project
MODULE:		resolver
FILE:		resolverUtils.asm

AUTHOR:		Steve Jang, Dec 14, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94   	Initial revision

DESCRIPTION:
	Various utilities for resolver.		

	$Id: resolverUtils.asm,v 1.11 97/12/11 02:43:02 allen Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResolverActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeAddChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a child to a tree node
CALLED BY:	Utility
PASS:		ds:di	  = parent
		ds:si/*bp = child to add
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeAddChildFar	proc	far
		call	TreeAddChild
		ret
TreeAddChildFar	endp

TreeAddChild	proc	near
		uses	bx, di
		.enter
	;
	; Make *ds:bx = parent
	; cur.prev = *parent
	;
		ChunkPtrToLptr ds, di, bx	; *ds:bp  = parent chunk
		mov	ds:[si].NC_prev, bx
	;
	; cur.level = parent.level + 1
	;
		mov	bx, ds:[di].NC_flags
		and	bx, mask NF_LEVEL
		inc	bx
		or	ds:[si].NC_flags, bx
	;
	; cur.next = parent.child
	;
		mov	bx, ds:[di].NC_child	; bx = next(sibling or parent)
		mov	ds:[si].NC_next, bx
	;
	; parent.child = cur
	;
		mov	ds:[di].NC_child, bp
	;
	; update flags
	;
		test	ds:[di].NC_flags, mask NF_HAS_CHILD
		jnz	haveSibling
		BitSet	ds:[di].NC_flags, NF_HAS_CHILD
		BitSet	ds:[si].NC_flags, NF_LAST
		jmp	done
haveSibling:
	;
	; So, we are not the last of sibling
	;
		BitClr	ds:[si].NC_flags, NF_LAST
	;
	; update our sibling's prev pointer
	;
		mov	di, ds:[bx]		; ds:di = next sibling
		mov	ds:[di].NC_prev, bp
done:
		.leave
		ret
TreeAddChild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeRemoveNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a node from tree
CALLED BY:	Utility
PASS:		ds:si/*bp = node to remove
RETURN:		nothing
		pointers are updated, and ds:si/*bp was removed from tree
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeRemoveNode	proc	near
		uses	ax, bx, di
		.enter

EC <		test	ds:[si].NC_flags, mask NF_ROOT			>
EC <		ERROR_NZ RFE_TREE_BUG					>
	;
	; bx = cur.next
	;
		clr	bx
		xchg	bx, ds:[si].NC_next	; *bx = next node
		mov	di, ds:[si].NC_prev	; *di = prev node
		mov	di, ds:[di]		; ds:di = prev node
	;
	; Are we removing a child?
	;
		cmp	ds:[di].NC_child, bp
		je	removeChild
removeSibling::
	;
	; Removing sibling
	; prev.next = cur.next
	;
		mov	ds:[di].NC_next, bx
	;
	; cur node = last sibling?
	;
		test	ds:[si].NC_flags, mask NF_LAST
		jz	middleSibling
	;
	; We just removed last sibling
	; prev node becomes last sibling now
	;
		BitSet	ds:[di].NC_flags, NF_LAST
		jmp	done
middleSibling:
middleChild:
	;
	; update nextNode.prev
	;
		mov	di, ds:[bx]		; deref next node ds:di
		segmov	ds:[di].NC_prev, ds:[si].NC_prev, ax
done:
		.leave
		ret
removeChild:
	;
	; ds:di = parent
	; bx = next sibling
	; prev.child = cur.next
	;
		mov	ds:[di].NC_child, bx
	;
	; if cur node = last child, the parent does not have a child anymore
	;
		test	ds:[si].NC_flags, mask NF_LAST
		jz	middleChild
		BitClr	ds:[di].NC_flags, NF_HAS_CHILD
		jmp	done
TreeRemoveNode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeGotoNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to next node
CALLED BY:	Utility
PASS:		ds:si = current node
RETURN:		ds:di = current node
		ds:si/*bp = next node
		carry set if went back up to parent
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeGotoNext	proc	near
		mov_tr	di, si
		test	ds:[di].NC_flags, mask NF_ROOT
;EC <		ERROR_NZ RFE_TREE_CORRUPTED				>
NEC <		stc							>
NEC <		jnz	done						>
		mov	bp, ds:[di].NC_next
EC <		tst	bp						>
EC <		ERROR_Z	RFE_TREE_CORRUPTED				>
		mov	si, ds:[bp]
		test	ds:[di].NC_flags, mask NF_LAST
		stc
		jnz	done
		clc
done:
		ret
TreeGotoNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeGotoChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to child node
CALLED BY:	Utility
PASS:		ds:si = current node
RETURN:		ds:di = current node
		ds:si = first child node
		ds:*bp = same as ds:si
		carry set if no child
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeGotoChild	proc	near
		test	ds:[si].NC_flags, mask NF_HAS_CHILD
		stc
		jz	done
		mov_tr	di, si
		mov	bp, ds:[di].NC_child
		mov	si, ds:[bp]
		clc
done:
		ret
TreeGotoChild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeGotoParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to parent
CALLED BY:	Utility
PASS:		ds:si	= a tree node
RETURN:		carry set if this is the root
			ds:si	= parent
		carry clear if not
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeGotoParent	proc	near
		uses	di, bp
		.enter
		test	ds:[si].NC_flags, mask NF_ROOT
		jnz	root
nextLoop:
		call	TreeGotoNext
		jnc	nextLoop
		clc
done:
		.leave
		ret
root:
		stc
		jmp	done
TreeGotoParent	endp

TreeGotoParentFar proc	far
		call	TreeGotoParent
		ret
TreeGotoParentFar endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Traverse a subtree calling the callback routine provided

CALLED BY:	Utility
PASS:		ds:si	= node to start traversing from
		ds:*bp	= same as ds:si
		ds:di	= previous node( if ds:si = root, ds:di = root also )
		bxax	= virtual far pointer(or fptr) to callback routine
		dx, es = parameters passed into callback
		
CALLBACK:
		Callback routine is called TWICE at each node; once on the way
		down the tree(the first time), and once on the way up the tree(
		the second time).  You can tell this by testing carry.

		PASS:	ds:di = previous node
			ds:si = current node
			ds:*bp= same as ds:si
			cx    = current level( 1 for the first node passed in )
			dx, es = parameters passed in
			carry clear on the first time called
			carry set on the second time called
		RETURN:
			ds must be readjusted if heap was moved
			carry set to stop traversing
			  ds:*bp = last node visited
			  ds:si  = last node visited
			  ds:di  = previous node to last node visited
			  dx, es = return value
			carry clr to continue
			  dx, es = value to pass into next callback
			  bp     = NOT destroyed unless you used the code
				   fragment below
		DESTROYS:
			allowed to destroy ax, bx, cx, di, si

	    *** CREATING A NODE INSIDE CALLBACK ***

		ds:si and ds:di may move around.  Be prepared for this!

		Note that if you create a child node and attach to the current
		node when the callback was called for the first time, the child
		will also be enum'ed.  But if you do the same thing on the
		second time the callback was called, the child will not be
		enumed( since the tree is trying to go up the tree now ).

	    *** REMOVING A NODE INSIDE CALLBACK ***

		Removing a node inside callback routine is a tricky business.
		Please use the following code:

		( Usually I would expect people to remove leaf nodes, but if
		  that's not the case, you need to figure out what to do with
		  the subtree you are removing. Please refer to the following
		  code at any rate. )

			--------------------
		;
		; in order to make the TreeEnum continue visiting the
		; next node, we need to fool TreeEnum by setting up temp
		; node and jumping to it.  Now set up temp node.
		; -- this temp node is already there.
		;
		push	di
		mov	di, ds:CBH_temp
		mov	di, ds:[di]
		segmov	ds:[di].NC_flags, ds:[si].NC_flags, ax
		segmov	ds:[di].NC_next, ds:[si].NC_next, ax
		pop	di
		;
		; ds:si/*bp = current node
		;
		call	TreeRemoveNode
		mov	ax, bp
		call	LMemFree		; free the chunk
		;
		; now jump to temp node
		;
		mov	bp, ds:CBH_temp

			    OR

		call	TreeRemoveNode
		mov	ax, bp
		call	LMemFree
		stc				; to stop enum'ing

			--------------------

		to make sure that TreeEnum can continue to the next node in the
		tree, and previous node is set correctly for the next node to
		be enum'ed.  Only in this case can bp be changed.

RETURN:		whatever returned from callback routine last called
		ds, si = last node visited

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeEnum	proc	far
		uses	cx
		.enter
	;
	; first tree level = 1
	;
		clr	cx
callback:
	;
	; callback
	;
		push	ax, bx, cx
		call	ProcCallFixedOrMovable	; dx, es = may have changed
		pop	ax, bx, cx
		mov	si, ds:[bp]
		jc	done
	;
	; Go to child
	;
		inc	cx			; pretend we are in next level
		call	TreeGotoChild		; ds:di,ds:si/ds:*bp updated
		jnc	callback
		dec	cx			; no level change
		jz	doneRoot		; if root doesn't have a child
next:						; just exit
	;
	; No child, call the same node again
	;
		stc				; make sure they get CF set
		push	ax, bx, cx
		call	ProcCallFixedOrMovable	; dx, es = may have changed
		pop	ax, bx, cx
		mov	si, ds:[bp]
		jc	done
	;
	; and go to sibling, no level change
	;
		call	TreeGotoNext		; ds:di,ds:si/ds:*bp updated
		jnc	callback		
	;
	; no sibling, we went up a level
	; Check if we are at the node we started at.
	;
		dec	cx
doneRoot:
		tst	cx
		jnz	next			; try siblings again
	;
	; Call callback for the last time at the root of subtree
	;
		stc
		push	ax, bx, cx
		call	ProcCallFixedOrMovable	; dx, es = may have changed
		pop	ax, bx, cx
		mov	si, ds:[bp]
done:
	;
	; carry is set if callback returned carry set
	;
		.leave
		ret
TreeEnum	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeSearchId
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for a request Id in request tree
CALLED BY:	Utility
PASS:		dx	= request id
RETURN:		carry clear if found,
			ds:di = prev request node
			ds:si = RequestNode (locked)
			ds:*bp = same as ds:di
		carry set if not found
			ds,di,si,bp = destroyed (nothing locked)
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeSearchId	proc	near
		uses	ax,bx
		.enter
		mov	bx, handle ResolverRequestBlock
		call	MemLock
		mov	ds, ax
		mov	si, ds:RBH_root
		mov	si, ds:[si]	; ds:si = root of request tree
		call	TreeRecursiveSearchId
		jnc	done
		call	MemUnlock
done:
		.leave
		ret
TreeSearchId	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeRecursiveSearchId
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	recursively search for an Id
CALLED BY:	TreeSearchId
PASS:		ds:si	= node to begin search at
		dx	= request id
RETURN:		carry clear if found,
			ds:di = prev node
			ds:si = node that contains Id
			ds:*bp = same as ds:di
		otherwise
			ds,di,si,bp = trashed
DESTROYED:	see otherwise
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeRecursiveSearchId	proc	near
		uses	ax
		.enter
		cmp	dx, ds:[si].RN_id
		je	found
		call	TreeGotoChild
		jc	done
traverse:
		call	TreeRecursiveSearchId
		jnc	done
		call	TreeGotoNext
		jc	done
		jmp	traverse
found:
		clc
done:
		.leave
		ret
TreeRecursiveSearchId	endp
TreeRecursiveSearchIdFar proc	far
		call	TreeRecursiveSearchId
		ret
TreeRecursiveSearchIdFar endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeSearchDomainName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the best match for a domain name in cache
CALLED BY:	Utility
PASS:		es:di	= domain name
RETURN:		ds:si	= best match
		cx	= number of labels not matched
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeSearchDomainName	proc	near
		uses	ax,bx,dx,es,di
		.enter
		mov	bx, handle ResolverCacheBlock
		call	MemLock
		mov	ds, ax
		mov	si, ds:CBH_root
		mov	si, ds:[si]	; ds:si = root of the cache tree
		call	DomainNameCountLabels	; cx = label count
		call	TreeRecursiveSearchDomainName
		.leave
		ret
TreeSearchDomainName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeRecursiveSearchDomainName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	search for best matching domain name

CALLED BY:	TreeSearchDomainName
PASS:		ds:si	= node to begin search at
		es:di	= domain name
		cx	= which label to match(2 means 2nd label)
RETURN:		ds:si	= node last visited( best match )
		cx	= remaining number of labels to match
DESTROYED:	ax,bx,dx
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeRecursiveSearchDomainName	proc	near
		uses	bp,di,dx
		.enter
		jcxz	done			; nothing to match
		mov	ax, di			; ax = offset to domain name
		dec	cx			; one level below
		call	DomainNameGotoLabel	; es:di = label to match
		mov	dx, di			; dx = label start
		call	TreeGotoChild		; ds:si = child node
		jc	noProgress
traverseLoop:
		add	si, offset RRN_name	; ds:si = current label
		mov	di, dx
		call	DomainNameMatchLabel
		je	found
		sub	si, offset RRN_name	; ds:si = current node
		call	TreeGotoNext		; ds:si = next node
		jc	noProgress		; ds:si = last visited node
		jmp	traverseLoop		
found:
		sub	si, offset RRN_name	; ds:si = last visited node
		jcxz	done			; we matched all the labels
		mov	di, ax			; recover domain name
		call	TreeRecursiveSearchDomainName
done:
		.leave
		ret
noProgress:
		inc	cx
		jmp	done
TreeRecursiveSearchDomainName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeAddDomainName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a path to a domain name in our RR cache
CALLED BY:	Utility
PASS:		es:di = domain name
RETURN:		carry clear if no error
			ds:si = last node visited or added( locked )
		carry set if memory error
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeAddDomainName	proc	far
		uses	ax,bx,cx,dx,es,di,bp
		.enter
		call	TreeSearchDomainName	; ds:si = best match
		jcxz	done
addLoop:
	;
	; ds:si = parent node
	; es:di = domain name label
	; cx	= # of labels left to add
	;
		call	TreeAddCacheLabel	; ds:si = newly added node
		jc	done
		loop	addLoop
done:
		.leave
		ret
TreeAddDomainName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeAddCacheLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new label to the cache node passed in
CALLED BY:	TreeDomainName
PASS:		ds:si	= parent node
		es:di	= domain name
		cx	= # labels left to add
RETURN:		carry clear if no error,
			ds:si	= newly added node
		carry set if memory error
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeAddCacheLabel	proc	near
		uses	ax,cx,bp,es,di
		.enter
		dec	cx
		call	DomainNameGotoLabel	; es:di = label to add
		push	di			; store label offset
	;
	; Save parent node since we are trying to allocate a chunk below
	;
		ChunkPtrToLptr ds, si, bp	; *ds:bp  = parent chunk
	;
	; allocate new node
	;
		clr	ch
		mov	cl, {byte}es:[di]
		inc	cx
		add	cx, size ResourceRecordNode
		clr	al
		call	LMemAlloc		; ax = new chunk
		jc	error
	;
	; deref parent node
	;
		mov	di, ds:[bp]		; ds:di = parent node
	;
	; Add new node to tree
	;
		mov	bp, ax			; ds:*bp = chunk to add
		mov	si, ds:[bp]		; ds:si  = chunk to add
		clr	ds:[si].NC_flags	; clear flags
		mov	ds:[si].NC_child, bp	; initialize child field
		call	TreeAddChild		; nothing changed
	;
	; Copy label
	;
		segxchg	ds, es			;
		mov	di, si			; es:di = new node
		pop	si			; ds:si = new label
		mov	ax, di			; save new node offset
		add	di, offset RRN_name	; es:di = name field
		sub	cx, size ResourceRecordNode ; cx = # of bytes to copy
EC <		CheckMovsbIntoChunk bp		; *es:bp = child chunk 	>
		rep movsb
		segmov	ds, es, di
		mov_tr	si, ax			; ds:si = new node
	;
	; resource = null
	;
		clr	ax
		mov	ds:[si].RRN_resource.high, ax
		mov	ds:[si].RRN_resource.low, ax
		clc
done:
		.leave
		ret
error:
		pop	di
		jmp	done
TreeAddCacheLabel	endp

; ===========================================================================
;
; 		 	Domain name utilities
;
; ===========================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DomainNameCountLabels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count the name of labels in a given domain name

CALLED BY:	Utility
PASS:		es:di	= DNS format domain name
RETURN:		cx	= number of labels
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DomainNameCountLabels	proc	near
		uses	di,ax
		.enter
		clr	cx
countLoop:
		tst	{byte}es:[di]
		jz	done
		clr	ah
		mov	al, {byte}es:[di]
		inc	ax
		add	di, ax
		inc	cx
		jmp	countLoop
done:
		.leave
		ret
DomainNameCountLabels	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DomainNameGotoLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip |cx| labels
CALLED BY:	Utility
PASS:		es:di	= domain name
		cx	= desired label location
RETURN:		es:di	= the (cx)th label or the end of domain name
		zero flag set if we reached the end of domain name
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DomainNameGotoLabel	proc	near
		uses	ax,cx,ds,si
		.enter
		jcxz	done
goLoop:
		clr	ah
		mov	al, es:[di]
		tst	al
		jz	done
		inc	ax
		add	di, ax
		loop	goLoop
		tst	di	; clear ZF
done:
		.leave
		ret
DomainNameGotoLabel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DomainNameMatchLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Match a label in domain name string
CALLED BY:	Utility
PASS:		ds:si = label1
		es:di = label2
RETURN:		equality ( use je or jne )
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DomainNameMatchLabel	proc	near
		uses	ax,cx,si,di
		.enter

		lodsb
		cmp	al, {byte}es:[di]
		jne	done
		inc	di
		clr	ah
		mov	cx, ax		; cx = # of chars to match
matchLoop:
		lodsb
		mov	ah, es:[di]
		inc	di
		cmp	al, ah
		jne	checkCase
cont:
		loop	matchLoop
		cmp	al, al		; successful match
done:
		.leave
		ret
checkCase:
		cmp	al, 'z'
		jg	done
		cmp	al, 'a'
		jl	uppercase
		xchg	al, ah
uppercase:
		sub	ah, 'a'-'A'
		cmp	al, ah
		je	cont
		jmp	done
DomainNameMatchLabel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DomainNameCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two domain name string

CALLED BY:	Utility
PASS:		ds:si = domain name string 1
		es:di = domain name string 2
RETURN:		cx length of the strings
		zero flag set if they are the same
		zero flag not set if they are different
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DomainNameCompare	proc	far
		uses	ax,dx,si,di
		.enter
		mov	cx, 1		; string length is at least 1
cmpLoop:
		lodsb	; al = {byte}ds:[si]
		mov	ah, {byte}es:[di]
		cmp	al, ah
		jne	checkCase
		tst	al
		jz	done
cont:
		inc	cx
		inc	di
		jmp	cmpLoop
done:
		.leave
		ret
checkCase:
		cmp	al, 'z'
		jg	done
		cmp	al, 'a'
		jl	convertAhUp
		xchg	al, ah
convertAhUp:
		sub	ah, 'a'-'A'
		cmp	al, ah
		je	cont
		jmp	done
DomainNameCompare	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DomainNameUncompress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uncompresses a domain name in a response packet

CALLED BY:	RecordAddRR
PASS:		ds:si	= domain name
		ds:bx	= beginning of the response packet
		es	= buffer
RETURN:		ds:si	= byte right after the domain name
		es 	= buffer filled in with uncompressed name
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DomainNameUncompress	proc	near
		uses	ax,cx,dx,di
		.enter
		clr	di, dx
copyLabel:
		lodsb
		test	al, 11000000b
		jnz	compressed
		stosb
		clr	ah
		mov	cx, ax
		jcxz	fin
		rep movsb
		jmp	copyLabel
fin:
		tst	dx
		jz	done
		mov	si, dx
done:
		.leave
		ret
compressed:
		lodsb
		tst	dx
		jnz	cont
		mov	dx, si
cont:
		xchg	al, ah	; change it to little endian
		and	ah, 00111111b	; ax = offset from the start of the pkt
		mov	si, bx
		add	si, ax
		jmp	copyLabel
		
DomainNameUncompress	endp
ForceRef	DomainNameUncompress


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DomainNameInsertByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a byte at the beginning of domain name string passed
		in
CALLED BY:	ResolverEventQueryInfo
PASS:		*ds:si = domain name string
RETURN:		*ds:si = the same chunk with one byte inserted at the beginning
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DomainNameInsertByte	proc	near
		uses	ax,bx,cx
		.enter
		mov	ax, si			; *ds:ax <- chunk
		clr	bx			; bx <- insert at offset 0
		mov	cx, 1			; cx <- insert 1 byte
		call	LMemInsertAt
		.leave
		ret
DomainNameInsertByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToDomainName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a dotted form of domain name to standard domain name
		string used in DNS
CALLED BY:	Utility
PASS:		es:di	= domain name string with one extra byte at start
RETURN:		es:di	= standard DNS format domain name string
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertToDomainName	proc	near
		uses	cx,si,di
		.enter
		mov	si, di		; es:si = label length
labelLoop:
		clr	cl
		inc	di		; es:di = label
lenLoop:
		cmp	{byte}es:[di], 0
		je	lastLabel
		cmp	{byte}es:[di], '.'
		je	endLabel
		inc	cl
		inc	di
		jmp	lenLoop
endLabel:
		mov	{byte}es:[si], cl
		mov	si, di
		jmp	labelLoop
lastLabel:
		mov	{byte}es:[si], cl		
		.leave
		ret
ConvertToDomainName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefRequestNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference a RequestNode;
		It actually saves some space to make this a routine rather
		than a macro.
CALLED BY:	Utility
PASS:		bp	= chunk handle of RequestNode
		ResolverRequestBlock must be locked at this point
RETURN:		ds:si	= RequestNode pointed by bp
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefRequestNode	proc	near
		push	bx
		mov	bx, handle ResolverRequestBlock
		call	MemDerefDS
		mov	si, ds:[bp]
		pop	bx
		ret
DerefRequestNode	endp
ForceRef DerefRequestNode

; =============================================================================
;
; 			Cache related utilities
;
; =============================================================================

if ERROR_CHECK	; for swat

TraverseTree	proc	far
		uses	ax,bx,cx,dx,es,ds,di,si,bp
		.enter
		mov	bx, handle ResolverCacheBlock
		call	MemLock
		mov	ds, ax
		mov	bp, ds:CBH_root
		mov	si, ds:[bp]
		mov	di, si
		mov	bx, vseg TraverseCB
		mov	ax, offset TraverseCB
		call	TreeEnum
		mov	bx, handle ResolverCacheBlock
		call	MemUnlock
		.leave
		ret
TraverseTree	endp

ForceRef TraverseTree

TraverseCB	proc	far
		clc
		ret
TraverseCB	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheRRCloseCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete current node after saving its content into a file
		if file handle is given

CALLED BY:	TreeEnum
PASS:		ds:si = current node
		ds:*bp= same as ds:si
		ds:di = previous node
		dx    = file handle
		carry clr if we are on our way down the tree
		carry set if we are on our way up
			- we delete the node on our way up

RETURN:		carry clear
		ds:*bp= points to previous node passed in
			( unless ds:si was root )
		carry set if file error (out of disk space)

DESTROYED:	ax, bx, cx, dx, bp, di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheRRCloseCB	proc	far
		uses	dx
		.enter
	;
	; We save the nodes on the way down the tree, and delete nodes on the
	; way up.  In this way, the cache is saved in nice orderly manner, and
	; it is deleted from the bottom.
	;
		jc	deleteNode
	;
	; Save node
	;
		mov_tr	ax, dx			; ax = file handle
		tst	ax			; CF = 0
		jz	done
	;
	; Save node and ResourceRecord chain since we have a file handle
	;
		call	RecordSaveNodeToFile
		movdw	bxdx, ds:[si].RRN_resource
		call	RecordCloseOrSaveAll	; ax,bx,cx,dx destroyed
		jmp	done			; carry set if file error
deleteNode:
	;
	; Delete ResourceRecord chain( root might have this too )
	;
		clr	ax, bx, dx		; file handle = 0
		xchgdw	bxdx, ds:[si].RRN_resource
		call	RecordCloseOrSaveAll	; RR chain deleted
	;
	; If we are root, we don't remove the actual node
	;
		test	ds:[si].NC_flags, mask NF_ROOT ; CF = 0
		jnz	done			; don't delete anything at root
	;
	; Remove and deallocate node
	;
	; in order to make the TreeEnum continue visiting the
	; next node, we need to fool TreeEnum by setting up temp
	; node and jumping to it.  Now set up temp node.
	; -- this temp node chunk is already there.
	;
		push	di
		mov	di, ds:CBH_temp
		mov	di, ds:[di]
		segmov	ds:[di].NC_flags, ds:[si].NC_flags, ax
		segmov	ds:[di].NC_next, ds:[si].NC_next, ax
		pop	di
	;
	; ds:si/*bp = current node
	;
		call	TreeRemoveNode
		mov	ax, bp
		call	LMemFree		; free the chunk
	;
	; now jump to temp node
	;
		mov	bp, ds:CBH_temp
	;
	; Check if we had the correct cacheSize
	;
doneClr::
		clc
done:
		.leave
		ret
CacheRRCloseCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheRRUpdateCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all resource record cache entries below current TTL
		limit decrementing deleteCount until deleteCount reaches 0.
		Also delete all unnecessary ResourceRecordNodes that
		consistitute deleted cache entries.

CALLED BY:	TreeEnum by CacheDeallocateHalf
PASS:		ds:si		= current ResourceRecordNode
		ds:*bp		= same as ds:si
		ds:di		= prev node
		dx		= current TTL limit
		es		= dgroup
RETURN:		es:deleteCount	= decremented by number of RR deleted
		es:cacheSize	= decremented by number of RR deleted
		carry set if deleteCount reached zero
DESTROYED:	ax, bx, cx, di, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheRRUpdateCB	proc	far
		uses	dx
		.enter
	;
	; We don't do anything on the way down the tree since we haven't seen
	; our children yet
	;
		jnc	doneClr
chk1::
	;
	; skip root node
	;
		test	ds:[si].NC_flags, mask NF_ROOT ; CF = 0
		jnz	done
	;
	; If we have resource records, check for their TTLs
	;
		mov_tr	ax, dx
		movdw	bxdx, ds:[si].RRN_resource
		call	RecordDeleteOld	; bxdx= optr to remaining RR chain or 0
		movdw	ds:[si].RRN_resource, bxdx
		pushf				; preserve carry bit returned
						; by RecordDeleteOld
	;
	; If we don't have any records or children, delete current node
	;
		tst	bx			; any resource record?
		jnz	recoverCF
		test	ds:[si].NC_flags, mask NF_HAS_CHILD
		jnz	recoverCF
	;
	; We have neither a resource record nor a child node
	; Remove and deallocate node
	;
	; in order to make the TreeEnum continue visiting the
	; next node, we need to fool TreeEnum by setting up temp
	; node and jumping to it.  Now set up temp node.
	; -- this temp node chunk is already there.
	;
		push	di
		mov	di, ds:CBH_temp
		mov	di, ds:[di]
		segmov	ds:[di].NC_flags, ds:[si].NC_flags, ax
		segmov	ds:[di].NC_next, ds:[si].NC_next, ax
		pop	di
	;
	; ds:si/*bp = current node
	;
		call	TreeRemoveNode
		mov	ax, bp
		call	LMemFree		; free the chunk
	;
	; now jump to temp node
	;
		mov	bp, ds:CBH_temp
recoverCF:
		popf
done:
		.leave
		ret
doneClr:
		clc
		jmp	done
CacheRRUpdateCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdValidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate an ID

CALLED BY:	RequestAllocId
PASS:		dx	= word value to be used as an Id
RETURN:		carry set if Id is already in use
		carry clr if Id was validated correctly
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jang	9/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdValidate	proc	far
		uses	ax, cx, es
		.enter
		GetDgroup es, ax
		mov	cl, dl
		and	cx, CLIENT_COUNT_MASK
		mov	ax, 1
		shl	ax, cl
		test	es:validId, ax
		jnz	setC
		or	es:validId, ax
		clc
done:
		.leave
		ret
setC:
		stc
		jmp	done
IdValidate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate an Id

CALLED BY:	ResolverGetHostInfo
PASS:		dx	= a valid id
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jang	9/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdInvalidate	proc	far
		uses	ax, cx, es
		.enter
		GetDgroup es, ax
		mov	cl, dl
		and	cx, CLIENT_COUNT_MASK
		mov	ax, 1
		shl	ax, cl
EC <		test	es:validId, ax					>
EC <		ERROR_Z RFE_GENERAL_FAILURE				>
		xor	es:validId, ax
		.leave
		ret
IdInvalidate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if an Id is valid

CALLED BY:	ResolverEventQueryInfo
PASS:		dx	= Id
RETURN:		ZF set if not valid
		ZF not set if valid
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jang	9/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdCheck	proc	far
		uses	ax, cx, es
		.enter
		GetDgroup es, ax
		mov	cl, dl
		and	cx, CLIENT_COUNT_MASK
		mov	ax, 1
		shl	ax, cl
		test	es:validId, ax
		.leave
		ret
IdCheck	endp


ResolverActionCode	ends


;.............................................................................
;
;
; 			       RESOLVER EC CODE
;
;.............................................................................

if ERROR_CHECK

ResolverCommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckDomainAddressString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if domain name string passed in is a valid name

CALLED BY:	ResolverResolveAddress
PASS:		ds:si	= supposedly domain name string
		cx	= domain name string length
RETURN:		nothing
DESTROYED:	nothing

NOTE:
	I am making some strong assumptions to catch possible invalid
	parameters.  If this is a problem for certain situations, please
	disable this routine.

	Invalid addresses should return an error, not cause a fatal error.
	I can't make that change for Responder, however, so I will simply
	comment out the syntax checking for now.

RULES:
	All characters are alpha numeric
	Contains at least one dot

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckDomainAddressString	proc	far

if 1
		Assert_buffer	dssi, cx
else
		uses	ax, cx, dx, si
		.enter
	;
	; Check fptr
	;
		Assert_buffer	dssi, cx
		clr	dx
checkCharLoop:
		lodsb
	;
	; check special characters
	;
		cmp	al, '.'			; '.' is okay
		je	dot
		cmp	al, '-'
		je	next
		cmp	al, '_'
		je	next
	;
	; '0'-'9', 'A'-'Z', 'a'-'z' are okay
	;
		cmp	al, '0'			; '0'-'9' is okay
		ERROR_B	RFE_BAD_ARGUMENT
		cmp	al, '9'
		jbe	next
		cmp	al, 'A'			; 'A'-'Z' is okay
		ERROR_B	RFE_BAD_ARGUMENT
		cmp	al, 'Z'
		jbe	next
		cmp	al, 'a'			; 'a'-'z' is okay
		ERROR_B	RFE_BAD_ARGUMENT
		cmp	al, 'z'
		jbe	next
		ERROR	RFE_BAD_ARGUMENT
dot:
		inc	dx
next:
		loop	checkCharLoop
		tst	dx
		ERROR_Z	RFE_BAD_ARGUMENT	; string contains no dots
		.leave
endif
		ret
		
ECCheckDomainAddressString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckMovsbIntoChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make sure we are passing right movsb

CALLED BY:	INTERNAL
PASS:		bx	= chunk handle of destination
		es:di	= destination
		cx	= data size
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckMovsbIntoChunk	proc	far
		Assert_inChunk	di, bx, es
		dec	cx
		add	di, cx
		Assert_inChunk	di, bx, es
		sub	di, cx
		inc	cx
		ret
ECCheckMovsbIntoChunk	endp

ResolverCommonCode	ends

endif	; ERROR_CHECK
