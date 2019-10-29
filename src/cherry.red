Red [

	Title: "Cherry Package Manager"
	Needs: 'View

]

#include %../deps/json.red
#if config [
	
	#include %../deps/input.red
	
]
#include %../lib/libcherry.red
; #include %environment/console/CLI/input.red

args: split system/script/args " "

switch args/1 [

	"init" [

		id: ask rejoin ["id (" replace last split-path cherry/utils/get-cwd "/" "" "): "]
		if (length? id) = 0 [id: replace last split-path cherry/utils/get-cwd "/" ""]
	
		name: ask rejoin ["name (" id "): "]
		if (length? name) = 0 [name: id]

	]

	"install" [
		
		either error? cherry/utils/get-cherry-location cherry/utils/get-cwd [

			print "Error: cherry.json not found."

		] [

			data: json/decode read cherry/utils/get-cherry-location cherry/utils/get-cwd

			foreach name keys-of data/deps [

				location: data/deps/(name)
				name: pick split to-string last split-path to-url location "." 1

				cherry/add-dep name location
				cherry/install-dep name location

			]

		]

	]

	"add" [

		either error? cherry/utils/get-cherry-location cherry/utils/get-cwd [

			print "Error: cherry.json not found."

		] [

			location: args/2
			name: pick split to-string last split-path to-url location "." 1

			cherry/add-dep name location
			cherry/install-dep name location

			print rejoin ["Installed `" location "` as '" name "' successfully!"]

		]

	]

	"remove" [

		either error? cherry/utils/get-cherry-location cherry/utils/get-cwd [

			print "Error: cherry.json not found."

		] [

			cherry/remove-dep args/2
			cherry/uninstall-dep args/2

		]

	]

]
