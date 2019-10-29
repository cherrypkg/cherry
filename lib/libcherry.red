Red [

	Title: "LibCherry"

]

cherry: context [

	utils: context [

		get-cwd: func [] [system/options/path]

		starts-with: func [

			value [string!] "value"
			match [string!] "Matching value"

		] [

			(find value match) = value

		]

		
		format-dependency-location: func [

			location [string! url!] "URL"

		] [

			either cherry/utils/starts-with location "https://github.com" [
				
				replace (replace location "blob/" "") "https://github.com" "https://raw.githubusercontent.com"

			] [

				location

			]

		]

		get-cherry-location: func [

			path [string! file!] "Path of file / folder where cherry.red is associated"

		] [

			try [

				; dirPath: to-file rejoin [path  ".."]

				either exists? to-file rejoin [path "cherry.json"] [

					to-file rejoin [path "cherry.json"]

				] [

					cherry/utils/get-cherry-location to-file rejoin [path  "../"]

				]

			]

		]

		get-dep: func [

			location [string! url!]
			top [logic!]
			/local
				m
				mp
				data

		] [

			m: ""
			mp: "_"
			data: read to-url location

			either not top [

				replace data ["Red" thru "[" thru "]"] ""

			] [

				data: rejoin [{;cherrypkg - } location { - } now/utc {^(line)^(line)} data]

			]

			while [

				m <> mp

			] [

				mp: m
				parse data [thru "#include" thru "%" copy m thru [".reds" | ".red"]]

				if (length? m) <> 0 [
					
					replace data ["#include" thru "%" thru [".reds" | ".red"]] (cherry/utils/get-dep to-url rejoin [rejoin reverse remove reverse split-path location m] false)

				]

			]

			data

		]

	]

	add-dep: func [

		name [string!]
		location [string! url!]
		/local
			data

	] [

		data: json/decode read cherry/utils/get-cherry-location cherry/utils/get-cwd
		data/deps/(to-word name): location
		write cherry/utils/get-cherry-location cherry/utils/get-cwd json/encode data

	]

	remove-dep: func [

		name [string!]
		/local
			data

	] [

		data: json/decode read cherry/utils/get-cherry-location cherry/utils/get-cwd
		remove/key data/deps (to-word name)
		write cherry/utils/get-cherry-location cherry/utils/get-cwd json/encode data

	]

	install-dep: func [

		name [string!]
		location [string! url!]

	] [

		depsRoot: rejoin [cherry/utils/get-cherry-location cherry/utils/get-cwd "/../deps/"]
		location: to-url cherry/utils/format-dependency-location location

		make-dir to-file depsRoot
		write to-file rejoin [depsRoot name ".red"] cherry/utils/get-dep location true

	]

	uninstall-dep: func [

		name [string!]
	
	] [

		depsRoot: rejoin [cherry/utils/get-cherry-location cherry/utils/get-cwd "/../deps/"]

		make-dir to-file depsRoot
		delete to-file rejoin [depsRoot name ".red"]
		
	]

]
