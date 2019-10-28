Red [

	Title: "Cherry Package Manager"

]

#include %../deps/json.red

#include %../lib/libcherry.red

args: split system/script/args " "

load-json: :json/decode
to-json: :json/encode

switch args/1 [

	; "init" [

	; 	id: ask rejoin ["id (" replace last split-path cherry/utils/cwd "/" "" "): "]
	; 	if (length? id) = 0 [id: replace last split-path cherry/utils/cwd "/" ""]
	
	; 	name: ask rejoin ["name (" id "): "]
	; 	if (length? name) = 0 [name: id]

	; ]

	"install" [
		
		json: load-json read cherry/utils/get-cherry-location cherry/utils/get-cwd

		foreach name keys-of json/deps [

			location: json/deps/(name)
			name: pick split to-string last split-path to-url location "." 1

			cherry/add-dep name location
			cherry/install-dep name location

		]

	]

	"add" [

		location: args/2
		name: pick split to-string last split-path to-url location "." 1

		cherry/add-dep name location
		cherry/install-dep name location

		print rejoin ["Installed `" location "` as '" name "' successfully!"]

	]

	"remove" [

		cherry/remove-dep args/2
		cherry/uninstall-dep args/2

	]

]
