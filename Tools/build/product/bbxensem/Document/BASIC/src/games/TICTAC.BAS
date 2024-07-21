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

Dim mainform as form
mainform = MakeComponent("form","app")
CompInit mainform
name="mainform"
caption="Tic Tac"
proto="mainform"
left=97
top=97
width=150
height=210
End CompInit
Dim message1 as label
message1 = MakeComponent("label",mainform)
CompInit message1
name="message1"
proto="label1"
caption="You use X's"
left=10
top=36
visible=1
End CompInit
Dim message2 as label
message2 = MakeComponent("label",mainform)
CompInit message2
name="message2"
proto="label2"
caption="You can go first."
left=10
top=54
visible=1
End CompInit
Dim row1 as group
row1 = MakeComponent("group",mainform)
CompInit row1
name="row1"
proto="group1"
caption=""
left=30
top=80
height=30
width=90
look=2
tile=1
tileLayout=1
tileSpacing=5
visible=1
End CompInit
Dim row2 as group
row2 = MakeComponent("group",mainform)
CompInit row2
name="row2"
proto="group2"
caption=""
left=30
top=111
height=30
width=90
look=2
tile=1
tileLayout=1
tileSpacing=5
visible=1
End CompInit
Dim row3 as group
row3 = MakeComponent("group",mainform)
CompInit row3
name="row3"
proto="group3"
caption=""
left=30
top=142
height=30
width=90
look=2
tile=1
tileLayout=1
tileSpacing=5
visible=1
End CompInit
Dim newGame as button
newGame = MakeComponent("button",mainform)
CompInit newGame
name="newGame"
proto="newGame"
caption="New game"
left=10
top=9
visible=1
End CompInit
duplo_start()
end sub

sub module_show()
    mainform.visible=1
end sub

sub module_hide()
    mainform.visible=0
end sub

sub duplo_start()
REM     Copyright (c) Geoworks 1994 
REM                    -- All Rights Reserved
REM
REM     FILE:   tictac.bas
REM     AUTHOR: Roy Goldman, Nov 14, 1994
REM     DESCRIPTION:
REM             Tic Tac Toe! against the computer
REM     roy
REM     $Revision:   1.0  $
REM

dim board[9] as integer

REM Indeces of board correspond conceptually
REM as follows:
REM
REM 0 1 2
REM 3 4 5
REM 6 7 8


REM When the game is done this turns to 1 and that game ends
dim done as integer
done = 0

REM Each board position can be EMPTY, XMARKER, or OMARKER
REM Three "constants" (for now just regular variables)...
REM Make OMARKER > 3 * XMARKER to make checking for winners
REM easier.  I also use these constants for reporting
REM who the winner is (EMPTY means no one, XMARKER means
REM X wins, OMARKER means O wins)

dim EMPTY   as integer
dim XMARKER as integer
dim OMARKER as integer

EMPTY = 0       
XMARKER = 1
OMARKER = 10

REM User is always X, computer is always O.
REM User always goes first.

REM Keep track of the number of plays per game.
REM We know we have a tie when we play 9 and there
REM are no winners. This will get cleared in the
REM reset function.

dim plays as integer

REM Create a 3 x 3 grid of triggers, this is our board
REM Put them in an array which maps directly to the board
REM array above. Each trigger's moniker can be 
REM a space, an X, or an O.

dim ui[9] as button
dim i as integer

for i = 0 to 2
	ui[i]   = MakeComponent("button",row1)
next i

for i = 0 to 2
	ui[i+3] = MakeComponent("button",row2)
next i

for i = 0 to 2
	ui[i+6] = MakeComponent("button",row3)
next i

REM One time initialization to UI position objects

for i = 0 to 8
   ui[i].visible = 1

   REM These two lines tell this component
   REM to call handlers beginning with
   REM the name uiGeneric, passing in index
   REM as the parameter.  This allows us
   REM to use one routine to handle clicks
   REM from all nine triggers

   ui[i].proto = "uiGeneric"
   ui[i].index = i
next i

REM Clear the board, both in memory and visually
REM by setting the monikers to spaces and setting
REM board elements to EMPTY.

reset()

end sub

sub reset()

REM This function resets the board in memory
REM and visually.
   dim i as integer


   for i = 0 to 8       
      board[i] = EMPTY
      ui[i].caption = " "
   next i

   plays = 0

end sub

sub uiGeneric_pressed(self as button)

   REM This function gets called every time
   REM the user clicks on a game board position.

   REM Only process event if game isn't done
   REM and position under mouse is empty
   
   dim index as integer
   dim choice as integer

   index = self.index

   if board[index] = EMPTY and done = 0 then

      plays = plays + 1

      board[index] = XMARKER
      ui[index].caption = "X"

      REM Did the user win?

      if checkForWinner() = XMARKER then
	 message1.caption = "You win!"
	 message2.caption = "What a star!"
	 done = 1
      else
	 if tieGame() then
	    message1.caption = "Tie!"
	    message2.caption = "Weak..."         
	    done = 1
	 else
	    REM Now the computer goes

	    choice = computerTurn()

	    board[choice] = OMARKER
	    ui[choice].caption = "O"
	    plays = plays + 1

	    REM Does the computer win!?

	    if checkForWinner() = OMARKER then
	       message1.caption = "I win!!"
	       message2.caption = "Give up yet?"
	       done = 1
	    else
	       if tieGame() then
		  message1.caption = "Tie!"
		  message2.caption = "Need help?"
		  done = 1
	       else
		  message1.caption = "Your turn..."
		  message2.caption = ""
	       end if
	    end if    
	 end if
      end if
   end if

end sub

function tieGame() as integer

   REM Very brain dead right now...

   if plays = 9 then
      tieGame = 1
   else
      tieGame = 0
   end if

end function

function checkForWinner() as integer

   REM Checks to see if there is a winner.
   REM Returns EMPTY for none, else XMARKER or OMARKER

   dim count  as integer
   dim count1 as integer
   dim count2 as integer

   checkForWinner = EMPTY

   if plays >= 5 then 
      REM Check horizontal win 

      for i = 0 to 6 step 3
		
	 count = board[i] + board[i+1] + board[i+2]
	 if count = 3 * XMARKER then
	     checkForWinner = XMARKER
	     REM No More Looping
	     i = 7
	 end if
	
	 if count = 3 * OMARKER then
	    checkForWinner = OMARKER
	    i=7
	 end if
      next i
 
      REM Check vertical win if no horizontal winner

      if checkForWinner = EMPTY then
		
	 for i = 0 to 2
	
	    count = board[i] + board[i+3] + board[i+6]

	    if count = 3 * XMARKER then
	       checkForWinner = XMARKER
	       REM No more looping
	       i = 3
	    end if
			
	    if count = 3 * OMARKER then
	       checkForWinner = OMARKER
	       i = 3
	    end if
	 next i
      end if

      REM Check diagonal wins if no horizontal or vertical winner

      if checkForWinner = EMPTY then

	 count1 = board[0] + board[4] + board[8]
	 count2 = board[2] + board[4] + board[6]

	 if (count1 = 3 * XMARKER) OR (count2 = 3 * XMARKER) then
	    checkForWinner = XMARKER
	 else 
	    if (count1 = 3 * OMARKER) or (count2 = 3 * OMARKER) then
	       checkForWinner = OMARKER
	    end if
	 end if
      end if
   end if

end function

function computerTurn() as integer
   REM This is where our fantastic strategy is embedded.
   REM Returns an index from 0-8 corresponding to the
   REM computer's choice.

   REM We assume there is at least one empty spot on the board

   dim count as integer
   computerTurn = -1

   REM Plays the same first move most of the time

   dim x as integer
   dim i as integer
   dim j as integer

   x = 4 * rnd() + .5

   if plays = 1 and x > 0 then
      REM Block some strategies which are based on the first move.
      
      REM If user chose middle square, choose a corner.
      if board[4] = XMARKER then
		computerTurn = 0
      else
		REM Otherwise, choose the middle
		computerTurn = 4
      end if
   end if


   if plays >= 3 then
      
      REM This part of the strategy will make sure we win with the
      REM next move if it's possible and it will block a forthcoming
      REM victory if possible.
      REM
      REM Don't bother unless user has already laid down 2 markers

      REM Build a 2D array. First index is 0-8, corresponding
      REM to board positions.  Second index is 0,1,2,3 marking
      REM the at most four different victories which
      REM could involve that spot: horizontal, vertical, and
      REM 0,1, or 2 diagonals depending on spot.
      REM Sum up the values of the different spots which
      REM could mean victory or defeat for each orientation.
      REM (initially all entries are 0)

      dim spot[9,4] as integer

      for i = 0 to 8
		for j = 0 to 3
		spot[i,j] = EMPTY
		next j
      next i

      REM  0=1=2
      REM  3=4==
      REM  6===8

      if board[0] = EMPTY then
		spot[0,0] = board[1] + board[2]
		spot[0,1] = board[3] + board[6]
		spot[0,2] = board[4] + board[8]
      end if

      REM  0=1=2
      REM  ==4==
      REM  ==7==

      if board[1] = EMPTY then
		spot[1,0] = board[0] + board[2]
		spot[1,1] = board[4] + board[7]
		REM No diagonal
      end if

      REM  0=1=2
      REM  ==4=5
      REM  6===8

      if board[2] = EMPTY then
		spot[2,0] = board[0] + board[1]
		spot[2,1] = board[5] + board[8]
		spot[2,2] = board[4] + board[6]
      end if

      REM  0====
      REM  3=4=5
      REM  6====

      if board[3] = EMPTY then
		spot[3,0] = board[4] + board[5]
		spot[3,1] = board[0] + board[6]
		REM No diagonal
      end if

      REM  0=1=2
      REM  3=4=5
      REM  6=7=8

      if board[4] = EMPTY then
		spot[4,0] = board[3] + board[5]
		spot[4,1] = board[1] + board[7]
		spot[4,2] = board[0] + board[8]
		spot[4,3] = board[2] + board[6]
      end if

      REM  ====2
      REM  3=4=5
      REM  ====8

      if board[5] = EMPTY then
		spot[5,0] = board[3] + board[4]
		spot[5,1] = board[2] + board[8]
		REM No Diagonal
      end if

      REM  0===2
      REM  3=4==
      REM  6=7=8

      if board[6] = EMPTY then
		spot[6,0] = board[7] + board[8]
		spot[6,1] = board[0] + board[3]
		spot[6,2] = board[4] + board[2]
      end if

      REM  ==1==
      REM  ==4==
      REM  6=7=8

      if board[7] = EMPTY then
		spot[7,0] = board[6] + board[8]
		spot[7,1] = board[1] + board[4]
      end if

      REM  0===2
      REM  ==4=5
      REM  6=7=8

      if board[8] = EMPTY then
		spot[8,0] = board[6] + board[7]
		spot[8,1] = board[2] + board[5]
		spot[8,2] = board[0] + board[4]
      end if

      REM Do a pass to try to win...

      if plays >= 4 then
		REM We've already played at least two, have a chance...

		for i = 0 to 8
		for j = 0 to 3
			if spot[i,j] = 2 * OMARKER then
					computerTurn = i
					j = 4
					i = 9
			end if
		next j
		next i
      end if

      REM If we couldn't win, at least block any potential 
      REM opponent victories...

      if computerTurn = -1 then
		for i = 0 to 8
		for j = 0 to 3
			if spot[i,j] = 2 * XMARKER then
					computerTurn = i
					j = 4
					i = 9
			end if
		next j
		next i
      end if

   end if

   if computerTurn = -1 then

      REM If there is no winning or blocking move, just choose one randomly
      REM See how many empty slots there are and then pick one randomly!
      REM A BRILLIANT strategy!

	  dim temp[9] as integer

      count = 0

	  for i = 0 to 8
		if board[i] = EMPTY then
		temp[count] = i
		count = count + 1
		end if
      next i
	
      count = count - 1
	  i = count * rnd() + .5
      computerTurn = temp[i]
   end if
end function

sub newGame_pressed(self as button)
   REM Called when the user clicks on the New Game button
   reset()
   done = 0
   message1.caption = "X goes first"
   message2.caption = ""  
end sub

