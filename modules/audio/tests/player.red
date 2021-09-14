Red [
	Needs: [view audio]
]

view [
	title "Audio Player"
	txt: text 200 center "Open a WAV file" return
	button "Open" [if f: request-file/filter ["wav"] [txt/text: to string! last split-path f]]
	button "Play" [if f [unless p [p: open audio://] insert p load f]]
	button "Stop" [if p [close p p: none]]
]