Red/System [
	Title:   "Red runtime win32 API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %defs-win.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#include %COM.reds

#define GENERIC_WRITE			40000000h
#define GENERIC_READ 			80000000h
#define FILE_SHARE_READ			00000001h
#define FILE_SHARE_WRITE		00000002h
#define FILE_SHARE_DELETE		00000004h
#define CREATE_NEW				00000001h
#define CREATE_ALWAYS			00000002h
#define OPEN_EXISTING			00000003h
#define OPEN_ALWAYS				00000004h
#define TRUNCATE_EXISTING		00000005h
#define FILE_ATTRIBUTE_NORMAL	00000080h
#define FILE_ATTRIBUTE_DIRECTORY  00000010h
#define FILE_FLAG_SEQUENTIAL_SCAN 08000000h
#define FILE_APPEND_DATA		4

#define STD_INPUT_HANDLE		-10
#define STD_OUTPUT_HANDLE		-11
#define STD_ERROR_HANDLE		-12

#define SET_FILE_BEGIN			0
#define SET_FILE_CURRENT		1
#define SET_FILE_END			2

#define MAX_FILE_REQ_BUF		4000h			;-- 16 KB
#define OFN_HIDEREADONLY		0004h
#define OFN_NOCHANGEDIR			0008h
#define OFN_EXPLORER			00080000h
#define OFN_ALLOWMULTISELECT	00000200h

#define WIN32_FIND_DATA_SIZE	592

#define BIF_RETURNONLYFSDIRS	1
#define BIF_USENEWUI			50h
#define BIF_SHAREABLE			8000h

#define BFFM_INITIALIZED		1
#define BFFM_SELCHANGED			2
#define BFFM_SETSELECTION		1127

#define VA_COMMIT_RESERVE	3000h						;-- MEM_COMMIT | MEM_RESERVE
#define VA_PAGE_RW			04h							;-- PAGE_READWRITE
#define VA_PAGE_RWX			40h							;-- PAGE_EXECUTE_READWRITE

#define KEY_EVENT 				 			01h
#define MOUSE_EVENT 			 			02h
#define WINDOW_BUFFER_SIZE_EVENT 			04h
#define MENU_EVENT 				 			08h
#define FOCUS_EVENT 			 			10h
#define ENHANCED_KEY 			 			0100h
#define ENABLE_PROCESSED_INPUT				01h
#define ENABLE_LINE_INPUT 					02h
#define ENABLE_ECHO_INPUT 					04h
#define ENABLE_WINDOW_INPUT         		08h
#define ENABLE_QUICK_EDIT_MODE				40h
#define ENABLE_VIRTUAL_TERMINAL_INPUT		0200h
#define ENABLE_VIRTUAL_TERMINAL_PROCESSING	04h
#define DISABLE_NEWLINE_AUTO_RETURN 		08h

#define _O_TEXT        	 	4000h  						;-- file mode is text (translated)
#define _O_BINARY       	8000h  						;-- file mode is binary (untranslated)
#define _O_WTEXT        	00010000h 					;-- file mode is UTF16 (translated)
#define _O_U16TEXT      	00020000h 					;-- file mode is UTF16 no BOM (translated)
#define _O_U8TEXT       	00040000h 					;-- file mode is UTF8  no BOM (translated)

#define SCH_CRED_MANUAL_CRED_VALIDATION	08h
#define SCH_CRED_NO_DEFAULT_CREDS		10h
#define SCH_USE_STRONG_CRYPTO			00400000h

#define ISC_REQ_REPLAY_DETECT			04h
#define ISC_REQ_SEQUENCE_DETECT			08h
#define ISC_REQ_CONFIDENTIALITY			10h
#define ISC_REQ_ALLOCATE_MEMORY			0100h
#define ISC_REQ_EXTENDED_ERROR			4000h
#define ISC_REQ_STREAM					8000h
#define ISC_REQ_MANUAL_CRED_VALIDATION	00080000h

#define ASC_REQ_EXTENDED_ERROR			8000h
#define ASC_REQ_STREAM					00010000h

#define FORMAT_MESSAGE_ALLOCATE_BUFFER	00000100h
#define FORMAT_MESSAGE_IGNORE_INSERTS	00000200h
#define FORMAT_MESSAGE_FROM_STRING		00000400h
#define FORMAT_MESSAGE_FROM_HMODULE		00000800h
#define FORMAT_MESSAGE_FROM_SYSTEM		00001000h

#define WEOF							FFFFh

#define INFINITE						FFFFFFFFh
#define HANDLE_FLAG_INHERIT				00000001h
#define STARTF_USESTDHANDLES			00000100h
#define STARTF_USESHOWWINDOW			00000001h

#define ERROR_BROKEN_PIPE				109
#define ERROR_IO_INCOMPLETE				996
#define ERROR_IO_PENDING				997

#define IS_TEXT_UNICODE_UNICODE_MASK 	000Fh

#define IOCP_WAIT_TIMEOUT				258
#define WAIT_OBJECT_0					0

#define FIONBIO							8004667Eh
#define SOL_SOCKET						FFFFh
#define NS_DNS							12

#define INVALID_HANDLE					[as int-ptr! -1]

#enum spawn-mode [
	P_WAIT:		0
	P_NOWAIT:	1
	P_OVERLAY:	2
	P_NOWAITO:	3
	P_DETACH:	4
]

#enum brush-type! [
	BRUSH_TYPE_NORMAL
	BRUSH_TYPE_TEXTURE
]

timeval!: alias struct! [
	tv_sec	[integer!]
	tv_usec [integer!]
]

SECURITY_ATTRIBUTES: alias struct! [
	nLength 			 [integer!]
	lpSecurityDescriptor [int-ptr!]
	bInheritHandle 		 [integer!]
]

OVERLAPPED!: alias struct! [
	Internal		[int-ptr!]
	InternalHigh	[int-ptr!]
	Offset			[integer!]				;-- or Pointer [int-ptr!]
	OffsetHigh		[integer!]
	hEvent			[int-ptr!]
]

OVERLAPPED_ENTRY!: alias struct! [
	lpCompletionKey				[int-ptr!]
	lpOverlapped				[int-ptr!]
	Internal					[int-ptr!]
	dwNumberOfBytesTransferred	[integer!]
]

WSADATA!: alias struct! [					;-- varies from 32bit to 64bit, for 32bit: 400 bytes
	wVersion		[integer!]
	;wHighVersion
	szDescription	[c-string!]
	szSystemStatus	[c-string!]
	iMaxSockets		[integer!]
	;iMaxUdpDg
	lpVendorInfo	[c-string!]
]

FLOWSPEC!: alias struct! [
	TokenRate		[uint!]
	TokenBucketSize	[uint!]
	PeakBandwidth	[uint!]
	Latency			[uint!]
	DelayVariation	[uint!]
	ServiceType		[uint!]
	MaxSduSize		[uint!]
	MinimumPolicedSize [uint!]
]

WSAPROTOCOL_INFOW: alias struct! [
	dwServiceFlags1		[integer!]
	dwServiceFlags2		[integer!]
	dwServiceFlags3		[integer!]
	dwServiceFlags4		[integer!]
	dwProviderFlags		[integer!]
	ProviderId			[integer!]
	dwCatalogEntryId	[integer!]
	ProtocolChain		[integer!]
	iVersion			[integer!]
	iAddressFamily		[integer!]
	iMaxSockAddr		[integer!]
	iMinSockAddr		[integer!]
	iSocketType			[integer!]
	iProtocol			[integer!]
	iProtocolMaxOffset	[integer!]
	iNetworkByteOrder	[integer!]
	iSecurityScheme		[integer!]
	dwMessageSize		[integer!]
	dwProviderReserved	[integer!]
	szProtocol			[integer!]
]

stat!: alias struct! [val [integer!]]

tagFILETIME: alias struct! [
	dwLowDateTime	[integer!]
	dwHighDateTime	[integer!]
]

WIN32_FIND_DATA: alias struct! [
	dwFileAttributes	[integer!]
	ftCreationTime		[tagFILETIME value]
	ftLastAccessTime	[tagFILETIME value]
	ftLastWriteTime		[tagFILETIME value]
	nFileSizeHigh		[integer!]
	nFileSizeLow		[integer!]
	dwReserved0			[integer!]
	dwReserved1			[integer!]
	;cFileName			[byte-ptr!]				;-- WCHAR  cFileName[ 260 ]
	;cAlternateFileName	[c-string!]				;-- cAlternateFileName[ 14 ]
]

WSABUF!: alias struct! [
	len			[integer!]
	buf			[byte-ptr!]
]

process-info!: alias struct! [
	hProcess	[integer!]
	hThread		[integer!]
	dwProcessId	[integer!]
	dwThreadId	[integer!]
]

startup-info!: alias struct! [
	cb				[integer!]
	lpReserved		[c-string!]
	lpDesktop		[c-string!]
	lpTitle			[c-string!]
	dwX				[integer!]
	dwY				[integer!]
	dwXSize			[integer!]
	dwYSize			[integer!]
	dwXCountChars	[integer!]
	dwYCountChars	[integer!]
	dwFillAttribute	[integer!]
	dwFlags			[integer!]
	wShowWindow-a	[byte!]           ; 16 bits integer needed here for windows WORD type
	wShowWindow-b	[byte!]
	cbReserved2-a	[byte!]
	cbReserved2-b	[byte!]
	lpReserved2		[byte-ptr!]
	hStdInput		[integer!]
	hStdOutput		[integer!]
	hStdError		[integer!]
]

security-attributes!: alias struct! [
	nLength				 [integer!]
	lpSecurityDescriptor [integer!]
	bInheritHandle		 [logic!]
]

OSVERSIONINFO: alias struct! [
	dwOSVersionInfoSize [integer!]
	dwMajorVersion		[integer!]
	dwMinorVersion		[integer!]
	dwBuildNumber		[integer!]	
	dwPlatformId		[integer!]
	szCSDVersion		[integer!]						;-- array of 128 bytes
	szCSDVersion0		[integer!]
	szCSDVersion1		[integer!]
	szCSDVersion2		[integer!]
	szCSDVersion3		[integer!]
	szCSDVersion4		[integer!]
	szCSDVersion5		[integer!]
	szCSDVersion6		[integer!]
	szCSDVersion7		[integer!]
	szCSDVersion8		[integer!]
	szCSDVersion9		[integer!]
	szCSDVersion10		[integer!]
	szCSDVersion11		[integer!]
	szCSDVersion12		[integer!]
	szCSDVersion13		[integer!]
	szCSDVersion14		[integer!]
	szCSDVersion15		[integer!]
	szCSDVersion16		[integer!]
	szCSDVersion17		[integer!]
	szCSDVersion18		[integer!]
	szCSDVersion19		[integer!]
	szCSDVersion20		[integer!]
	szCSDVersion21		[integer!]
	szCSDVersion22		[integer!]
	szCSDVersion23		[integer!]
	szCSDVersion24		[integer!]
	szCSDVersion25		[integer!]
	szCSDVersion26		[integer!]
	szCSDVersion27		[integer!]
	szCSDVersion28		[integer!]
	szCSDVersion29		[integer!]
	szCSDVersion30		[integer!]
	wServicePack		[integer!]						;-- Major: 16, Minor: 16
	wSuiteMask0			[byte!]
	wSuiteMask1			[byte!]
	wProductType		[byte!]
	wReserved			[byte!]
]

GdiplusStartupInput!: alias struct! [
	GdiplusVersion				[integer!]
	DebugEventCallback			[integer!]
	SuppressBackgroundThread	[integer!]
	SuppressExternalCodecs		[integer!]
]

tagSYSTEMTIME: alias struct! [
	year-month	[integer!]
	week-day	[integer!]
	hour-minute	[integer!]
	second		[integer!]
]

tagTIME_ZONE_INFORMATION: alias struct! [
	Bias				[integer!]
	StandardName1		[float!]			;-- StandardName: 64 bytes
	StandardName2		[float!]
	StandardName3		[float!]
	StandardName4		[float!]
	StandardName5		[float!]
	StandardName6		[float!]
	StandardName7		[float!]
	StandardName8		[float!]
	StandardDate		[tagSYSTEMTIME value]
	StandardBias		[integer!]
	DaylightName1		[float!]			;-- DaylightName: 64 bytes
	DaylightName2		[float!]
	DaylightName3		[float!]
	DaylightName4		[float!]
	DaylightName5		[float!]
	DaylightName6		[float!]
	DaylightName7		[float!]
	DaylightName8		[float!]
	DaylightDate		[tagSYSTEMTIME value]
	DaylightBias		[integer!]
]

tagSYSTEM_INFO: alias struct! [
	dwOemId						[integer!]
	dwPageSize					[integer!]
	lpMinimumApplicationAddress	[int-ptr!]
	lpMaximumApplicationAddress	[int-ptr!]
	dwActiveProcessorMask		[int-ptr!]
	dwNumberOfProcessors		[integer!]
	dwProcessorType				[integer!]
	dwAllocationGranularity		[integer!]
	wProcessorLevel				[integer!]
]

tagPAINTSTRUCT: alias struct! [
	hdc			 [handle!]
	fErase		 [integer!]
	left		 [integer!]
	top			 [integer!]
	right		 [integer!]
	bottom		 [integer!]
	fRestore	 [integer!]
	fIncUpdate	 [integer!]
	rgbReserved1 [integer!]
	rgbReserved2 [integer!]
	rgbReserved3 [integer!]
	rgbReserved4 [integer!]
	rgbReserved5 [integer!]
	rgbReserved6 [integer!]
	rgbReserved7 [integer!]
	rgbReserved8 [integer!]
]

POINT_2F: alias struct! [
	x		[float32!]
	y		[float32!]
]

PATHDATA: alias struct! [
	count       [integer!]
	points      [POINT_2F]
	types       [byte-ptr!]
]

tagPOINT: alias struct! [
	x		[integer!]
	y		[integer!]	
]

CRYPT_INTEGER_BLOB: alias struct! [
	cbData	[integer!]
	pbData	[byte-ptr!]
]

CRYPT_ALGORITHM_IDENTIFIER: alias struct! [
	pszObjId	[c-string!]
	Parameters	[CRYPT_INTEGER_BLOB value]
]

CRYPT_BIT_BLOB: alias struct! [
	cbData		[integer!]
	pbData		[byte-ptr!]
	cUnusedBits	[integer!]
]

CERT_PUBLIC_KEY_INFO: alias struct! [
	Algorithm	[CRYPT_ALGORITHM_IDENTIFIER value]
	PublicKey	[CRYPT_BIT_BLOB value]
]

CERT_INFO!: alias struct! [
	dwVersion			[integer!]
	SerialNumber		[CRYPT_INTEGER_BLOB value]
	SignatureAlgorithm	[CRYPT_ALGORITHM_IDENTIFIER value]
	Issuer				[CRYPT_INTEGER_BLOB value]
	NotBefore			[tagFILETIME value]
	NotAfter			[tagFILETIME value]
	Subject				[CRYPT_INTEGER_BLOB value]
	SubjectPublicKeyInfo [CERT_PUBLIC_KEY_INFO value]
	IssuerUniqueId		[CRYPT_BIT_BLOB value]
	SubjectUniqueId		[CRYPT_BIT_BLOB value]
	cExtension			[integer!]
	rgExtension			[int-ptr!]
]

BCRYPT_RSAKEY_BLOB: alias struct! [
	magic		[integer!]
	bitlen		[integer!]
	cbPubExp	[integer!]
	cbMod		[integer!]
	cbPrime1	[integer!]
	cbPrime2	[integer!]
]

BCRYPT_ECCKEY_BLOB: alias struct! [
	dwMagic		[integer!]
	cbKey		[integer!]
]

CRYPT_ECC_PRIVATE_KEY_INFO: alias struct! [
	dwVersion	[integer!]				;-- ecPrivKeyVer1(1)
	PrivateKey	[CRYPT_INTEGER_BLOB value] ;-- d
	szCurveOid	[c-string!]				;-- Optional
	PublicKey	[CRYPT_BIT_BLOB value]	;-- Optional (x, y)
]

CRYPT_KEY_PROV_PARAM: alias struct! [
	dwParam		[integer!]
	pbData		[byte-ptr!]
	cbData		[integer!]
	dwFlags		[integer!]
]

CRYPT_KEY_PROV_INFO: alias struct! [
	pwszContainerName	[c-string!]
	pwszProvName		[c-string!]
	dwProvType			[integer!]
	dwFlags				[integer!]
	cProvParam			[integer!]
	rgProvParam			[CRYPT_KEY_PROV_PARAM]
	dwKeySpec			[integer!]
]

BCryptBuffer!: alias struct! [
	cbBuffer	[integer!]		;-- Length of buffer, in bytes
	BufferType	[integer!]		;-- Buffer type
	pvBuffer	[byte-ptr!]		;-- Pointer to buffer
]

BCryptBufferDesc!: alias struct! [
	ulVersion	[integer!]		;-- Version number
	cBuffers	[integer!]		;-- Number of buffers
	pBuffers	[BCryptBuffer!]	;-- Pointer to array of buffers
]

CERT_CONTEXT: alias struct! [
	dwCertEncodingType	[integer!]
	pbCertEncoded		[byte-ptr!]
	cbCertEncoded		[integer!]
	pCertInfo			[CERT_INFO!]
	hCertStore			[int-ptr!]
]

SCHANNEL_CRED: alias struct! [
	dwVersion				[integer!]
	cCreds					[integer!]
	paCred					[int-ptr!]
	hRootStore				[int-ptr!]

	cMappers				[integer!]
	aphMappers				[int-ptr!]

	cSupportedAlgs			[integer!]
	palgSupportedAlg		[int-ptr!]

	grbitEnabledProtocols	[integer!]
	dwMinimumCipherStrength	[integer!]
	dwMaximumCipherStrength	[integer!]
	dwSessionLifespan		[integer!]
	dwFlags					[integer!]
	dwCredFormat			[integer!]
]

SecHandle!: alias struct! [
	dwLower		[int-ptr!]
	dwUpper		[int-ptr!]
]

SecBuffer!: alias struct! [
	cbBuffer	[integer!]			;-- Size of the buffer, in bytes
	BufferType	[integer!]			;-- Type of the buffer (below)
	pvBuffer	[byte-ptr!]
]

SecBufferDesc!: alias struct! [
	ulVersion	[integer!]
	cBuffers	[integer!]
	pBuffers	[SecBuffer!]
]

SecPkgContext_IssuerListInfoEx!: alias struct! [
	aIssuers	[int-ptr!]
	cIssuers	[integer!]
]

SecPkgContext_StreamSizes: alias struct! [
	cbHeader			[integer!]
	cbTrailer			[integer!]
	cbMaximumMessage	[integer!]
	cBuffers			[integer!]
	cbBlockSize			[integer!]
]

CERT_ENHKEY_USAGE: alias struct! [
	cUsageIdentifier		[integer!]
	rgpszUsageIdentifier	[int-ptr!]
]

CERT_STRONG_SIGN_PARA: alias struct! [
	cbSize				[integer!]
	choice				[integer!]
	u					[int-ptr!]
]

CERT_USAGE_MATCH: alias struct! [
	type				[integer!]
	usage				[CERT_ENHKEY_USAGE value]
]

CERT_CHAIN_PARA: alias struct! [
	cbSize				[integer!]
	usage				[CERT_USAGE_MATCH value]
	policy				[CERT_USAGE_MATCH value]
	timeout				[integer!]
	check-time			[logic!]
	time				[integer!]
	resync				[tagFILETIME]
	strong				[CERT_STRONG_SIGN_PARA]
	flags				[integer!]
]

CERT_TRUST_STATUS: alias struct! [
	dwErrorStatus		[integer!]
	dwInfoStatus		[integer!]
]

CERT_CHAIN_ELEMENT: alias struct! [
	cbSize				[integer!]
	pCertContext		[CERT_CONTEXT]
	TrustStatus			[CERT_TRUST_STATUS value]
	pRevocationInfo		[int-ptr!]
	pIssuanceUsage		[CERT_ENHKEY_USAGE]
	pApplicationUsage	[CERT_ENHKEY_USAGE]
	ErrorInfo			[byte-ptr!]
]

CERT_SIMPLE_CHAIN: alias struct! [
	cbSize				[integer!]
	TrustStatus			[CERT_TRUST_STATUS value]
	cElement			[integer!]
	rgpElement			[int-ptr!]
	pTrustListInfo		[integer!]
	has-time			[logic!]
	time				[integer!]
]

CERT_CHAIN_CONTEXT: alias struct! [
	cbSize				[integer!]
	TrustStatus			[CERT_TRUST_STATUS value]
	cChain				[integer!]
	rgpChain			[int-ptr!]
	cLower				[integer!]
	rgpLower			[int-ptr!]
	has-time			[logic!]
	time				[integer!]
	flags				[integer!]
	ChainId				[tagGUID value]
]

CERT_CHAIN_POLICY_PARA: alias struct! [
	cbSize				[integer!]
	flags				[integer!]
	extra				[byte-ptr!]
]

HTTPSPolicyCallbackData: alias struct! [
	cbSize				[integer!]
	dwAuthType			[integer!]
	fdwChecks			[integer!]
	pwszServerName		[byte-ptr!]
]

CERT_CHAIN_POLICY_STATUS: alias struct! [
	cbSize				[integer!]
	dwError				[integer!]
	lChainIndex			[integer!]
	lElementIndex		[integer!]
	pvExtraPolicyStatus	[byte-ptr!]
]

AcquireCredentialsHandleW!: alias function! [
	pszPrincipal		[c-string!]
	pszPackage			[c-string!]
	fCredentialUse		[integer!]
	pvLogonId			[int-ptr!]
	pAuthData			[int-ptr!]
	pGetKeyFn			[int-ptr!]
	pvGetKeyArgument	[int-ptr!]
	phCredential		[SecHandle!]
	ptsExpiry			[tagFILETIME]
	return:				[integer!]
]

FreeCredentialsHandle!: alias function! [
	phCredential		[SecHandle!]
	return:				[integer!]
]

AcceptSecurityContext!: alias function! [
	phCredential		[SecHandle!]
	phContext			[SecHandle!]
	pInput				[SecBufferDesc!]
	fContextReq			[integer!]
	TargetDataRep		[integer!]
	phNewContext		[SecHandle!]
	pOutput				[SecBufferDesc!]
	pfContextAttr		[int-ptr!]
	ptsExpiry			[tagFILETIME]
	return:				[integer!]
]

CompleteAuthToken!: alias function! [
	phContext			[SecHandle!]
	pToken				[SecBufferDesc!]
	return:				[integer!]
]

InitializeSecurityContextW!: alias function! [
	phCredential		[SecHandle!]
	phContext			[SecHandle!]
	pTargetName			[c-string!]
	fContextReq			[integer!]
	Reserved1			[integer!]
	TargetDataRep		[integer!]
	pInput				[SecBufferDesc!]
	Reserved2			[integer!]
	phNewContext		[SecHandle!]
	pOutput				[SecBufferDesc!]
	pfContextAttr		[int-ptr!]
	ptsExpiry			[tagFILETIME]
	return:				[integer!]
]

DeleteSecurityContext!: alias function! [
	phContext			[int-ptr!]
	return:				[integer!]
]

FreeContextBuffer!: alias function! [
	pvContextBuffer		[byte-ptr!]
	return:				[integer!]
]

ApplyControlToken!: alias function! [
	phContext			[SecHandle!]
	pInput				[SecBufferDesc!]
	return:				[integer!]
]

QueryContextAttributesW!: alias function! [
	phContext			[SecHandle!]
	ulAttribute			[integer!]
	pBuffer				[byte-ptr!]
	return:				[integer!]
]

QuerySecurityContextToken!: alias function! [
	phContext			[SecHandle!]
	Token				[ptr-ptr!]
	return:				[integer!]
]

DecryptMessage!: alias function! [
	phContext			[SecHandle!]
	pMessage			[SecBufferDesc!]
	MessageSeqNo		[integer!]
	fQOP				[int-ptr!]
	return:				[integer!]
]

EncryptMessage!: alias function! [
	phContext			[SecHandle!]
	fQOP				[integer!]
	pMessage			[SecBufferDesc!]
	MessageSeqNo		[integer!]
	return:				[integer!]
]

SecurityFunctionTableW: alias struct! [
	dwVersion					[integer!]
	EnumerateSecurityPackagesW	[int-ptr!]
	QueryCredentialsAttributesW	[int-ptr!]
	AcquireCredentialsHandleW	[AcquireCredentialsHandleW!]
	FreeCredentialsHandle		[FreeCredentialsHandle!]
	Reserved2					[int-ptr!]
	InitializeSecurityContextW	[InitializeSecurityContextW!]
	AcceptSecurityContext		[AcceptSecurityContext!]
	CompleteAuthToken			[CompleteAuthToken!]
	DeleteSecurityContext		[DeleteSecurityContext!]
	ApplyControlToken			[ApplyControlToken!]
	QueryContextAttributesW		[QueryContextAttributesW!]
	ImpersonateSecurityContext	[int-ptr!]
	RevertSecurityContext		[int-ptr!]
	MakeSignature				[int-ptr!]
	VerifySignature				[int-ptr!]
	FreeContextBuffer			[FreeContextBuffer!]
	QuerySecurityPackageInfoW	[int-ptr!]
	Reserved3					[int-ptr!]
	Reserved4					[int-ptr!]
	ExportSecurityContext		[int-ptr!]
	ImportSecurityContextW		[int-ptr!]
	AddCredentialsW 			[int-ptr!]
	Reserved8					[int-ptr!]
	QuerySecurityContextToken	[QuerySecurityContextToken!]
	EncryptMessage				[EncryptMessage!]
	DecryptMessage				[DecryptMessage!]
	SetContextAttributesW		[int-ptr!]	;-- available in OSes after win2k
	SetCredentialsAttributesW	[int-ptr!]	;-- available in OSes after W2k3SP1

	ChangeAccountPasswordW		[int-ptr!]

	;-- Fields below this are available in OSes after Windows 8.1
	QueryContextAttributesExW	[int-ptr!]
	QueryCredentialsAttributesExW [int-ptr!]
]

DNS_HEADER: alias struct! [
	Xid				[integer!]
	QuestionCount	[integer!]
	;AnswerCount
	NameServerCount	[integer!]
	;AdditionalCount
]

DNS_MESSAGE_BUFFER: alias struct! [
    MessageHead		[DNS_HEADER value]
    MessageBody		[integer!]
]

DNS_RECORD!: alias struct! [
	pNext		[DNS_RECORD!]
	pName		[c-string!]
	wType		[int16!]
	;wDataLength [int16!]
	Flags		[integer!]
	dwTtl		[integer!]
	dwReserved	[integer!]

	;// Record Data
	A			[integer!]
]

#import [
	LIBC-file cdecl [
		_setmode: "_setmode" [
			handle		[integer!]
			mode		[integer!]
			return:		[integer!]
		]
		_fileno: "_fileno" [
			file		[int-ptr!]
			return:		[integer!]
		]
		__iob_func: "__iob_func" [return: [int-ptr!]]
		wcsupr: "_wcsupr" [
			str		[c-string!]
			return:	[c-string!]
		]
		strnicmp: "_strnicmp" [
			s1			[byte-ptr!]
			s2			[byte-ptr!]
			len			[integer!]
			return:		[integer!]
		]
		_rename: "_wrename" [
			old		[c-string!]
			new		[c-string!]
			return:	[integer!]
		]
	]
	"kernel32.dll" stdcall [
		CreateEventA: "CreateEventA" [
			lpAttr		[SECURITY_ATTRIBUTES]
			ManualReset	[logic!]
			Initial		[logic!]
			lpName		[c-string!]
			return:		[handle!]
		]
		SetEvent: "SetEvent" [
			hEvent		[handle!]
			return:		[logic!]
		]
		ResetEvent: "ResetEvent" [
			hEvent		[handle!]
			return:		[logic!]
		]
		VirtualAlloc: "VirtualAlloc" [
			address		[byte-ptr!]
			size		[integer!]
			type		[integer!]
			protection	[integer!]
			return:		[int-ptr!]
		]
		VirtualFree: "VirtualFree" [
			address 	[int-ptr!]
			size		[integer!]
			type		[integer!]
			return:		[integer!]
		]
		AllocConsole: "AllocConsole" [return: [logic!]]
		FreeConsole: "FreeConsole" [return: [logic!]]
		WriteConsole: 	 "WriteConsoleW" [
			consoleOutput	[integer!]
			buffer			[byte-ptr!]
			charsToWrite	[integer!]
			numberOfChars	[int-ptr!]
			_reserved		[int-ptr!]
			return:			[integer!]
		]
		WriteFile: "WriteFile" [
			handle			[integer!]
			buffer			[byte-ptr!]
			len				[integer!]
			written			[int-ptr!]
			overlapped		[integer!]
			return:			[integer!]
		]
		GetConsoleMode:	"GetConsoleMode" [
			handle			[integer!]
			mode			[int-ptr!]
			return:			[integer!]
		]
		GetCurrentDirectory: "GetCurrentDirectoryW" [
			buf-len			[integer!]
			buffer			[byte-ptr!]
			return:			[integer!]
		]
		SetCurrentDirectory: "SetCurrentDirectoryW" [
			lpPathName		[c-string!]
			return:			[logic!]
		]
		GetCommandLine: "GetCommandLineW" [
			return:			[byte-ptr!]
		]
		GetEnvironmentStrings: "GetEnvironmentStringsW" [
			return:		[c-string!]
		]
		GetEnvironmentVariable: "GetEnvironmentVariableW" [
			name		[c-string!]
			value		[c-string!]
			valsize		[integer!]
			return:		[integer!]
		]
		SetEnvironmentVariable: "SetEnvironmentVariableW" [
			name		[c-string!]
			value		[c-string!]
			return:		[logic!]
		]
		FreeEnvironmentStrings: "FreeEnvironmentStringsW" [
			env			[c-string!]
			return:		[logic!]
		]
		FileTimeToSystemTime: "FileTimeToSystemTime" [
			filetime	[tagFILETIME]
			systemtime	[tagSYSTEMTIME]
			return:		[integer!]
		]
		GetSystemTimeAsFileTime: "GetSystemTimeAsFileTime" [
			time			[tagFILETIME]
		]
		GetSystemTime: "GetSystemTime" [
			time			[tagSYSTEMTIME]
		]
		GetLocalTime: "GetLocalTime" [
			time			[tagSYSTEMTIME]
		]
		GetTimeZoneInformation: "GetTimeZoneInformation" [
			tz				[tagTIME_ZONE_INFORMATION]
			return:			[integer!]
		]
		OS-Sleep: "Sleep" [
			dwMilliseconds	[integer!]
		]
		lstrlen: "lstrlenW" [
			str			[byte-ptr!]
			return:		[integer!]
		]
		CreateProcessW: "CreateProcessW" [
			lpApplicationName       [c-string!]
			lpCommandLine           [c-string!]
			lpProcessAttributes     [integer!]
			lpThreadAttributes      [integer!]
			bInheritHandles         [logic!]
			dwCreationFlags         [integer!]
			lpEnvironment           [integer!]
			lpCurrentDirectory      [c-string!]
			lpStartupInfo           [startup-info!]
			lpProcessInformation    [process-info!]
			return:                 [logic!]
		]
		WaitForSingleObject: "WaitForSingleObject" [
			hHandle                 [handle!]
			dwMilliseconds          [integer!]
			return:                 [integer!]
		]
		GetExitCodeProcess: "GetExitCodeProcess" [
			hProcess				[integer!]
			lpExitCode				[int-ptr!]
			return:                 [logic!]
		]
		CreatePipe: "CreatePipe" [
			hReadPipe               [int-ptr!]
			hWritePipe              [int-ptr!]
			lpPipeAttributes        [security-attributes!]
			nSize                   [integer!]
			return:                 [logic!]
		]
		CreateFileW: "CreateFileW" [
			lpFileName				[c-string!]
			dwDesiredAccess			[integer!]
			dwShareMode				[integer!]
			lpSecurityAttributes	[security-attributes!]
			dwCreationDisposition	[integer!]
			dwFlagsAndAttributes	[integer!]
			hTemplateFile			[integer!]
			return:					[integer!]
		]
		CloseHandle: "CloseHandle" [
			hObject                 [int-ptr!]
			return:                 [logic!]
		]
		GetStdHandle: "GetStdHandle" [
			nStdHandle				[integer!]
			return:					[integer!]
		]
		ReadFile: "ReadFile" [
			hFile                   [integer!]
			lpBuffer                [byte-ptr!]
			nNumberOfBytesToRead    [integer!]
			lpNumberOfBytesRead     [int-ptr!]
			lpOverlapped            [integer!]
			return:                 [integer!]
		]
		SetHandleInformation: "SetHandleInformation" [
			hObject					[integer!]
			dwMask					[integer!]
			dwFlags					[integer!]
			return:					[logic!]
		]
		GetLastError: "GetLastError" [
			return:                 [integer!]
		]
		MultiByteToWideChar: "MultiByteToWideChar" [
			CodePage				[integer!]
			dwFlags					[integer!]
			lpMultiByteStr			[byte-ptr!]
			cbMultiByte				[integer!]
			lpWideCharStr			[byte-ptr!]
			cchWideChar				[integer!]
			return:					[integer!]
		]
		SetFilePointer: "SetFilePointer" [
			file		[integer!]
			distance	[integer!]
			pDistance	[int-ptr!]
			dwMove		[integer!]
			return:		[integer!]
		]
		GetNativeSystemInfo: "GetNativeSystemInfo" [
			lpSystemInfo	[tagSYSTEM_INFO]
		]
		IsWow64Process: "IsWow64Process" [
			hProcess	[int-ptr!]
			isWow64?	[int-ptr!]
			return:		[logic!]
		]
		GetVersionEx: "GetVersionExA" [
			lpVersionInfo [OSVERSIONINFO]
			return:		[integer!]
		]
		GetCurrentProcess: "GetCurrentProcess" [
			return:		[int-ptr!]
		]
		GetFileAttributesW: "GetFileAttributesW" [
			path		[c-string!]
			return:		[integer!]
		]
		GetFileAttributesExW: "GetFileAttributesExW" [
			path		[c-string!]
			info-level  [integer!]
			info		[WIN32_FIND_DATA]
			return:		[integer!]
		]
		CreateFileA: "CreateFileA" [			;-- temporary needed by Red/System
			filename	[c-string!]
			access		[integer!]
			share		[integer!]
			security	[int-ptr!]
			disposition	[integer!]
			flags		[integer!]
			template	[int-ptr!]
			return:		[integer!]
		]
		CreateDirectory: "CreateDirectoryW" [
			pathname	[c-string!]
			sa			[int-ptr!]
			return:		[logic!]
		]
		DeleteFile: "DeleteFileW" [
			filename	[c-string!]
			return:		[integer!]
		]
		RemoveDirectory: "RemoveDirectoryW" [
			filename	[c-string!]
			return:		[integer!]
		]
		FindFirstFile: "FindFirstFileW" [
			filename	[c-string!]
			filedata	[WIN32_FIND_DATA]
			return:		[integer!]
		]
		FindNextFile: "FindNextFileW" [
			file		[integer!]
			filedata	[WIN32_FIND_DATA]
			return:		[integer!]
		]
		FindClose: "FindClose" [
			file		[integer!]
			return:		[integer!]
		]
		GetFileSize: "GetFileSize" [
			file		[integer!]
			high-size	[integer!]
			return:		[integer!]
		]
		SetEndOfFile: "SetEndOfFile" [
			file		[integer!]
			return:		[integer!]
		]
		WideCharToMultiByte: "WideCharToMultiByte" [
			CodePage			[integer!]
			dwFlags				[integer!]
			lpWideCharStr		[c-string!]
			cchWideChar			[integer!]
			lpMultiByteStr		[byte-ptr!]
			cbMultiByte			[integer!]
			lpDefaultChar		[c-string!]
			lpUsedDefaultChar	[integer!]
			return:				[integer!]
		]
		GetLogicalDriveStrings: "GetLogicalDriveStringsW" [
			buf-len				[integer!]
			buffer				[byte-ptr!]
			return:				[integer!]
		]
		CreateThread: "CreateThread" [
			lpThreadAttributes	[SECURITY_ATTRIBUTES]
			dwStackSize			[integer!]
			lpStartAddress		[int-ptr!]
			lpParameter			[int-ptr!]
			dwCreationFlags		[integer!]
			lpThreadID			[int-ptr!]
			return:				[int-ptr!]
		]
		CreateIoCompletionPort: "CreateIoCompletionPort" [
			FileHandle		[int-ptr!]
			ExistingPort	[int-ptr!]
			CompletionKey	[int-ptr!]
			nThreads		[integer!]
			return:			[int-ptr!]
		]
		GetQueuedCompletionStatus: "GetQueuedCompletionStatus" [
			CompletionPort		[int-ptr!]
			lpNumberOfBytes		[int-ptr!]
			lpCompletionKey		[int-ptr!]
			lpOverlapped		[OVERLAPPED!]
			dwMilliseconds		[integer!]
			return:				[integer!]
		]
		GetQueuedCompletionStatusEx: "GetQueuedCompletionStatusEx" [
			CompletionPort		[int-ptr!]
			entries				[OVERLAPPED_ENTRY!]
			ulCount				[integer!]
			entriesRemoved		[int-ptr!]
			dwMilliseconds		[integer!]
			alertable			[logic!]
			return:				[integer!]
		]
		PostQueuedCompletionStatus: "PostQueuedCompletionStatus" [
			CompletionPort		[int-ptr!]
			nTransferred		[integer!]
			dwCompletionKey		[int-ptr!]
			lpOverlapped		[OVERLAPPED!]
			return:				[integer!]
		]
		SetFileCompletionNotificationModes: "SetFileCompletionNotificationModes" [
			handle				[int-ptr!]
			flags				[integer!]
			return:				[logic!]
		]
	]
	"ws2_32.dll" stdcall [
		WSAStartup: "WSAStartup" [
			version		[integer!]
			lpWSAData	[int-ptr!]
			return:		[integer!]
		]
		WSASocketW: "WSASocketW" [
			af				[integer!]
			type			[integer!]
			protocol		[integer!]
			lpProtocolInfo	[WSAPROTOCOL_INFOW]
			g				[integer!]
			dwFlags			[integer!]
			return:			[integer!]
		]
		WSAConnect: "WSAConnect" [
			s				[ulong!]
			name			[sockaddr_in!]
			namelen			[integer!]
			lpCallerData	[WSABUF!]
			lpCalleeData	[WSABUF!]
			lpSQOS			[FLOWSPEC!]
			lpGQOS			[FLOWSPEC!]
			return:			[integer!]
		]
		WSASend: "WSASend" [
			s					[integer!]
			lpBuffers			[WSABUF!]
			dwBufferCount		[integer!]
			lpNumberOfBytesSent	[int-ptr!]
			dwFlags				[integer!]
			lpOverlapped		[OVERLAPPED!]
			lpCompletionRoutin	[int-ptr!]
			return:				[integer!]
		]
		WSASendTo: "WSASendTo" [
			s					[integer!]
			lpBuffers			[WSABUF!]
			dwBufferCount		[integer!]
			lpNumberOfBytesSent	[int-ptr!]
			dwFlags				[integer!]
			lpTo				[sockaddr_in6!]
			lpTolen				[integer!]
			lpOverlapped		[OVERLAPPED!]
			lpCompletionRoutin	[int-ptr!]
			return:				[integer!]
		]
		WSARecv: "WSARecv" [
			s					[integer!]
			lpBuffers			[WSABUF!]
			dwBufferCount		[integer!]
			lpNumberOfBytesSent	[int-ptr!]
			dwFlags				[int-ptr!]
			lpOverlapped		[OVERLAPPED!]
			lpCompletionRoutin	[int-ptr!]
			return:				[integer!]
		]
		WSARecvFrom: "WSARecvFrom" [
			s					[integer!]
			lpBuffers			[WSABUF!]
			dwBufferCount		[integer!]
			lpNumberOfBytesSent	[int-ptr!]
			dwFlags				[int-ptr!]
			lpFrom				[sockaddr_in6!]
			lpFromlen			[int-ptr!]
			lpOverlapped		[OVERLAPPED!]
			lpCompletionRoutin	[int-ptr!]
			return:				[integer!]
		]
		GetAddrInfoExW: "GetAddrInfoExW" [
			pName				[c-string!]
			pServiceName		[c-string!]
			dwNameSpace			[integer!]
			lpNspId				[int-ptr!]
			pHints				[addrinfo!]
			ppResult			[int-ptr!]
			timeout				[timeval!]
			lpOverlapped		[OVERLAPPED!]
			lpCompletionRoutine	[int-ptr!]
			lpNameHandle		[int-ptr!]
			return:				[integer!]
		]
		FreeAddrInfoEx: "FreeAddrInfoEx" [
			pAddInfoEx			[ptr-ptr!]
		]
		inet_pton: "inet_pton" [
			Family				[integer!]
			pszAddrString		[c-string!]
			pAddrBuf			[int-ptr!]
			return:				[integer!]
		]
		WSAWaitForMultipleEvents: "WSAWaitForMultipleEvents" [
			cEvents				[integer!]
			lphEvents			[int-ptr!]
			fWaitAll			[logic!]
			dwTimeout			[integer!]
			fAlertable			[logic!]
			return:				[integer!]
		]
		WSAIoctl: "WSAIoctl" [
			s					[integer!]
			dwIoControlCode		[integer!]
			lpvInBuffer			[int-ptr!]
			cbInBuffer			[integer!]
			lpvOutBuffer		[int-ptr!]
			cbOutBuffer			[integer!]
			lpcbBytesReturned	[int-ptr!]
			lpOverlapped		[OVERLAPPED!]
			lpCompletionRoutine	[int-ptr!]
			return:				[integer!]
		]
		closesocket: "closesocket" [
			s			[integer!]
			return:		[integer!]
		]
		ioctlsocket: "ioctlsocket" [
			s			[integer!]
			cmd			[integer!]
			argp		[int-ptr!]
			return:		[integer!]
		]
		htons: "htons" [
			hostshort	[integer!]
			return:		[integer!]
		]
		inet_addr: "inet_addr" [
			cp			[c-string!]
			return:		[integer!]
		]
		WS2.bind: "bind" [
			s			[integer!]
			addr		[int-ptr!]
			namelen		[integer!]
			return:		[integer!]
		]
		WS2.listen: "listen" [
			s			[integer!]
			backlog		[integer!]
			return:		[integer!]
		]
		setsockopt: "setsockopt" [
			s			[integer!]
			level		[integer!]
			optname		[integer!]
			optval		[c-string!]
			optlen		[integer!]
			return:		[integer!]
		]
		getsockopt: "getsockopt" [
			s			[integer!]
			level		[integer!]
			optname		[integer!]
			optval		[c-string!]
			optlen		[int-ptr!]
			return:		[integer!]
		]
		getpeername: "getpeername" [
			s			[integer!]
			name		[sockaddr_in6!]
			len			[int-ptr!]
			return:		[integer!]
		]
		ntohs: "ntohs" [
			netshort	[uint16!]
			return:		[uint16!]
		]
	]
	"dnsapi.dll" stdcall [
		DnsQueryConfig: "DnsQueryConfig" [
			Config			[integer!]
			Flag			[integer!]
			pwsAdapterName	[c-string!]
			pReserved		[byte-ptr!]
			pBuffer			[int-ptr!]
			pBufLen			[int-ptr!]
			return:			[integer!]
		]
		DnsWriteQuestionToBuffer_UTF8: "DnsWriteQuestionToBuffer_UTF8" [
			pDnsBuffer		[byte-ptr!]
			pdwBufferSize	[int-ptr!]
			pszName			[c-string!]
			wType			[integer!]
			Xid				[integer!]
			fRecursionDesired [logic!]
			return:			[logic!]
		]
		DnsExtractRecordsFromMessage_UTF8: "DnsExtractRecordsFromMessage_UTF8" [
			pDnsBuffer		[DNS_MESSAGE_BUFFER]
			wMessageLength	[integer!]
			ppRecord		[ptr-ptr!]
			return:			[integer!]
		]
		;DnsRecordListFree: "DnsRecordListFree" [
		;	p				[DNS_RECORD!]
		;	t				[integer!]
		;]
		DnsFree: "DnsFree" [
			pData			[byte-ptr!]
			type			[integer!]
		]
	]
	"gdiplus.dll" stdcall [
		GdiplusStartup: "GdiplusStartup" [
			token		[int-ptr!]
			input		[integer!]
			output		[integer!]
			return:		[integer!]
		]
		GdiplusShutdown: "GdiplusShutdown" [
			token		[integer!]
		]
	]
	"shell32.dll" stdcall [
		ShellExecute: "ShellExecuteW" [
			hwnd		 [integer!]
			lpOperation	 [c-string!]
			lpFile		 [c-string!]
			lpParameters [integer!]
			lpDirectory	 [integer!]
			nShowCmd	 [integer!]
			return:		 [integer!]
		]
	]
	"secur32.dll" stdcall [
		InitSecurityInterfaceW: "InitSecurityInterfaceW" [
			return: [SecurityFunctionTableW]
		]
	]
	"crypt32.dll" stdcall [
		CertOpenStore: "CertOpenStore" [
			lpszStoreProvider	[integer!]
			dwEncodingType		[integer!]
			hCryptProv			[int-ptr!]
			dwFlags				[integer!]
			pvPara				[c-string!]
			return:				[int-ptr!]
		]
		CertCloseStore: "CertCloseStore" [
			store				[int-ptr!]
			flags				[integer!]
			return:				[logic!]
		]
		CertDuplicateStore: "CertDuplicateStore" [
			store				[int-ptr!]
			return:				[int-ptr!]
		]
		CertEnumCertificatesInStore: "CertEnumCertificatesInStore" [
			store				[int-ptr!]
			ctx					[CERT_CONTEXT]
			return:				[CERT_CONTEXT]
		]
		CertAddCertificateContextToStore: "CertAddCertificateContextToStore" [
			store				[int-ptr!]
			ctx					[CERT_CONTEXT]
			dwAddDisposition	[integer!]
			ppStoreContext		[int-ptr!]
			return:				[logic!]
		]
		CertFindCertificateInStore: "CertFindCertificateInStore" [
			hCertStore			[int-ptr!]
			dwCertEncodingType	[integer!]
			dwFindFlags			[integer!]
			dwFindType			[integer!]
			pvFindPara			[byte-ptr!]
			pPrevCertContext	[CERT_CONTEXT]
			return:				[CERT_CONTEXT]
		]
		CertGetNameStringA: "CertGetNameStringA" [
			ctx					[CERT_CONTEXT]
			type				[integer!]
			flags				[integer!]
			para				[int-ptr!]
			name				[c-string!]
			len					[integer!]
			return:				[integer!]
		]
		CertCreateCertificateContext: "CertCreateCertificateContext" [
			dwCertEncodingType	[integer!]
			pbCertEncoded		[byte-ptr!]
			cbCertEncode		[integer!]
			return:				[CERT_CONTEXT]
		]
		CertFreeCertificateContext: "CertFreeCertificateContext" [
			ctx					[CERT_CONTEXT]
			return:				[logic!]
		]
		CertAddEncodedCertificateToStore: "CertAddEncodedCertificateToStore" [
			store				[int-ptr!]
			type				[integer!]
			encoded				[byte-ptr!]
			len					[integer!]
			disposition			[integer!]
			ctx					[int-ptr!]
			return:				[logic!]
		]
		CertSetCertificateContextProperty: "CertSetCertificateContextProperty" [
			ctx					[CERT_CONTEXT]
			propID				[integer!]
			dwFlags				[integer!]
			pvData				[byte-ptr!]
			return:				[logic!]
		]
		CertGetCertificateContextProperty: "CertGetCertificateContextProperty" [
			ctx					[CERT_CONTEXT]
			propID				[integer!]
			pvData				[byte-ptr!]
			pcbData				[int-ptr!]
			return:				[logic!]
		]
		CertGetCertificateChain: "CertGetCertificateChain" [
			engine				[int-ptr!]
			ctx					[CERT_CONTEXT]
			time				[int-ptr!]
			add-store			[int-ptr!]
			para				[CERT_CHAIN_PARA]
			flags				[integer!]
			reserved			[integer!]
			pChain				[int-ptr!]
			return:				[logic!]
		]
		CertVerifyCertificateChainPolicy: "CertVerifyCertificateChainPolicy" [
			iod					[int-ptr!]
			pChainContext		[CERT_CHAIN_CONTEXT]
			pPolicyPara			[CERT_CHAIN_POLICY_PARA]
			pPolicyStatus		[CERT_CHAIN_POLICY_STATUS]
			return:				[logic!]
		]
		CryptStringToBinaryA: "CryptStringToBinaryA" [
			pszString			[c-string!]
			cchString			[integer!]
			dwFlags				[integer!]
			pbBinary			[byte-ptr!]
			pcbBinary			[int-ptr!]
			pdwSkip				[int-ptr!]
			pdwFlags			[int-ptr!]
			return:				[logic!]
		]
		CryptDecodeObjectEx: "CryptDecodeObjectEx" [
			dwCertEncodingType	[integer!]
			lpszStructType		[integer!]
			pbEncoded			[byte-ptr!]
			cbEncoded			[integer!]
			dwFlags				[integer!]
			pDecodePara			[int-ptr!]
			pvStructInfo		[byte-ptr!]
			pcbStructInf		[int-ptr!]
			return:				[logic!]
		]
	]
	"ncrypt.dll" stdcall [
		NCryptOpenStorageProvider: "NCryptOpenStorageProvider" [
			phProvider			[int-ptr!]
			pszProviderName		[c-string!]
			dwFlag				[integer!]
			return:				[integer!]
		]
		NCryptImportKey: "NCryptImportKey" [
			hProvider			[int-ptr!]
			hImportKey			[int-ptr!]
			pszBlobType			[c-string!]
			ParameterList		[int-ptr!]
			phKey				[int-ptr!]
			pbData				[byte-ptr!]
			cbData				[integer!]
			dwFlag				[integer!]
			return:				[integer!]
		]
		NCryptFreeObject: "NCryptFreeObject" [
			x				[int-ptr!]
			return:			[integer!]
		]
	]
]

AcceptEx!: alias function! [
	sListenSocket			[integer!]
	sAcceptSocket			[integer!]
	lpOutputBuffer			[byte-ptr!]
	dwReceiveDataLength		[integer!]
	dwLocalAddressLength	[integer!]
	dwRemoteAddressLength	[integer!]
	lpdwBytesReceived		[int-ptr!]
	lpOverlapped			[int-ptr!]
	return:					[logic!]
]

ConnectEx!: alias function! [
	s						[integer!]
	name					[int-ptr!]
	namelen					[integer!]
	lpSendBuffer			[byte-ptr!]
	dwSendDataLength		[integer!]
	lpdwBytesSent			[int-ptr!]
	lpOverlapped			[int-ptr!]
	return:					[integer!]
]

DisconnectEx!: alias function! [
	hSocket					[integer!]
	lpOverlapped			[OVERLAPPED!]
	dwFlags					[integer!]
	reserved				[integer!]
	return:					[logic!]
]

TransmitFile!: alias function! [
	hSocket					[integer!]
	hFile					[int-ptr!]
	nNumberOfBytesToWrite	[integer!]
	nNumberOfBytesPerSend	[integer!]
	lpOverlapped			[OVERLAPPED!]
	lpTransmitBuffers		[int-ptr!]
	dwReserved				[integer!]
	return:					[logic!]
]

GetAcceptExSockaddrs!: alias function! [
	lpOutputBuffer			[byte-ptr!]
	dwReceiveDataLength		[integer!]
	dwLocalAddressLength	[integer!]
	dwRemoteAddressLength	[integer!]
	LocalSockaddr			[ptr-ptr!]
	LocalSockaddrLength		[int-ptr!]
	RemoteSockaddr			[ptr-ptr!]
	RemoteSockaddrLength	[int-ptr!]
]

