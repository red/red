Red [
	Title:   "Red .NET bridge"
	Author:  "Xie Qingtian"
	File: 	 %test-svg.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %bridge.red

clr-start

clr-load 'WPF/PresentationFramework.dll

;-- Lib download from http://sharpvectors.codeplex.com/
clr-load %./SvgConverter/SharpVectors.Converters.dll
clr-load %./SvgConverter/SharpVectors.Rendering.Wpf.dll

settings: clr-new [SharpVectors.Renderers.Wpf.WpfDrawingSettings]
clr-do [settings/IncludeRuntime: yes]
clr-do [settings/TextAsGeometry: no]

converter: clr-new [SharpVectors.Converters.FileSvgReader settings]
drawing:   clr-do [converter/Read "test.svg"]

image: clr-new [System.Windows.Media.DrawingImage drawing]

svgImage: clr-new [System.Windows.Controls.Image]
clr-do [svgImage/Source: image]

win:   clr-new [System.Windows.Window]
clr-do [win/Title: "Red SVG Viewer"]
clr-do [win/Height: 500]
clr-do [win/Width:  500]
clr-do [win/Content: svgImage]
clr-do [win/ShowDialog]

clr-stop

probe "end"