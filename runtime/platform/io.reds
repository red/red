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
	IOCP_TYPE_TLS:		10h
]

#either OS = 'Windows [
	#include %windows/iocp.reds
	#include %windows/tls.reds
	#include %windows/socket.reds
][
	#include %POSIX/iocp.reds
	#include %POSIX/tls.reds
	#include %POSIX/socket.reds
]