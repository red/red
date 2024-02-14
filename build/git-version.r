REBOL [
	Title:   "Get git version data"
	Author:  "Will Arp"
	File: 	 %git-version.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

context [
	out: make string! 1024
	err: make string! 1024

	git: func [cmd][
		clear out
		clear err
		unless all [
			0 = call/output/error join "git " cmd out err
			empty? err
		][
			make error! "Git command not available or failed or not in a Git repo"
		]
		copy trim/tail out
	]

	set 'git-version has [temp] [
		if all [system/version/4 = 3 not find get-env "PATH" "git"][return none]
		
		attempt [
			temp: parse git "describe --long --tags" "-"
			compose/deep [
				context [
					branch: (git "rev-parse --abbrev-ref HEAD")
					tag: (to issue! temp/1)
					ahead: (to integer! temp/2)
					date: to-local-date to date! (
						to integer! git {log -1 --pretty=format:"%ct"}
					)
					commit: (to issue! git "rev-parse HEAD")
					message: (git "log -1 --pretty=%B")
				]
			]
		]
	]
]

git-version
