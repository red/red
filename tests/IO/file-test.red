Red [
    title: "Basic TCP test client"
]

do [

recycle/off

;debug: :print
debug: :comment

file-port: open file:///E/temp/movies/aabb.rmvb

len: 0.0
start: now/precise

file-port/awake: func [event /local port] [
    debug ["=== Client event:" event/type]
    port: event/port
    switch event/type [
        connect [copy port]
        read [
	        ;probe port/data/1
	        len: len + length? port/data
	        if (length? port/data) < 65536 [
		        ?? len
		        close port
		        return false
	        ]
            copy port
        ]
        wrote [probe "wrote"]
        EOF	[
	        ?? len
	        close port
        ]
    ]
    false
]
if none? system/view [
	wait file-port
	close file-port
	print "Done"
]
]
