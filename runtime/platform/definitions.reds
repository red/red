Red/System [
	Title:   "platform definitions"
	Author:  "Xie Qingtian"
	File: 	 %definitions.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2018 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

;-- Cross platform definitions

#define SOCK_STREAM		1				;-- stream socket
#define SOCK_DGRAM		2				;-- datagram socket
#define SOCK_RAW		3				;-- raw-protocol interface
#define SOCK_RDM		4				;-- reliably-delivered message
#define SOCK_SEQPACKET	5				;-- sequenced packet stream

#define IPPROTO_ICMP	1				;-- control message protocol
#define IPPROTO_IGMP	2				;-- group management protocol
#define IPPROTO_TCP		6				;-- tcp
#define IPPROTO_UDP		17				;-- user datagram protocol

#define AF_INET			2				;-- internetwork: UDP, TCP, etc.

#import [
	LIBC-file cdecl [
		realloc: "realloc" [			"Resize and return allocated memory."
			memory			[byte-ptr!]
			size			[integer!]
			return:			[byte-ptr!]
		]
	]
]