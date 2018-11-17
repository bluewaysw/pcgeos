
/**************************************************************************
 *
 *	File DebugInf.INC
 *
 *	Routinen zum Debugging
 *
 *	Diese Datei ist in eine Methoden-Datei, z.B. Process.goc,
 *	einzubinden
 *
 **************************************************************************/


#include <stdio.h>
#include <localize.h>


@extern object DebugText;
@extern object DebugValue1;
@extern object DebugValue2;
@extern object DebugValue3;
@extern object DebugInfoGlyph;


void DebugInfo (char *i ) {
	@call DebugText::MSG_VIS_TEXT_APPEND_PTR(i,0);
	}

void DebugInfoOptr( optr text) {
	@call DebugText::MSG_VIS_TEXT_APPEND_OPTR(text,0);
	}
void DebugInfo1 (char *i, int arg) {
char p[100];
	sprintf(p,i,arg);
	@call DebugText::MSG_VIS_TEXT_APPEND_PTR(p,0);
	}


void DebugShowText(char *t ) {
	@send DebugInfoGlyph::MSG_GEN_REPLACE_VIS_MONIKER_TEXT(t,VUM_NOW);
	}

void DebugShowValue1(int v) {
	@send DebugValue1::MSG_GEN_VALUE_SET_INTEGER_VALUE(v,FALSE);
	}

void DebugShowValue2(int v) {
	@send DebugValue2::MSG_GEN_VALUE_SET_INTEGER_VALUE(v,FALSE);
	}

void DebugShowValue3(int v) {
	@send DebugValue3::MSG_GEN_VALUE_SET_INTEGER_VALUE(v,FALSE);
	}



void MessageBox(char *txt) {
		UserStandardDialog ( (char *)0,(char *)0,(char *)0,(char *)0,txt,
		(( CDT_NOTIFICATION << CDBF_DIALOG_TYPE_OFFSET) |
		 ( GIT_NOTIFICATION << CDBF_INTERACTION_TYPE_OFFSET)) );
		 }

void MessageNumberBox(word number) {
		char txt[10];
		LocalFixedToAscii(txt,MakeWWFixed(number),0);
		UserStandardDialog ( (char *)0,(char *)0,(char *)0,(char *)0,txt,
		(( CDT_NOTIFICATION << CDBF_DIALOG_TYPE_OFFSET) |
		 ( GIT_NOTIFICATION << CDBF_INTERACTION_TYPE_OFFSET)) );
		 }


