Red/System [
	Title:	"low-level I/O facilities"
	Author: "Xie Qingtian"
	File: 	%io.reds
	Tabs: 	4
	Rights: "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

SOCK_READBUF_SZ: 8192			;-- 8KB

#enum iocp-type! [
	IOCP_TYPE_TCP:		0
	IOCP_TYPE_UDP:		1
	IOCP_TYPE_DNS:		2
	IOCP_TYPE_FILE:		3
	IOCP_TYPE_TLS:		10h
]

make-sockaddr: func [
	saddr	[sockaddr_in!]
	addr	[c-string!]
	port	[integer!]
	type	[integer!]
][
	port: htons port
	saddr/sin_family: port << 16 or type
	saddr/sin_addr: inet_addr addr
	saddr/sa_data1: 0
	saddr/sa_data2: 0
]

#either OS = 'Windows [
	#include %windows/iocp.reds
	#include %windows/dns.reds
	#include %windows/tls.reds
	#include %windows/socket.reds
	;#include %windows/file.reds
][
	#include %POSIX/iocp.reds
	#include %POSIX/dns.reds
	#include %POSIX/tls.reds
	#include %POSIX/socket.reds
]