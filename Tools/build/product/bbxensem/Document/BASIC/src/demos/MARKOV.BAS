sub duplo_ui_ui_ui()
 REM	Copyright (c) Geoworks 1995 -- All Rights Reserved
 REM	FILE:		STDINC.BH

 STRUCT TimeOfDay
  DIM hour as integer
  DIM minute as integer
  DIM second as integer
 END STRUCT

 STRUCT Date
  DIM year as integer
  DIM month as integer
  DIM day as integer
 END STRUCT

 STRUCT Notification
  DIM arg1 as integer
  DIM arg2 as integer
  DIM arg3 as integer
  DIM arg4 as integer
  DIM arg5 as string
  DIM arg6 as complex
 END STRUCT

 REM end of stdinc.bh

dim mytop as form
mytop = MakeComponent("form", "app")
mytop.proto = "mytop"
mytop.name = "mytop"

dim make_sentence as button
make_sentence = MakeComponent("button", mytop)
make_sentence.name = "make_sentence"
make_sentence.caption = "make_sentence"
make_sentence.left = 20
make_sentence.top = 20
make_sentence.visible = 1
make_sentence.proto = "make_sentence"

DIM result as text
result = MakeComponent("text", mytop)
result.name = "result"
result.left = 20
result.top = 40
result.width = 300
result.height = 300
result.visible = 1

duplo_start()
end sub

sub module_show()
    mytop.visible = 1
end sub

sub module_hide()
    mytop.visible = 0
end sub


sub duplo_start()

dim bigstring1 as string
dim bigstring2 as string
dim bigstring3 as string
dim bigstring4 as string
dim bigstring5 as string

bigstring1 = "What's her name? Mia. How did Marsellus and her meet? I dunno, however people meet people. She usta be an actress. She ever do anything I woulda saw? I think her biggest deal was she starred in a pilot. What's a pilot? Well, you know the shows on TV? I don't watch TV. Yes, but you are aware that there's an invention called television, and on that invention they show shows? Yeah. Well, the way they pick the shows on TV is they make one show, and that show is called a pilot. And they show that one show to the people who pick the shows, and on the strength on that one show, they decide if they want to make more shows. Some get accepted and become TV programs. And some don't and become nothing. She starred in one of the ones that became nothing."


bigstring2 = "I am pleased to announce that starting September 1, 1994 Geoworks will offer Domestic Partner for family and bereavement leaves.  Current family leave policy allows for up to 12 weeks of unpaid leave to care for a spouse, child, parent, and now domestic partner, who has a serious health condition.  Bereavement leave entitles eligible employees to three days of paid leave. Due to insurance restrictions, domestic partners are not eligible for medical/dental benifits at this time. You and your domestic partner are in a commited relationship of mutual caring which has existed for at least one year prior to enrollment of your domestic partner."

bigstring3 = "19th century martial arts master Wong fei-hung (Jet Li) and his followers defend their province from the evil soho mob and devilish Western traders in an exhilaratingly entertaining martial arts historical epic laced with wit and comedy."


bigstring4 = "Johnny Heartsman is the personification of the Oakland blues tradition. Listeners, especially those previously unfamiliar with West Coast blues in general and Oakland blues in particular, will find in Heartsman's Alligator debut a refreshingly different take on the blues. Produced by long time Heartsman booster Dick Shurman, it presents Johnny Heartsman -- guitarist, bassist, pianist, organist, flutist, songwriter, arranger, and vocalist -- a complete musician with a compellingly original touch."

bigstring5 = "A few paces from the corporate headquarters of Sapporo Breweries Ltd., in an expansive new commercial and residential development southwest of Tokyo, a simple stone footpath leads to a spot of garden greenery that shelters a perfect little Shinto shrine, no bigger than a child's playhouse and intricately, meticulously constructed of gleaming blond cypress wood."


CONST MAX_STRINGS 200, MAX_FOLLOWS 20

REM dim an array for all the words we know about 
dim words[MAX_STRINGS * 2]                  as string

dim num_words as integer
num_words = 0

REM dim a two dimensioan array of pointers to following words
dim follows1[MAX_STRINGS, MAX_FOLLOWS]   as integer
dim follows2[MAX_STRINGS, MAX_FOLLOWS]   as integer
dim num_follows1[MAX_STRINGS]            as integer
dim num_follows2[MAX_STRINGS]            as integer




dim NUM_LABELS as integer
NUM_LABELS = 10

dim first_word as integer
first_word = 1
dim first_word_table[MAX_STRINGS * 2] as integer


parse_stuff()

end sub

function duplo_revision()

REM     Copyright (c) Geoworks 1994 
REM                    -- All Rights Reserved
REM
REM     FILE:   markov.bas
REM     AUTHOR: Jimmy Lefkowitz, Nov  7, 1994
REM     jimmy
REM     $Revision:   1.1  $
REM

end function

function add_word(newword as string) as integer
REM ********************************************
REM             add_word
REM ********************************************
REM
REM  SYNOPSIS:   add a word to the global list
REM     
REM  CALLED BY:  global
REM  PASS:       new word string
REM  RETURN:
REM
REM  REVISION HISTORY
REM   Name      Date            Description
REM   ----      ----            -----------
REM   jimmy     11/11/94        Initial Version
REM
REM *********************************************

dim i as integer

i = 0
do while i < MAX_STRINGS*2 and words[i] <> "" and words[i] <> newword 
	i = i + 1
loop
 
if i < MAX_STRINGS*2 then
   if first_word = 1 then
      first_word_table[i] = 1
      first_word = 0
   end if

  if words[i] = "" then
    words[i] = newword
    num_words = num_words + 1
  end if

  if is_end_char(right(newword, 1)) <> 0 then
     first_word = 1
  end if

end if

add_word = i

end function

function use_default_values() as integer
REM ********************************************
REM             use_default_values
REM ********************************************
REM
REM  SYNOPSIS:       load up default values
REM     
REM  CALLED BY:      global
REM  PASS:
REM  RETURN:
REM
REM  REVISION HISTORY
REM   Name      Date            Description
REM   ----      ----            -----------
REM   jimmy     11/11/94        Initial Version
REM
REM *********************************************


REM for now we have 13 sample strings to read from


   use_default_values = 0
end function

sub parse_string(s as string)
REM ********************************************
REM             parse_string
REM ********************************************
REM
REM  SYNOPSIS:   parse a string into the tables
REM     
REM  CALLED BY: global
REM  PASS:      a string
REM  RETURN:    strings data parsed into tables
REM
REM  REVISION HISTORY
REM   Name      Date            Description
REM   ----      ----            -----------
REM   jimmy     11/14/94        Initial Version
REM
REM ********************************************

    dim s2[2] as string
    dim last_word as integer
    dim next_word as string

    last_word = -1
    do while s <> ""
	s2[0] = s
REM get_next_word will return the rest of the string in s2[1]
	next_word = get_next_word(s2)
	last_word = enter_word(next_word, last_word)
	s = s2[1]
    loop

end sub

function get_next_word(s2[] as string) as string
REM ********************************************
REM             get_next_word
REM ********************************************
REM
REM  SYNOPSIS:  parse of the next word
REM     
REM  CALLED BY: parse_string
REM  PASS:      string
REM  RETURN:    next word from string
REM
REM  REVISION HISTORY
REM   Name      Date            Description
REM   ----      ----            -----------
REM   jimmy     11/14/94        Initial Version
REM
REM ********************************************

    dim i as integer
    dim s as string
    dim temp as string

    s = s2[0]
    i = 1
    get_next_word = ""
    do
	temp = mid(s, i, 1)
	select case temp
      case ""
	 get_next_word = s
	 s2[1] = ""
REM space is end of word
	    case " "
	 if i <> 1 then
		    get_next_word = left(s, i-1)
		    s2[1] = right(s, len(s)-i)
   else
	     s = right(s, len(s)-1)
	     i = 0
	end if
REM a word can also end with the following punctuation
	    case ".", "?", "!", ","
		get_next_word = left(s, i)
		s2[1] = right(s, len(s) - i)
	end select
   i = i + 1
   loop until get_next_word <> ""

      
end function

function enter_word(word as string, last_word as integer) as integer
REM ********************************************
REM             enter_word
REM ********************************************
REM
REM  SYNOPSIS:  set up all the revelant data for a new word
REM     
REM  CALLED BY:
REM  PASS:      word is the new word
REM             last_word is an index to the last word entered in the
REM             global array
REM  RETURN:
REM
REM  REVISION HISTORY
REM   Name      Date            Description
REM   ----      ----            -----------
REM   jimmy     11/14/94        Initial Version
REM
REM ********************************************

REM put the new word in the table
    enter_word = add_word(word)
    dim lw as string
    dim lwm as integer, lwd as integer

    if last_word <> -1 then
	lw = words[last_word]
	lwm = last_word MOD MAX_STRINGS
	lwd = last_word / MAX_STRINGS
	select case lwd
	case 0
		if num_follows1[last_word] < MAX_FOLLOWS  then
		    follows1[lwm, num_follows1[lwm]] = enter_word
		    num_follows1[lwm] = num_follows1[lwm] + 1     
		else
			debug
		end if
	case 1
		if num_follows2[lwm] < MAX_FOLLOWS  then
		    follows2[lwm, num_follows2[lwm]] = enter_word
		    num_follows2[lwm] = num_follows2[lwm] + 1     
		else
			debug
		end if
	case else
		debug
	end select
    end if
	
end function

sub make_sentence_pressed(self as component)
REM ********************************************
REM             make_sentence_pressed
REM ********************************************
REM
REM  SYNOPSIS:           create a sentence
REM      
REM  CALLED BY:          global
REM  PASS:               nothing interesting
REM  RETURN:
REM
REM  REVISION HISTORY
REM   Name      Date            Description
REM   ----      ----            -----------
REM   jimmy     11/11/94        Initial Version
REM
REM *********************************************

dim new_sent as string
dim n as integer
dim last_word as string
dim i as integer, j as integer
dim l as integer
dim ch as string
dim sent as string

if num_words > 0 then

 new_sent = ""
 do
    sent = ""
    do 
       n = num_words * RND() + .5
       if first_word_table[n] = 1 then
REM       if 1 then
	   sent = words[n]
	   exit do
      end if
    loop

    last_word = sent
    do while is_end_char(right(sent, 1)) = 0 and last_word <> ""
       last_word = extend_sentence(sent, last_word)
       sent = sent + " " + last_word
    loop

    new_sent = new_sent + " " + sent
    if (len(new_sent) > 500) then
	if (len(new_sent) > 750) then
		new_sent = left(new_sent, 750)
	end if
	exit do
    end if
 loop

    sent = new_sent
	result.text = ""
    result.AppendString(sent)
end if
end sub

function is_end_char(s as string) as integer
    select case s
	  case ".", "!", "?"
	     is_end_char = 1
	  case else
	     is_end_char = 0
    end select
end function

function extend_sentence(sentence as string, last_word as string) as string
dim n as integer, nd as integer, nm as integer

    n = add_word(last_word)
    nd = n / MAX_STRINGS
    nm = n MOD MAX_STRINGS
    dim num as integer

    select case nd
	case 0  
		if num_follows1[nm] = 0 then
			extend_sentence = ""
		else
			num = num_follows1[nm] * RND()
			extend_sentence = words[follows1[nm, num]]
		end if
	case 1  
		if num_follows2[nm] = 0 then
			extend_sentence = ""
		else
			num = num_follows2[nm] * RND()
			extend_sentence = words[follows2[nm, num]]
		end if
	case else
		debug
	end select

end function


sub parse_stuff()
   result.text = "Parsing input text, please twiddle your thumbs for a few moments...Starting with "
   Update()
   result.AppendString(bigstring1)
   parse_string(bigstring1)
result.text = "Now parsing..."
result.AppendString(bigstring2)
Update()
   parse_string(bigstring2)
result.text = "Now parsing..."
result.AppendString(bigstring3)
Update()
   parse_string(bigstring3)
result.text = "Now parsing..."
result.AppendString(bigstring4)
Update()
   parse_string(bigstring4)
result.text = "Now parsing..."
result.AppendString(bigstring5)
Update()
   parse_string(bigstring5)
   result.text = "Done! For my next trick..."

end sub

