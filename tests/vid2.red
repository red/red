Red [
	Needs: 'View
	Purpose: "Test layout alignment features"
]

view [
    size 1200x900
   	across top
   	button "ok" base red text "1" return

   	across middle
   	button "ok" base blue 650x250 text "2" return

   	across bottom
   	button "ok" base red text "3" return

   	below left
   	button "ok" base green text "4" 

   	across 
   	button "ok" base yellow 350x250 text "5"

    below center
   	button "ok" base green text "6" return

   	below right
   	button "ok" base green text "7" return
]