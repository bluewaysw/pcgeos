/*
	Make Extern - Create @extern - statements for objects and chunks
	Process .goc file and create corresponding .goh file
*/
#include <stdio.h>
#include <string.h>

#include <conio.h>
//include <windows.h>

/*
	Constants and Prototypes
*/
#define LINE_BUFFER_SIZE 256
#define FALSE	0
#define TRUE (-1)
#define IDENTIFIER_MAX_LEN 64

void PrintUsage(void);
void PrintCopyright(void);
void ProcessFile(FILE *fh, FILE *destf);
void ProcessLine(char *buff, FILE *destf);
void TabsToSpaces(char *buf);
char *CopyIdentifier(char *src, char *dest);
int OpenFiles(char *name, FILE **srcFh, FILE **destFh);


int numChunks = 0;
int numMonikers = 0;
int numObjects = 0;
int numArrays = 0;
int numGStrings = 0;

/*++++++++++++++++++++++++++++++++++++++++++++++++
	Main-Routine - check passed filenames and call ProcessFile() routine
  ++++++++++++++++++++++++++++++++++++++++++++++++*/

int main(int numArgs, char ** args)
{
int n, err;
char fName[LINE_BUFFER_SIZE];

	if (numArgs < 2)
	{
		PrintCopyright();
		PrintUsage();
		return 0;
	}

	PrintCopyright();
	for ( n = 1; n< numArgs; n++ )
	{
	FILE *fh, *destf;
		strcpy(fName, args[n]);
		err = OpenFiles(fName, &fh, &destf);

		if (err)
		{
			continue;
		}
		else
		{
			printf("Processing file ");
			printf(fName);
			printf(" ...\n");
			ProcessFile(fh, destf);
			fclose(fh);
			fclose(destf);
		}
	}


	return 0;
}

/*++++++++++++++++++++++++++++++++++++++++++++++++
	Common tool routines
  ++++++++++++++++++++++++++++++++++++++++++++++++*/

// -------------------------------
// 			PrintUsage
// -------------------------------
void PrintUsage(void)
{
//	printf("\x1b[31m");
	printf("* mkext scans the files passed to it for object and data chunks and generates the corresponding .goh files containing the @extern statements\n");
	printf("Usage: mkext <files>\nDefault extension: goc\n");
	printf("\nExamlpe: MakeExt libui\nCreates libui.goh from libui.goc\n");
}

// -------------------------------
// 			PrintCopyright
// -------------------------------
void PrintCopyright(void)
{
/*
HANDLE hConsole;
	CONSOLE_SCREEN_BUFFER_INFO csbiScreen;
	WORD wOldColAttr;


hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
	GetConsoleScreenBufferInfo(hConsole, &csbiScreen);
	wOldColAttr = csbiScreen.wAttributes;

SetConsoleTextAttribute(hConsole, 14); // 14 = Beliebige Zahl von 1-255 Z.B. 15 = Weiss
//system("color 73");
printf("BlaBla\n");
printf("\x1b[31m");


//	textcolor(RED);
*/
	printf("* @extern statements creation tool by RABE-Soft for freeGEOS, Rainer Bettsteller, 2022-2026 *\n");
	// Alte Text-Farbe wiederherstellen
//	SetConsoleTextAttribute(hConsole, wOldColAttr);

}

/*
#include <iostream>

#include <windows.h>

int main()
{
	HANDLE hStdOut;
	CONSOLE_SCREEN_BUFFER_INFO csbiScreen;
	WORD wOldColAttr;

	// HANDLE für stdout (Anm.: Error-Checking wäre hier angebracht)
	hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);

	// Alte Textfarbe abspeichern
	GetConsoleScreenBufferInfo(hStdOut, &csbiScreen);
	wOldColAttr = csbiScreen.wAttributes;

	// Text-Farbe auf blau & "leuchtend" setzen
	SetConsoleTextAttribute(hStdOut, FOREGROUND_BLUE | FOREGROUND_INTENSITY);

	// Hier kann nun per WinAPI (WriteFile(), ReadFile(), WriteConsole(), ReadConsole())
	// oder per "Standard"-Methoden gearbeitet werden.
	std::cout << "Es ist blau!!" << std::endl;

	// Alte Text-Farbe wiederherstellen
	SetConsoleTextAttribute(hStdOut, wOldColAttr);

	return 0;
}
*/


// -------------------------------
// 			OpenFiles
// -------------------------------
int OpenFiles(char *name, FILE **srcFh, FILE **destFh)
{
char destName[IDENTIFIER_MAX_LEN], *p;

	// Construct file names
	if (strchr(name, '.') == NULL ) strcat(name, ".goc");
	strcpy(destName, name);
	p = strchr(destName, '.');
	p++;
	strcpy(p, "goh");

	// Open source file
	*srcFh = fopen(name, "r");
	if (*srcFh == NULL)
	{
		printf("+++ Error opening file ");
		printf(name);printf(" +++\n");
		return TRUE;
	}

	// Open destination file
	*destFh = fopen(destName, "w");
	if (*destFh == NULL)
	{
		printf("+++ Error creating file ");
		printf(destName);printf(" +++\n");
		fclose(*srcFh);
		return TRUE;
	}

	return FALSE;
}

/*++++++++++++++++++++++++++++++++++++++++++++++++
	File processing tool routines
  ++++++++++++++++++++++++++++++++++++++++++++++++*/

// -------------------------------
// 			FileReadLine
// return TRUE if only EOF was found
// -------------------------------
int FileReadLine(FILE *fh, char *buff)
{
char c;
int n;

	// Read up to LINE_BUFFER_SIZE (256) characters from a file
	*buff = 0;

	// skip initial line feed characters, tabs and spaces if any
	c = fgetc(fh);
	while ( (c == 0x0D) || (c == 0x0A) || (c == ' ') || (c == '\t') ) { /*printf("\r >>skip");*/ c = fgetc(fh); } /// µµ
	if ( c==EOF ) { /*printf("\r <<EOF>>");*/ return TRUE; } /// µµ


	// Copy line to buffer. Count characters
	n = 0;
	while ( (c!=0x0A) && (c!=0x0D) && (c!=EOF) )
	{
		buff[n] = c;
		n++;
		c = fgetc(fh);
		if (n==(LINE_BUFFER_SIZE-1)) break;
	}

	buff[n] = 0;

/*
printf("\r->");
printf(buff);
printf("<-");
*/
	return FALSE;

}

// -------------------------------
// 			TabsToSpaces
// -------------------------------
void TabsToSpaces(char *buf)
{
char *p;

	p = strchr(buf, '\t');
	while (p)
	{
		*p = ' ';
		p++;
		p= strchr(p, '\t');
	}

}


// -------------------------------
// 			IsCharValid
// return TRUE, if c is an valid character for an identifier
// -------------------------------
int IsCharValid(char c)
{

	// Valid charaters are
	// '0' .. '9', 'A' ... 'Z', 'a' .. 'z', '_'
	if ( (c>='0') && (c<='9') ) return TRUE;
	if ( (c>='A') && (c<='Z') ) return TRUE;
	if ( (c>='a') && (c<='z') ) return TRUE;

	if ( (c=='_') ) return TRUE;

	return FALSE;
}

// -------------------------------
// 			CopyIdentifier
// -------------------------------
char *CopyIdentifier(char *src, char *dest)
{
int n;
char c;

	// skip spaces
	while (*src == ' ') src++;

	// Copy Identifier
	n = 0;
	c = *src;
	while (IsCharValid(c))
	{
		*dest = *src;
		src++;
		dest++;
		c = *src;

		n++;
		if (n > IDENTIFIER_MAX_LEN) break;
	}

	*dest = 0;

	// return: pointer to first invalid char
	return src;

}


/*++++++++++++++++++++++++++++++++++++++++++++++++
	Process GOC file
  ++++++++++++++++++++++++++++++++++++++++++++++++*/

// -------------------------------
// 			ProcessFile
// -------------------------------
void ProcessFile(FILE *fh, FILE *destf)
{
int cnt, done = FALSE;
char buff[LINE_BUFFER_SIZE];

	while ( TRUE )
	{
		done = FileReadLine(fh, buff);
		if (done) {
			/*printf(" +++++++ done");*/break;	// µµ
		}

		// if first character is a '@', the line is of interrest
		if (buff[0] == '@')
		{
			TabsToSpaces(buff);
			ProcessLine(buff, destf);
		}
	}

	cnt = numChunks + numMonikers + numObjects + numArrays + numGStrings;
	if ( cnt )
	{
		printf("   %u chunks exported\n", numChunks);
		printf("   %u objects exported\n", numObjects);
		printf("   %u visMonikers exported\n", numMonikers);
		if ( numArrays ) printf("   %u arrays exported\n", numArrays);
		if ( numGStrings ) printf("   %u gstrings exported\n", numGStrings);
	}
	else
	{
		printf("No chunks found to export\n");
	}
}

// -------------------------------
// 			ProcessLine
// -------------------------------
void ProcessLine(char *buff, FILE *destf)
{
char chunkText[IDENTIFIER_MAX_LEN+2],
	typeText[IDENTIFIER_MAX_LEN+2],
	identifierText[IDENTIFIER_MAX_LEN+2];
char *txt;

	// Structure if line contains an exportable object
	// @chunk dataType identifier = ...
	// @chunk dataType identifier[] = ...
	// @visMoniker monikerName = ...

	// Copy Identifiers, skip the '@' char at start of line
	txt = CopyIdentifier(buff+1, chunkText);
	txt = CopyIdentifier(txt, typeText);
	CopyIdentifier(txt, identifierText);

	// depending on the chunkText, write output
	// if txt is still zero, no output has to be written
	txt = 0;
	if (strcmp(chunkText, "chunk") == 0) { txt = identifierText; numChunks++; }
	if (strcmp(chunkText, "chunkArray") == 0) { txt = identifierText; numArrays++; };
	if (strcmp(chunkText, "object") == 0) { txt = identifierText;; numObjects++; }
	if (strcmp(chunkText, "visMoniker") == 0) { txt = typeText;; numMonikers++; }
	if (strcmp(chunkText, "elementArray") == 0) { txt = identifierText;; numArrays++; }
	if (strcmp(chunkText, "gstring") == 0) { txt = typeText; ; numGStrings++; }

	if ( txt )
	{
		fprintf(destf, "@extern ");
		fprintf(destf, chunkText);
		fprintf(destf, " ");
		fprintf(destf, txt);
		fprintf(destf, ";\n");
	}

}
