Red [
	Title:   "Red .NET bridge"
	Author:  "Qingtian Xie"
	File: 	 %bridge.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#system [
	#if dev-mode? = yes [
		#include %../../runtime/platform/COM.reds
	]

	CLSID_CLRMetaHost:	  [9280188Dh 48670E8Eh A87F0CB3h DEE88438h]
	IID_ICLRMetaHost:	  [D332DB9Eh 4125B9B3h 48A10782h 1632F584h]
	CLSID_CorRuntimeHost: [CB2F6723h 11D2AB3Ah C000409Ch 3E0AA34Fh]
	IID_CorRuntimeHost:	  [CB2F6722h 11D2AB3Ah C000409Ch 3E0AA34Fh]
	IID_ICLRRuntimeInfo:  [BD39D1D2h 486ABA2Fh B0B4B089h 916846CBh]
	IID_IAppDomain:		  [05F696DCh 36632B29h 38C48BADh 13A7F29Ch]

	#define BindingFlags_Instance		4
	#define BindingFlags_Static			8
	#define BindingFlags_Public			16
	#define BindingFlags_InvokeMethod	256
	#define BindingFlags_CreateInstance 512
    #define BindingFlags_GetProperty	4096
    #define BindingFlags_SetProperty	8192

	GetRuntime!: alias function! [
		this		[this!]
		version		[c-string!]
		riid		[int-ptr!]
		runtime		[int-ptr!]
		return:		[integer!]
	]

	EnumerateInstalledRuntimes!: alias function! [
		this		[this!]
		enum		[int-ptr!]
		return:		[integer!]
	]

	InvokeMember_3!: alias function! [
		this		[this!]
		name		[byte-ptr!]
		attrs		[integer!]
		binder		[int-ptr!]
		data1		[integer!]
		data2		[integer!]
		data3		[integer!]
		data4		[integer!]
		args		[int-ptr!]
		retVal		[tagVARIANT]
		return:		[integer!]
	]

	ToString!: alias function! [this [this!] name [int-ptr!] return: [integer!]]

	ICLRMetaHost: alias struct! [
		QueryInterface					 [QueryInterface!]
		AddRef							 [AddRef!]
		Release							 [Release!]
		GetRuntime						 [GetRuntime!]
		GetVersionFromFile				 [integer!]
		EnumerateInstalledRuntimes		 [EnumerateInstalledRuntimes!]
		EnumerateLoadedRuntimes			 [integer!]
		RequestRuntimeLoadedNotification [integer!]
		QueryLegacyV2RuntimeBinding		 [integer!]
		ExitProcess						 [function! [this [this!] exitCode [integer!] return: [integer!]]]
	]

	ICLRRuntimeInfo: alias struct! [
		QueryInterface					[QueryInterface!]
		AddRef							[AddRef!]
		Release							[Release!]
		GetVersionString				[function! [this [this!] buffer [byte-ptr!] size [int-ptr!] return: [integer!]]]
		GetRuntimeDirectory				[function! [this [this!] buffer [byte-ptr!] size [int-ptr!] return: [integer!]]]
		IsLoaded						[function! [this [this!] process [integer!] loaded [int-ptr!] return: [integer!]]]
		LoadErrorString					[integer!]
		LoadLibrary						[function! [this [this!] dllname [c-string!] module [int-ptr!] return: [integer!]]]
		GetProcAddress					[integer!]
		GetInterface					[function! [this [this!] rclsid [int-ptr!] riid [int-ptr!] Unk [int-ptr!] return: [integer!]]]
		IsLoadable						[function! [this [this!] loadable [int-ptr!] return: [integer!]]]
		SetDefaultStartupFlags			[integer!]
		GetDefaultStartupFlags			[integer!]
		BindAsLegacyV2Runtime			[integer!]
		IsStarted						[function! [this [this!] bStarted [int-ptr!] flags [int-ptr!] return: [integer!]]]
	]

	ICorRuntimeHost: alias struct! [
		QueryInterface					[QueryInterface!]
		AddRef							[AddRef!]
		Release							[Release!]
		CreateLogicalThreadState		[integer!]
		DeleteLogicalThreadState		[integer!]
		SwitchInLogicalThreadState		[integer!]
		SwitchOutLogicalThreadState		[integer!]
		LocksHeldByLogicalThread		[integer!]
		MapFile							[integer!]
		GetConfiguration				[integer!]
		Start							[function! [this [this!] return: [integer!]]]
		Stop							[function! [this [this!] return: [integer!]]]
		CreateDomain					[function! [this [this!] name [c-string!] id [integer!] domain [int-ptr!] return: [integer!]]]
		GetDefaultDomain				[function! [this [this!] domain [int-ptr!] return: [integer!]]]
		EnumDomains						[integer!]
		NextDomain						[integer!]
		CloseEnum						[integer!]
		CreateDomainEx					[integer!]
		CreateDomainSetup				[integer!]
		CreateEvidence					[integer!]
		UnloadDomain					[function! [this [this!] domain [integer!] return: [integer!]]]
		CurrentDomain					[function! [this [this!] domain [int-ptr!] return: [integer!]]]
	]

	_AppDomain: alias struct! [
		QueryInterface					[QueryInterface!]			;-- IUnknown
		AddRef							[AddRef!]
		Release							[Release!]
		GetTypeInfoCount				[integer!]					;-- IDispatch
		GetTypeInfo						[integer!]
		GetIDsOfNames					[integer!]
		Invoke							[integer!]
		ToString						[function! [this [this!] name [int-ptr!] return: [integer!]]]
		Equals							[integer!]
		GetHashCode						[integer!]
		GetType							[integer!]
		InitializeLifetimeService		[integer!]
		GetLifetimeService				[integer!]
		Evidence						[integer!]
		add_DomainUnload				[integer!]
		remove_DomainUnload				[integer!]
		add_AssemblyLoad				[integer!]
		remove_AssemblyLoad				[integer!]
		add_ProcessExit					[integer!]
		remove_ProcessExit				[integer!]
		add_TypeResolve					[integer!]
		remove_TypeResolve				[integer!]
		add_ResourceResolve				[integer!]
		remove_ResourceResolve			[integer!]
		add_AssemblyResolve				[integer!]
		remove_AssemblyResolve			[integer!]
		add_UnhandledException			[integer!]
		remove_UnhandledException		[integer!]
		DefineDynamicAssembly			[integer!]
		DefineDynamicAssembly_2			[integer!]
		DefineDynamicAssembly_3			[integer!]
		DefineDynamicAssembly_4			[integer!]
		DefineDynamicAssembly_5			[integer!]
		DefineDynamicAssembly_6			[integer!]
		DefineDynamicAssembly_7			[integer!]
		DefineDynamicAssembly_8			[integer!]
		DefineDynamicAssembly_9			[integer!]
		CreateInstance					[integer!]
		CreateInstanceFrom				[integer!]
		CreateInstance_2				[integer!]
		CreateInstanceFrom_2			[integer!]
		CreateInstance_3				[integer!]
		CreateInstanceFrom_3			[integer!]
		Load							[integer!]
		Load_2							[function! [this [this!] name [byte-ptr!] retVal [int-ptr!] return: [integer!]]]
		Load_3							[integer!]
		Load_4							[integer!]
		Load_5							[integer!]
		Load_6							[integer!]
		Load_7							[integer!]
		ExecuteAssembly					[integer!]
		ExecuteAssembly_2				[integer!]
		ExecuteAssembly_3				[integer!]
		FriendlyName					[function! [this [this!] name [int-ptr!] return: [integer!]]]
		BaseDirectory					[integer!]
		RelativeSearchPath				[integer!]
		ShadowCopyFiles					[integer!]
		GetAssemblies					[function! [this [this!] retVal [int-ptr!] return: [integer!]]]
		AppendPrivatePath				[integer!]
		ClearPrivatePath				[integer!]
		SetShadowCopyPath				[integer!]
		ClearShadowCopyPath				[integer!]
		SetCachePath					[integer!]
		SetData							[integer!]
		GetData							[integer!]
		SetAppDomainPolicy				[integer!]
		SetThreadPrincipal				[integer!]
		SetPrincipalPolicy				[integer!]
		DoCallBack						[integer!]
		DynamicDirectory				[integer!]
	]

	_Assembly: alias struct! [
		QueryInterface					[QueryInterface!]			;-- IUnknown
		AddRef							[AddRef!]
		Release							[Release!]
		GetTypeInfoCount				[integer!]					;-- IDispatch
		GetTypeInfo						[integer!]
		GetIDsOfNames					[integer!]
		Invoke							[integer!]
		ToString						[function! [this [this!] name [int-ptr!] return: [integer!]]]
		Equals							[integer!]
		GetHashCode						[integer!]
		GetType							[function! [this [this!] out [int-ptr!] return: [integer!]]]
		CodeBase						[integer!]
		EscapedCodeBase					[integer!]
		GetName							[integer!]
		GetName_2						[integer!]
		FullName						[function! [this [this!] name [int-ptr!] return: [integer!]]]
		EntryPoint						[integer!]
		GetType_2						[function! [this [this!] name [byte-ptr!] out [int-ptr!] return: [integer!]]]
		GetType_3						[integer!]
		GetExportedTypes				[integer!]
		GetTypes						[integer!]
		GetManifestResourceStream		[integer!]
		GetManifestResourceStream_2		[integer!]
		GetFile							[integer!]
		GetFiles						[integer!]
		GetFiles_2						[integer!]
		GetManifestResourceNames		[integer!]
		GetManifestResourceInfo			[integer!]
		Location						[ToString!]
		Evidence						[integer!]
		GetCustomAttributes				[integer!]
		GetCustomAttributes_2			[integer!]
		IsDefined						[integer!]
		GetObjectData					[integer!]
		add_ModuleResolve				[integer!]
		remove_ModuleResolve			[integer!]
		GetType_4						[integer!]
		GetSatelliteAssembly			[integer!]
		GetSatelliteAssembly_2			[integer!]
		LoadModule						[integer!]
		LoadModule_2					[integer!]
		CreateInstance					[integer!]
		CreateInstance_2				[integer!]
		CreateInstance_3				[integer!]
		GetLoadedModules				[integer!]
		GetLoadedModules_2				[integer!]
		GetModules						[integer!]
		GetModules_2					[integer!]
		GetModule						[integer!]
		GetReferencedAssemblies			[integer!]
		GlobalAssemblyCache				[integer!]
	]

	_Type: alias struct! [
		QueryInterface					[QueryInterface!]			;-- IUnknown
		AddRef							[AddRef!]
		Release							[Release!]
		GetTypeInfoCount				[integer!]					;-- IDispatch
		GetTypeInfo						[integer!]
		GetIDsOfNames					[integer!]
		Invoke							[integer!]
		ToString						[ToString!]
		Equals							[integer!]
		GetHashCode						[integer!]
		GetType							[function! [this [this!] out [int-ptr!] return: [integer!]]]
		MemberType						[integer!]
		name							[ToString!]
		DeclaringType					[integer!]
		ReflectedType					[integer!]
		GetCustomAttributes				[integer!]
		GetCustomAttributes_2			[integer!]
		IsDefined						[integer!]
		Guid							[integer!]
		Module							[integer!]
		Assembly						[integer!]
		TypeHandle						[integer!]
		FullName						[ToString!]
		Namespace						[ToString!]
		AssemblyQualifiedName			[integer!]
		GetArrayRank					[integer!]
		BaseType						[integer!]
		GetConstructors					[integer!]
		GetInterface					[integer!]
		GetInterfaces					[integer!]
		FindInterfaces					[integer!]
		GetEvent						[integer!]
		GetEvents						[integer!]
		GetEvents_2						[integer!]
		GetNestedTypes					[integer!]
		GetNestedType					[integer!]
		GetMember						[integer!]
		GetDefaultMembers				[integer!]
		FindMembers						[integer!]
		GetElementType					[integer!]
		IsSubclassOf					[integer!]
		IsInstanceOfType				[integer!]
		IsAssignableFrom				[integer!]
		GetInterfaceMap					[integer!]
		GetMethod						[integer!]
		GetMethod_2						[integer!]
		GetMethods						[integer!]
		GetField						[integer!]
		GetFields						[integer!]
		GetProperty						[integer!]
		GetProperty_2					[integer!]
		GetProperties					[integer!]
		GetMember_2						[integer!]
		GetMembers						[integer!]
		InvokeMember					[integer!]
		UnderlyingSystemType			[integer!]
		InvokeMember_2					[integer!]
		InvokeMember_3					[InvokeMember_3!]
		GetConstructor					[integer!]
		GetConstructor_2				[integer!]
		GetConstructor_3				[integer!]
		GetConstructors_2				[integer!]
		TypeInitializer					[integer!]
		GetMethod_3						[integer!]
		GetMethod_4						[integer!]
		GetMethod_5						[integer!]
		GetMethod_6						[integer!]
		GetMethods_2					[integer!]
		GetField_2						[integer!]
		GetFields_2						[integer!]
		GetInterface_2					[integer!]
		GetEvent_2						[integer!]
		GetProperty_3					[integer!]
		GetProperty_4					[integer!]
		GetProperty_5					[integer!]
		GetProperty_6					[integer!]
		GetProperty_7					[integer!]
		GetProperties_2					[integer!]
		GetNestedTypes_2				[integer!]
		GetNestedType_2					[integer!]
		GetMember_3						[integer!]
		GetMembers_2					[integer!]
		Attributes						[integer!]
		IsNotPublic						[integer!]
		IsPublic						[integer!]
		IsNestedPublic					[integer!]
		IsNestedPrivate					[integer!]
		IsNestedFamily					[integer!]
		IsNestedAssembly				[integer!]
		IsNestedFamANDAssem				[integer!]
		IsNestedFamORAssem				[integer!]
		IsAutoLayout					[integer!]
		IsLayoutSequential				[integer!]
		IsExplicitLayout				[integer!]
		IsClasstval						[integer!]
		IsInterface						[integer!]
		IsValueType						[integer!]
		IsAbstract						[integer!]
		IsSealed						[integer!]
		IsEnum							[integer!]
		IsSpecialName					[integer!]
		IsImport						[integer!]
		IsSerializable					[integer!]
		IsAnsiClass						[integer!]
		IsUnicodeClass					[integer!]
		IsAutoClass						[integer!]
		IsArray							[integer!]
		IsByRef							[integer!]
		IsPointer						[integer!]
		IsPrimitive						[integer!]
		IsCOMObject						[integer!]
		HasElementType					[integer!]
		IsContextful					[integer!]
		IsMarshalByRef					[integer!]
		Equals_2						[integer!]
	]

	#import [
	"kernel32.dll" stdcall [
		LoadLibraryA: "LoadLibraryA" [
			lpFileName	[c-string!]
			return:		[integer!]
		]
		GetProcAddress: "GetProcAddress" [
			hModule		[integer!]
			lpProcName	[c-string!]
			return:		[integer!]
		]
	]]

	clrMetahost:	as this! 0
	clrRuntime:		as this! 0
	clrDomain:		as this! 0
	clrMetaClass:	0

	clr-pick-runtime: func [
		metahost	[this!]
		return:		[this!]
		/local
			host	[ICLRMetaHost]
			enum	[this!]
			runtime [this!]
			spRT	[this!]
			len		[integer!]
			e		[integer!]
			rt		[integer!]
			rt-host [integer!]
			start?	[integer!]
			flags	[integer!]
			buf		[byte-ptr!]
			IEnum	[IEnumUnknown]
			IRT		[ICLRRuntimeInfo]
			ICorRT	[ICorRuntimeHost]
			unk		[IUnknown]
	][
		host: as ICLRMetaHost metahost/vtbl

		e: 0
		host/EnumerateInstalledRuntimes metahost :e
		if zero? e [probe "No .NET installed in this system" return null]

		buf: allocate 64 * 2
		enum: as this! e
		IEnum: as IEnumUnknown enum/vtbl
		while [
			rt: 0
			zero? IEnum/Next enum 1 as interface! :rt null
		][
			runtime: as this! rt
			IRT: as ICLRRuntimeInfo runtime/vtbl
			len: 64
			IRT/GetVersionString runtime buf :len
		]

		start?: 0 flags: 0
		if 0 <> IRT/IsStarted runtime :start? :flags [
			host/GetRuntime metahost as c-string! buf IID_ICLRRuntimeInfo :rt
			runtime: as this! rt
		]
		free buf

		rt-host: 0
		IRT: as ICLRRuntimeInfo runtime/vtbl
		IRT/GetInterface runtime CLSID_CorRuntimeHost IID_CorRuntimeHost :rt-host
		spRT: as this! rt-host
		ICorRT: as ICorRuntimeHost spRT/vtbl

		if zero? start? [
			if 0 <> ICorRT/Start spRT [
				probe "Could not start runtime" return null
			]
		]
		spRT
	]

	clr-get-domain: func [
		runtime		[this!]
		return:		[this!]
		/local
			rt		[ICorRuntimeHost]
			unk		[IUnknown]
			hr		[integer!]
			pv		[integer!]
			this	[this!]
	][
		pv: 0
		rt: as ICorRuntimeHost runtime/vtbl
		hr: rt/GetDefaultDomain runtime :pv
		if COM_FAILED(hr) [
			probe "Could not get default app domain"
			return null
		]

		this: as this! pv
		unk: as IUnknown this/vtbl
		pv: 0
		unk/QueryInterface this IID_IAppDomain as interface! :pv
		as this! pv
	]

	clr-metahost-init: func [
		return:		[this!]
		/local
			dll		[integer!]
			host	[integer!]
			addr	[integer!]
			CLRCreateInstance
	][
		dll: LoadLibraryA "mscoree.dll"
		if zero? dll [probe "Failed to load mscoree.dll" return null]

		addr: GetProcAddress dll "CLRCreateInstance"
		if zero? addr [probe "Failed to load CLRCreateInstance from mscoree.dll" return null]

		CLRCreateInstance: as function! [
			clsid	[int-ptr!]
			riid	[int-ptr!]
			p-int	[int-ptr!]
			return: [integer!]
		] addr

		host: 0
		if 0 <> CLRCreateInstance CLSID_CLRMetaHost IID_ICLRMetaHost :host [
			probe "Could not create CLRMetaHost"
			return null
		]
		as this! host
	]

	_clr-stop: func [/local unk [IUnknown]][
		COM_SAFE_RELEASE(unk clrDomain)
		COM_SAFE_RELEASE(unk clrRuntime)
		COM_SAFE_RELEASE(unk clrMetahost)
	]
]

~classes: 	make block! 20
;-- ~classes: [
;-- 	class.name [
;--			obj-id | none
;--			assembly-id
;--			class-id
;--			class-name
;--		]
;--		...
;-- ]

clr-base-path:  none
~class: 		none

clr-fetch-class: func [name [word!] /local class][
	class: reduce [
		none											;-- instance id (for objects only)
		none											;-- assembly
		none											;-- class id
		name											;-- class name (original form)
	]
	unless clr-search-class form name class [
		print ["Error: not found class" form name]
		exit
	]
	append ~classes name								;-- original class name
	append/only ~classes class
	class
]

clr-search-class: routine [
	name    [string!]
	blk		[block!]
	return: [logic!]
	/local
		size	[integer!]
		assems	[integer!]
		str		[c-string!]
		len		[integer!]
		pAms	[int-ptr!]
		ret		[integer!]
		class	[this!]
		am		[this!]
		IA		[_Assembly]
		domain	[_AppDomain]
		IType	[_Type]
		bstr-t	[byte-ptr!]
		value	[red-value!]
][
	domain: as _AppDomain clrDomain/vtbl
	assems: 0
	domain/GetAssemblies clrDomain :assems
	pAms: as int-ptr! assems
	pAms: as int-ptr! pAms/4						;-- pvData
	size: pAms/5
	am: as this! pAms/1

	len: -1
	bstr-t: SysAllocString unicode/to-utf16-len as red-string! name :len no
	ret: 0

	loop size [
		IA: as _Assembly am/vtbl
		IA/GetType_2 am bstr-t :ret
		either zero? ret [
			pAms: pAms + 1
			am: as this! pAms/1
		][break]
	]
	either zero? ret [false][
		value: (as red-value! block/rs-head blk) + 1
		integer/make-at as red-value! value as-integer am
		integer/make-at as red-value! value + 1 ret
		true
	]
]

clr-get-base-path: routine [
	return: [string!]
	/local
		assems	[integer!]
		plen	[int-ptr!]
		path	[integer!]
		len		[integer!]
		pAms	[int-ptr!]
		ret		[integer!]
		class	[this!]
		am		[this!]
		IA		[_Assembly]
		domain	[_AppDomain]
		value	[red-string!]
][
	domain: as _AppDomain clrDomain/vtbl
	assems: 0
	domain/GetAssemblies clrDomain :assems
	pAms: as int-ptr! assems
	pAms: as int-ptr! pAms/4						;-- pvData
	am: as this! pAms/1
	IA: as _Assembly am/vtbl
	path: 0
	IA/Location am :path
	
	plen: as int-ptr! path - 4
	value: string/load as c-string! path plen/value >> 1 UTF-16LE
	as red-string! SET_RETURN(value)
]

_clr-setup: routine [
	return:  [logic!]
	/local
		domain	[_AppDomain]
		name	[byte-ptr!]
		wpf		[integer!]
][
	clrMetahost: clr-metahost-init
	if null? clrMetahost [return false]

	clrRuntime: clr-pick-runtime clrMetahost
	if null? clrRuntime [return false]

	clrDomain: clr-get-domain clrRuntime
	clrDomain <> null

	domain: as _AppDomain clrDomain/vtbl

	;wpf: 0
	;;@@ Hard-coded, find a better way to load it
	;name: SysAllocString #u16 "PresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
	;domain/Load_2 clrDomain name :wpf
	;SysFreeString name
	yes
]

_clr-set-meta-class: routine [
	class-id [integer!]
][
	clrMetaClass: class-id
]

clr-invoke: routine [
	blk		 [block!]
	method	 [string!]
	args     [block!]
	type	 [integer!]
	/local
		value	[red-value!]
		bool	[red-logic!]
		int		[red-integer!]
		flt		[red-float!]
		pf		[pointer! [float!]]
		size	[integer!]
		arr		[tagVARIANT]
		parr	[int-ptr!]
		str		[c-string!]
		len		[integer!]
		class	[this!]
		IType	[_Type]
		bstr-m	[byte-ptr!]
		d4		[integer!]
		d3		[integer!]
		d2		[integer!]
		d1		[integer!]
		var		[tagVARIANT]
		data4	[integer!]
		data3	[integer!]
		data2	[integer!]
		data1	[integer!]
		flags	[integer!]
		result	[tagVARIANT]
		Unk		[IUnknown]
][
	value: block/rs-head args
	size:  block/rs-length? args

	parr: SafeArrayCreateVector VT_VARIANT 0 size
	arr: as tagVARIANT parr/4

	loop size [
		switch TYPE_OF(value) [
			TYPE_BLOCK [				;-- object
				int: as red-integer! block/rs-head as red-block! value
				arr/data1: VT_UNKNOWN
				arr/data3: int/value
			]
			TYPE_INTEGER [
				int: as red-integer! value
				arr/data1: VT_I4
				arr/data3: int/value
			]
			TYPE_CHAR [
				int: as red-integer! value
				arr/data1: VT_INT
				arr/data3: int/value
			]
			TYPE_STRING [
				len: -1
				str: unicode/to-utf16-len as red-string! value :len no
				arr/data1: VT_BSTR
				arr/data3: as-integer SysAllocString str
			]
			TYPE_FLOAT [
				flt: as red-float! value
				arr/data1: VT_R8
				pf: (as pointer! [float!] arr) + 1
				pf/value: flt/value
			]
			TYPE_LOGIC [
				bool: as red-logic! value
				arr/data1: VT_BOOL
				arr/data3: either bool/value [-1][0]
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(value)]
			]
		]
		arr: arr + 1
		value: value + 1
	]

	data1: 0 data2: 0 data3: 0 data4: 0
	result: as tagVARIANT :data1
	either TYPE_OF(method) = TYPE_NONE [
		str: null
		bstr-m: SysAllocString #u16 ""
	][
		len: -1
		str: unicode/to-utf16-len method :len no
		bstr-m: SysAllocString str
	]

	flags: switch type [
		1 6 [BindingFlags_Instance or BindingFlags_InvokeMethod]
		2 [BindingFlags_Static or BindingFlags_InvokeMethod]
		3 [BindingFlags_SetProperty or BindingFlags_Instance]
		4 [BindingFlags_GetProperty or BindingFlags_Instance]
		5 [BindingFlags_CreateInstance or BindingFlags_Instance]
	]

	d1: VT_UNKNOWN d2: 0 d3: 0 d4: 0
	int: as red-integer! block/rs-head blk
	if TYPE_OF(int) = TYPE_INTEGER [d3: int/value]

	int: int + 2
	class: as this! int/value
	IType: as _Type class/vtbl

	IType/InvokeMember_3
		class
		bstr-m
		flags or BindingFlags_Public
		null
		d1 d2 d3 d4
		parr
		result

	SafeArrayDestroy as-integer parr
	SysFreeString bstr-m

	blk/header: TYPE_NONE
	flags: data1 and FFFFh
	if all [flags = VT_UNKNOWN type = 6][		;-- get object's type
		class: as this! data3
		IType: as _Type class/vtbl
		data3: 0
		IType/ToString class :data3
		flags: VT_BSTR
	]
	switch flags [				;-- return value's type
		VT_UNKNOWN [			;-- @@ object
			either type = 5 [	;-- clr-new object		
				value: as red-value! blk
			][					;-- return a block! (CLR object -> Red block)
				block/make-at blk 4
				value: ALLOC_TAIL(blk)
				none/make-in blk
				integer/make-in blk clrMetaClass
				none/make-in blk
			]
			integer/make-at value data3
		]
		VT_NULL
		VT_EMPTY [0]
		VT_BSTR  [
			parr: as int-ptr! data3 - 4
			string/load-at as c-string! data3 parr/value >> 1 as red-value! blk UTF-16LE
		]
		VT_BOOL  [
			bool: as red-logic! blk
			bool/header: TYPE_LOGIC
			bool/value: as logic! data3
		]
		VT_ERROR [probe "error"]
		VT_R4					;-- float
		VT_R8	 [0]			;-- double
		default  [
			integer/make-at as red-value! blk data3
		]
	]
	SET_RETURN(blk)
]

;====== Public API ======

clr-verbose: 0

clr-start: func [
	return:  [logic!]
	/local
		result meta-class
][
	result: _clr-setup
	meta-class: clr-fetch-class 'System.Object
	_clr-set-meta-class meta-class/3
	clr-base-path: head clear find/last/tail clr-get-base-path #"\"
	result
]

clr-stop: routine [][
	_clr-stop
]

clr-load: function [
	path	[file! word! path!]
	return:	[logic!]
][
	file: either file? path [
		to-local-file/full path
	][
		rejoin [clr-base-path to-string path]
	]

	to logic! clr-do ['System/Reflection/Assembly/LoadFrom file]
]

clr-get-class: func [name [word!]][
	if clr-verbose > 0 [print ["clr-get-class:" name]]
	
	any [
		select/skip ~classes name 2
		clr-fetch-class name
	]
]

clr-new: func [spec [block!] /local name class id obj method][
	if clr-verbose > 0 [print ["clr-new:" mold spec]]
	
	if class: clr-get-class name: spec/1 [
		id: clr-invoke class none reduce next spec 5
		if id = 0 [
			print ["Error: cannot instantiate object from class" form name]
			exit
		]
	]
	obj: copy class
	obj/1: id
	obj
]

clr-do: function [spec [block!]][
	if clr-verbose > 0 [print ["clr-do:" mold spec]]

	obj: spec/1
	type: 0
	case [
		path? obj [								;-- instance method
			method: obj/2
			obj: get obj/1
			unless integer? obj/1 [
				print ["Error:" form :obj "is not a clr object!"]
				exit
			]
			type: 1
		]
		lit-path? obj [							;-- static method
			obj: copy obj
			method: last obj
			remove back tail obj
			obj: to-string to-path obj
			replace/all obj #"/" #"."
			obj: clr-get-class to-word obj
			type: 2
		]
		set-path? obj [							;-- set property
			method: obj/2
			obj: get obj/1
			type: 3
		]
		get-path? obj [							;-- get property
			method: obj/2
			obj: get obj/1
			type: 4
		]
		true [
			print ["Error: object/method or namespace.class.method expected as first argument in " mold spec]
			exit
		]
	]

	args: reduce next spec
	obj: clr-invoke obj form method args type

	if block? obj [
		name: clr-invoke obj "GetType" [] 6
		cls: clr-fetch-class to-word name
		obj/3: cls/3
	]
	obj
]