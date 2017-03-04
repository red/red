Red [
	Title:   "Red .NET bridge HelloWorld"
	Author:  "Xie Qingtian"
	File: 	 %test-wpf.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %bridge.red

clr-start

clr-do ['System/Console/WriteLine "{0}{1} -- {2}" "Hello" ".NET" 123]

clr-load 'WPF/PresentationFramework.dll

btn:   clr-new [System.Windows.Controls.Button]
clr-do [btn/Height: 48]
clr-do [btn/Width: 100]
clr-do [btn/Content: "OK"]

area:  clr-new [System.Windows.Controls.TextBox]
clr-do [area/AcceptsReturn: yes]
clr-do [area/Height: 450]
clr-do [area/AppendText "WPF window created by Red.^M^/^M^/"]
clr-do [area/AppendText "Red生成的.NET WPF窗口。"]

panel: clr-new [System.Windows.Controls.StackPanel]
container: clr-do [:panel/Children]
clr-do [container/Add btn]
clr-do [container/Add area]

win:   clr-new [System.Windows.Window]
clr-do [win/Title: "Red WPF Window"]
clr-do [win/Height: 500]
clr-do [win/Width:  500]
clr-do [win/Content: panel]
clr-do [win/ShowDialog]

clr-stop

probe "end"