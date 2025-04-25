Red [
	Name: "Camera resizing test"
	Needs: 'View
	Purpose: "Test the behavior of camera widget on resizing, especially aspect ratio preservation."
]

view [
	size 500x500
	cam: camera select 1
	at cam/offset + cam/size 
	knob: base 10x10 orange loose on-drag [cam/size: knob/offset - cam/offset]
]