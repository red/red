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

#enum event-category! [
	EVT_CATEGORY_GUI
	EVT_CATEGORY_IO
]

#define SOCK_STREAM		1				;-- stream socket
#define SOCK_DGRAM		2				;-- datagram socket
#define SOCK_RAW		3				;-- raw-protocol interface
#define SOCK_RDM		4				;-- reliably-delivered message
#define SOCK_SEQPACKET	5				;-- sequenced packet stream

#define SO_DEBUG		0001h			;-- turn on debugging info recording
#define SO_ACCEPTCONN	0002h			;-- socket has had listen()
#define SO_REUSEADDR	0004h			;-- allow local address reuse
#define SO_KEEPALIVE	0008h			;-- keep connections alive
#define SO_DONTROUTE	0010h			;-- just use interface addresses
#define SO_BROADCAST	0020h			;-- permit sending of broadcast msgs
#define SO_USELOOPBACK	0040h			;-- bypass hardware when possible
#define SO_LINGER		0080h			;-- linger on close if data present
#define SO_OOBINLINE	0100h			;-- leave received OOB data in line

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

in6_addr!: alias struct! [				;-- 16 bytes
	addr1		[integer!]
	addr2		[integer!]
	addr3		[integer!]
	addr4		[integer!]
]

sockaddr_in6!: alias struct! [
	sin_family	 [integer!]
	sin_flowinfo [integer!]
	sin_addr	 [in6_addr! value]
	sin_scope_id [integer!]
]

;=== platform specific definitions ===

#either OS = 'Windows [
	#include %definitions/windows.reds
][			;-- POSIX
	#include %definitions/POSIX.reds
]