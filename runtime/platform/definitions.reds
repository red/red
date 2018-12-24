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

;=== Cross platform definitions ===

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

sockaddr_in!: alias struct! [			;-- 16 bytes
	sin_family	[integer!]				;-- family and port
	sin_addr	[integer!]
	sa_data1	[integer!]
	sa_data2	[integer!]
]

;=== platform specific definitions ===

#either OS = 'Windows [
	#include %definitions/windows.reds
][			;-- POSIX
	#include %definitions/POSIX.reds
]