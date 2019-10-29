;cherrypkg - https://raw.githubusercontent.com/red/red/master/environment/console/CLI/input.red - 29-Oct-2019/0:36:39

Red [
	Title:	"INPUT prototype for Unix platforms"
	Author: "Nenad Rakocevic"
	File: 	%input.red
	Tabs: 	4
	Rights: "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {
		Freely inspired by linenoise fork from msteveb:
		https://github.com/msteveb/linenoise/blob/master/linenoise.c
	}
]

;;@@ Temporary patch to allow inclusion in user code.
unless system/console [
	system/console: context [
		history: make block! 200
		size: 80x50										;-- default size for dump/help funcs
	]
]
;; End patch



red-complete-ctx: context [

	has-common-part?: no

	common-substr: func [
		"Internal Use Only"
		blk		[block!]
		/local a b
	][
		has-common-part?: either 1 < length? blk [
			sort blk
			a: first blk
			b: last blk
			while [
				all [
					not tail? a
					not tail? b
					find/match a first b
				]
			][
				a: next a
				b: next b
			]
			insert blk copy/part head a a
			yes
		][no]
	]

	red-complete-path: func [
		"Internal Use Only"
		str		 [string!]
		console? [logic!]
		/local s result word w1 ptr words first? sys-word w
	][
		result: make block! 4
		first?: yes
		s: ptr: str
		while [ptr: find str #"/"][
			word: attempt [to word! copy/part str ptr]
			if none? word [return result]
			either first? [
				set/any 'w1 get/any word
				first?: no
			][
				if w1: in :w1 word [set/any 'w1 get/any w1]
			]
			str: either object? :w1 [next ptr][""]
		]
		case [
			any [function? :w1 action? :w1 native? :w1 routine? :w1] [
				word: find/last/tail s #"/"
				words: make block! 4
				foreach w spec-of w1 [
					if refinement? w [append words w]
				]
			]
			object? :w1 [
				word: str
				words: words-of w1
			]
			words: select system/catalog/accessors type?/word :w1 [
				word: find/last/tail s #"/"
			]
		]
		if words [
			foreach w words [
				sys-word: form w
				if any [empty? word find/match sys-word word] [
					append result sys-word
				]
			]
		]

		if console? [common-substr result]
		if any [1 = length? result has-common-part?] [
			poke result 1 append copy/part s word result/1
		]
		result
	]

	red-complete-file: func [
		"Internal Use Only"
		str		 [string!]
		console? [logic!]
		/local file result path word f files replace? change?
	][
		result: make block! 4
		file: to file! next str
		replace?: no

		either word: find/last/tail str #"/" [
			path: to file! copy/part next str word
			unless exists? path [return result]
			replace?: yes
		][
			path: %./
			word: file
		]

		files: read path
		foreach f files [
			if any [empty? word find/match f word] [
				append result f
			]
		]
		if console? [common-substr result]
		if any [1 = length? result has-common-part?] [
			poke result 1 append copy/part str either replace? [word][1] result/1
		]
		result
	]

	complete-input: func [
		str		 [string!]			;-- should be `tail str`
		console? [logic!]
		/local
			word ptr result sys-word delim? len insert?
			start end delimiters d w change?
	][
		has-common-part?: no
		result: make block! 4
		delimiters: [#"^-" #" " #"[" #"(" #":" #"'" #"{"]
		delim?: no
		insert?: not tail? str
		len: (index? str) - 1
		end: str
		ptr: str: head str
		foreach d delimiters [
			word: find/last/tail/part str d len
			if all [word (index? ptr) < (index? word)] [ptr: word]
		]
		either head? ptr [start: str][start: ptr delim?: yes]
		word: copy/part start end
		unless empty? word [
			case [
				all [
					#"%" = word/1
					1 < length? word
				][
					append result 'file
					append result red-complete-file word console?
				]
				all [
					#"/" <> word/1
					ptr: find word #"/"
					#" " <> pick ptr -1
				][
					append result 'path
					append result red-complete-path word console?
				]
				true [
					append result 'word
					foreach w words-of system/words [
						if value? w [
							sys-word: mold w
							if find/match sys-word word [
								append result sys-word
							]
						]
					]
					if ptr: find result word [swap next result ptr]
					if console? [common-substr next result]
				]
			]
		]
		if console? [result: next result]

		if all [console? any [has-common-part? 1 = length? result]][
			if word = result/1 [
				unless has-common-part? [clear result]
			]
			unless empty? result [
				either any [insert? delim?] [
					str: append copy/part str start result/1
					poke result 1 tail str
					if insert? [append str end]
				][
					poke result 1 tail result/1
				]
			]
		]
		result
	]

	set 'red-complete-input :complete-input			;-- alias for VS Code plug
]

#system [
	terminal: context [
	
		#enum special-key! [
			KEY_UNSET:		 -1
			KEY_NONE:		  0
			KEY_UP:			-20
			KEY_DOWN:		-21
			KEY_RIGHT:		-22
			KEY_LEFT:		-23
			KEY_END:		-24
			KEY_HOME:		-25
			KEY_INSERT:		-26
			KEY_DELETE:		-27
			KEY_PAGE_UP:	-28
			KEY_PAGE_DOWN:	-29
			KEY_ESC:		-30
			KEY_CTRL_A:		  1
			KEY_CTRL_B:		  2
			KEY_CTRL_C:		  3
			KEY_CTRL_D:		  4
			KEY_CTRL_E:		  5
			KEY_CTRL_F:		  6
			KEY_CTRL_H:		  8
			KEY_TAB:		  9
			KEY_CTRL_K:		 11
			KEY_CTRL_L:		 12
			KEY_ENTER:		 13
			KEY_CTRL_N:		 14
			KEY_CTRL_P:		 16
			KEY_CTRL_T:		 20
			KEY_CTRL_U:		 21
			KEY_CTRL_W:		 23
			KEY_ESCAPE:		 27
			KEY_BACKSPACE:	127
		]
		
		
combining-table: [
	0300h 036Fh 0483h 0486h 0488h 0489h
	0591h 05BDh 05BFh 05BFh 05C1h 05C2h
	05C4h 05C5h 05C7h 05C7h 0600h 0603h
	0610h 0615h 064Bh 065Eh 0670h 0670h
	06D6h 06E4h 06E7h 06E8h 06EAh 06EDh
	070Fh 070Fh 0711h 0711h 0730h 074Ah
	07A6h 07B0h 07EBh 07F3h 0901h 0902h
	093Ch 093Ch 0941h 0948h 094Dh 094Dh
	0951h 0954h 0962h 0963h 0981h 0981h
	09BCh 09BCh 09C1h 09C4h 09CDh 09CDh
	09E2h 09E3h 0A01h 0A02h 0A3Ch 0A3Ch
	0A41h 0A42h 0A47h 0A48h 0A4Bh 0A4Dh
	0A70h 0A71h 0A81h 0A82h 0ABCh 0ABCh
	0AC1h 0AC5h 0AC7h 0AC8h 0ACDh 0ACDh
	0AE2h 0AE3h 0B01h 0B01h 0B3Ch 0B3Ch
	0B3Fh 0B3Fh 0B41h 0B43h 0B4Dh 0B4Dh
	0B56h 0B56h 0B82h 0B82h 0BC0h 0BC0h
	0BCDh 0BCDh 0C3Eh 0C40h 0C46h 0C48h
	0C4Ah 0C4Dh 0C55h 0C56h 0CBCh 0CBCh
	0CBFh 0CBFh 0CC6h 0CC6h 0CCCh 0CCDh
	0CE2h 0CE3h 0D41h 0D43h 0D4Dh 0D4Dh
	0DCAh 0DCAh 0DD2h 0DD4h 0DD6h 0DD6h
	0E31h 0E31h 0E34h 0E3Ah 0E47h 0E4Eh
	0EB1h 0EB1h 0EB4h 0EB9h 0EBBh 0EBCh
	0EC8h 0ECDh 0F18h 0F19h 0F35h 0F35h
	0F37h 0F37h 0F39h 0F39h 0F71h 0F7Eh
	0F80h 0F84h 0F86h 0F87h 0F90h 0F97h
	0F99h 0FBCh 0FC6h 0FC6h 102Dh 1030h
	1032h 1032h 1036h 1037h 1039h 1039h
	1058h 1059h 1160h 11FFh 135Fh 135Fh
	1712h 1714h 1732h 1734h 1752h 1753h
	1772h 1773h 17B4h 17B5h 17B7h 17BDh
	17C6h 17C6h 17C9h 17D3h 17DDh 17DDh
	180Bh 180Dh 18A9h 18A9h 1920h 1922h
	1927h 1928h 1932h 1932h 1939h 193Bh
	1A17h 1A18h 1B00h 1B03h 1B34h 1B34h
	1B36h 1B3Ah 1B3Ch 1B3Ch 1B42h 1B42h
	1B6Bh 1B73h 1DC0h 1DCAh 1DFEh 1DFFh
	200Bh 200Fh 202Ah 202Eh 2060h 2063h
	206Ah 206Fh 20D0h 20EFh 302Ah 302Fh
	3099h 309Ah A806h A806h A80Bh A80Bh
	A825h A826h FB1Eh FB1Eh FE00h FE0Fh
	FE20h FE23h FEFFh FEFFh FFF9h FFFBh
	00010A01h 00010A03h 00010A05h 00010A06h 00010A0Ch 00010A0Fh
	00010A38h 00010A3Ah 00010A3Fh 00010A3Fh 0001D167h 0001D169h
	0001D173h 0001D182h 0001D185h 0001D18Bh 0001D1AAh 0001D1ADh
	0001D242h 0001D244h 000E0001h 000E0001h 000E0020h 000E007Fh
	000E0100h 000E01EFh
]

in-table?: func [
	cp		[integer!]
	table	[int-ptr!]
	max		[integer!]
	return: [logic!]
	/local
		a	[integer!]
		b	[integer!]
][
	if any [cp < table/1 cp > table/max][return no]

	a: -1
	until [
		a: a + 2
		b: a + 1
		if all [cp >= table/a cp <= table/b][return yes]
		b = max
	]
	no
]

wcwidth?: func [
	cp		[integer!]
	return: [integer!]
][
	if zero? cp [return 0]
	if any [						;-- tests for 8-bit control characters
		cp < 32
		all [cp >= 7Fh cp < A0h]
	][return 1]

	if in-table? cp combining-table size? combining-table [return 0]

	if any [
		all [
			cp >= 1100h
			any [
				cp <= 115Fh									;-- Hangul Jamo init. consonants
				cp = 2329h
				cp = 232Ah
				all [cp >= 2E80h cp <= A4CFh cp <> 303Fh]	;-- CJK ... Yi
				all [cp >= AC00h cp <= D7A3h]				;-- Hangul Syllables
				all [cp >= F900h cp <= FAFFh]				;-- CJK Compatibility Ideographs
				all [cp >= FE10h cp <= FE19h]				;-- Vertical forms
				all [cp >= FE30h cp <= FE6Fh]				;-- CJK Compatibility Forms
				all [cp >= FF00h cp <= FF60h]				;-- Fullwidth Forms
				all [cp >= FFE0h cp <= FFE6h]
				all [cp >= 00020000h cp <= 0002FFFDh]
				all [cp >= 00030000h cp <= 0003FFFDh]
			]
		]
		cp = 0D0Ah
	][return 2]
	1
]

#if OS = 'Windows [
	ambiguous-table: [
		00A1h 00A1h 00A4h 00A4h 00A7h 00A8h
		00AAh 00AAh 00AEh 00AEh 00B0h 00B4h
		00B6h 00BAh 00BCh 00BFh 00C6h 00C6h
		00D0h 00D0h 00D7h 00D8h 00DEh 00E1h
		00E6h 00E6h 00E8h 00EAh 00ECh 00EDh
		00F0h 00F0h 00F2h 00F3h 00F7h 00FAh
		00FCh 00FCh 00FEh 00FEh 0101h 0101h
		0111h 0111h 0113h 0113h 011Bh 011Bh
		0126h 0127h 012Bh 012Bh 0131h 0133h
		0138h 0138h 013Fh 0142h 0144h 0144h
		0148h 014Bh 014Dh 014Dh 0152h 0153h
		0166h 0167h 016Bh 016Bh 01CEh 01CEh
		01D0h 01D0h 01D2h 01D2h 01D4h 01D4h
		01D6h 01D6h 01D8h 01D8h 01DAh 01DAh
		01DCh 01DCh 0251h 0251h 0261h 0261h
		02C4h 02C4h 02C7h 02C7h 02C9h 02CBh
		02CDh 02CDh 02D0h 02D0h 02D8h 02DBh
		02DDh 02DDh 02DFh 02DFh 0391h 03A1h
		03A3h 03A9h 03B1h 03C1h 03C3h 03C9h
		0401h 0401h 0410h 044Fh 0451h 0451h
		2010h 2010h 2013h 2016h 2018h 2019h
		201Ch 201Dh 2020h 2022h 2024h 2027h
		2030h 2030h 2032h 2033h 2035h 2035h
		203Bh 203Bh 203Eh 203Eh 2074h 2074h
		207Fh 207Fh 2081h 2084h 20ACh 20ACh
		2103h 2103h 2105h 2105h 2109h 2109h
		2113h 2113h 2116h 2116h 2121h 2122h
		2126h 2126h 212Bh 212Bh 2153h 2154h
		215Bh 215Eh 2160h 216Bh 2170h 2179h
		2190h 2199h 21B8h 21B9h 21D2h 21D2h
		21D4h 21D4h 21E7h 21E7h 2200h 2200h
		2202h 2203h 2207h 2208h 220Bh 220Bh
		220Fh 220Fh 2211h 2211h 2215h 2215h
		221Ah 221Ah 221Dh 2220h 2223h 2223h
		2225h 2225h 2227h 222Ch 222Eh 222Eh
		2234h 2237h 223Ch 223Dh 2248h 2248h
		224Ch 224Ch 2252h 2252h 2260h 2261h
		2264h 2267h 226Ah 226Bh 226Eh 226Fh
		2282h 2283h 2286h 2287h 2295h 2295h
		2299h 2299h 22A5h 22A5h 22BFh 22BFh
		2312h 2312h 2460h 24E9h 24EBh 254Bh
		2550h 2573h 2580h 258Fh 2592h 2595h
		25A0h 25A1h 25A3h 25A9h 25B2h 25B3h
		25B6h 25B7h 25BCh 25BDh 25C0h 25C1h
		25C6h 25C8h 25CBh 25CBh 25CEh 25D1h
		25E2h 25E5h 25EFh 25EFh 2605h 2606h
		2609h 2609h 260Eh 260Fh 2614h 2615h
		261Ch 261Ch 261Eh 261Eh 2640h 2640h
		2642h 2642h 2660h 2661h 2663h 2665h
		2667h 266Ah 266Ch 266Dh 266Fh 266Fh
		273Dh 273Dh 2776h 277Fh E000h F8FFh
		FFFDh FFFDh 000F0000h 000FFFFDh 00100000h 0010FFFDh
	]

	cjk-wcwidth?: func [
		cp		[integer!]
		return: [integer!]
	][
		if in-table? cp ambiguous-table size? ambiguous-table [return 2]
		wcwidth? cp
	]
]
		
		#either OS = 'Windows [
			

#define VK_BACK 				 	08h
#define VK_TAB 					 	09h
#define VK_CLEAR 				 	0Ch
#define VK_RETURN 				 	0Dh

#either modules contains 'View [][
	#define VK_SHIFT				10h
	#define VK_CONTROL				11h
	#define VK_PRIOR				21h
	#define VK_NEXT					22h
	#define VK_END					23h
	#define VK_HOME					24h
	#define VK_LEFT					25h
	#define VK_UP					26h
	#define VK_RIGHT				27h
	#define VK_DOWN					28h
	#define VK_SELECT				29h
	#define VK_INSERT				2Dh
	#define VK_DELETE				2Eh
]

#define KEY_EVENT 				 	01h
#define MOUSE_EVENT 			 	02h
#define WINDOW_BUFFER_SIZE_EVENT 	04h
#define MENU_EVENT 				 	08h
#define FOCUS_EVENT 			 	10h
#define ENHANCED_KEY 			 	0100h
#define ENABLE_PROCESSED_INPUT		01h
#define ENABLE_LINE_INPUT 			02h
#define ENABLE_ECHO_INPUT 			04h
#define ENABLE_WINDOW_INPUT         08h
#define ENABLE_QUICK_EDIT_MODE		40h

mouse-event!: alias struct! [
	Position  [integer!]			;-- high 16-bit: Y	low 16-bit: X
	BtnState  [integer!]
	KeyState  [integer!]
	Flags	  [integer!]
]

key-event!: alias struct! [		   ;typedef struct _KEY_EVENT_RECORD {
	KeyDown   			[integer!] ;  WINBOOL bKeyDown;  	offset: 0
	RepeatCnt-KeyCode	[integer!] ;  WORD wRepeatCount;            4
	ScanCode-Char		[integer!] ;  WORD wVirtualKeyCode;    		6
	KeyState  			[integer!] ;  WORD wVirtualScanCode;  		8
]                          		   ;  union {
                                   ;    WCHAR UnicodeChar;
                                   ;    CHAR AsciiChar;
                                   ;  } uChar;						10
                                   ;  DWORD dwControlKeyState;		12
                                   ;} KEY_EVENT_RECORD,*PKEY_EVENT_RECORD;

input-record!: alias struct! [
	EventType [integer!]
	Event	  [integer!]
	pad2	  [integer!]
	pad3	  [integer!]
	pad4	  [integer!]
]

;@@ use integer16! once available as values are in words
screenbuf-info!: alias struct! [	;-- size? screenbuf-info! = 22
	Size	        [integer!]     	;typedef struct _CONSOLE_SCREEN_BUFFER_INFO {
	Position        [integer!]     	;  COORD dwSize;		offset: 0
	attr-left       [integer!]     	;  COORD dwCursorPosition;		4
	top-right       [integer!]     	;  WORD wAttributes;			8
	bottom-maxWidth [integer!]     	;  SMALL_RECT srWindow;			10
	pad4 	  [byte!]           	;  COORD dwMaximumWindowSize;	18
	pad5 	  [byte!]           	;} CONSOLE_SCREEN_BUFFER_INFO,*PCONSOLE_SCREEN_BUFFER_INFO;
]									;-- sizeof(CONSOLE_SCREEN_BUFFER_INFO) = 22

#import [
	"kernel32.dll" stdcall [
		ReadFile:	"ReadFile" [
			file		[integer!]
			buffer		[byte-ptr!]
			bytes		[integer!]
			read		[int-ptr!]
			overlapped	[int-ptr!]
			return:		[integer!]
		]
		ReadConsoleInput: "ReadConsoleInputW" [
			handle			[integer!]
			arrayOfRecs		[integer!]
			length			[integer!]
			numberOfRecs	[int-ptr!]
			return:			[integer!]
		]
		SetConsoleMode: "SetConsoleMode" [
			handle			[integer!]
			mode			[integer!]
			return:			[integer!]
		]
		GetConsoleMode:	"GetConsoleMode" [
			handle			[integer!]
			mode			[int-ptr!]
			return:			[integer!]
		]
		WriteConsole: 	 "WriteConsoleW" [
			consoleOutput	[integer!]
			buffer			[byte-ptr!]
			charsToWrite	[integer!]
			numberOfChars	[int-ptr!]
			_reserved		[int-ptr!]
			return:			[integer!]
		]
		FillConsoleOutputAttribute: "FillConsoleOutputAttribute" [
			handle			[integer!]
			attributs		[integer!]
			length			[integer!]
			coord			[integer!]
			numberOfAttrs	[int-ptr!]
		]
		FillConsoleOutputCharacter: "FillConsoleOutputCharacterW" [
			handle			[integer!]
			attributs		[integer!]
			length			[integer!]
			coord			[integer!]
			numberOfChars	[int-ptr!]
		]
		SetConsoleCursorPosition: "SetConsoleCursorPosition" [
			handle 			[integer!]
			coord 			[integer!]
		]
		GetConsoleScreenBufferInfo: "GetConsoleScreenBufferInfo" [
			handle 			[integer!]
			info 			[integer!]
			return: 		[integer!]
		]
		GetConsoleWindow: "GetConsoleWindow" [
			return:			[int-ptr!]
		]
		GetFileType: "GetFileType" [
			hFile			[int-ptr!]
			return:			[integer!]
		]
	]
]

input-rec: declare input-record!
base-y:	 	 0
saved-con:	 0
utf-char: allocate 10

#define FIRST_WORD(int) (int and FFFFh)
#define SECOND_WORD(int) (int >>> 16)

isatty: func [
	handle	[int-ptr!]
	return:	[logic!]
][
	2 = GetFileType handle			;-- FILE_TYPE_CHAR: 2
]

stdin-read: func [
	return:		[integer!]
	/local
		i		[integer!]
		c		[integer!]
		len		[integer!]
		read-sz [integer!]
][
	read-sz: 0
	if zero? ReadFile stdin utf-char 1 :read-sz null [return -1]

	c: as-integer utf-char/1
	case [
		c and 80h = 0	[len: 1]
		c and E0h = C0h [len: 2]
		c and F0h = E0h [len: 3]
		c and F8h = F0h [len: 4]
	]
	if any [len < 1 len > 4][return -1]

	i: 1
	while [i < len][
		if all [
			len >= (i + 1)
			zero? 	ReadFile stdin utf-char + i 1 :read-sz null
		][
			return -1
		]
		i: i + 1
	]
	c: unicode/decode-utf8-char as-c-string utf-char :len
	c
]

fd-read: func [
	return: 	[integer!]
	/local
		key 	[key-event!]
		n	 	[integer!]
		keycode [integer!]
		size    [red-pair!]
][
	n: 0
	forever [
		if zero? ReadConsoleInput stdin as-integer input-rec 1 :n [return -1]
		switch input-rec/EventType and FFFFh [
			KEY_EVENT [
				key: as key-event! (as-integer input-rec) + (size? integer!)
				if key/KeyDown <> 0 [
					keycode: SECOND_WORD(key/RepeatCnt-KeyCode)  ;-- 1st RepeatCnt 2 KeyCode
					case [
						key/KeyState and ENHANCED_KEY > 0 [
							switch keycode [
								VK_LEFT		[return KEY_LEFT]
								VK_RIGHT	[return KEY_RIGHT]
								VK_UP		[return KEY_UP]
								VK_DOWN		[return KEY_DOWN]
								VK_INSERT	[return KEY_INSERT]
								VK_DELETE	[return KEY_DELETE]
								VK_HOME		[return KEY_HOME]
								VK_END		[return KEY_END]
								VK_PRIOR	[return KEY_PAGE_UP]
								VK_NEXT		[return KEY_PAGE_DOWN]
								VK_RETURN	[return KEY_ENTER]
								default		[return KEY_NONE]
							]
						]
						keycode = VK_CONTROL []
						true [return SECOND_WORD(key/ScanCode-Char)] ;-- return Char
					]
				]
			]
			WINDOW_BUFFER_SIZE_EVENT [
				get-window-size
			]
			;FOCUS_EVENT
			;MENU_EVENT
			;MOUSE_EVENT
			default []
		]
	]
	-1
]

get-window-size: func [
	return: 	[integer!]
	/local
		info 	[screenbuf-info!]
		x-y 	[integer!]
		size    [red-pair!]
][
	info: declare screenbuf-info!
	size: as red-pair! #get system/console/size
	size/x: 80											;-- set defaults when working with stdout
	size/y: 50											;   as many output funcs rely on it
	columns: size/x
	rows: size/y
	if zero? GetConsoleScreenBufferInfo stdout as-integer info [return -1]
	x-y: info/Size
	columns: FIRST_WORD(x-y)
	rows: SECOND_WORD(x-y)
	size/x: SECOND_WORD(info/top-right) - SECOND_WORD(info/attr-left) + 1
	size/y: FIRST_WORD(info/bottom-maxWidth) - FIRST_WORD(info/top-right) + 1
	if columns <= 0 [size/x: 80 columns: 80 return -1]
	x-y: info/Position
	base-y: SECOND_WORD(x-y)
	0
]

emit-red-char: func [cp [integer!] /local n][
	if hide-input? [cp: as-integer #"*"]
	n: 2 * unicode/cp-to-utf16 cp pbuffer
	pbuffer: pbuffer + n
]

reset-cursor-pos: does [
	SetConsoleCursorPosition stdout base-y << 16
]

erase-to-bottom: func [
	/local
		n	 [integer!]
		info [screenbuf-info!]
		x-y  [integer!]
][
	n: 0
	info: declare screenbuf-info!
	GetConsoleScreenBufferInfo stdout as-integer info
	x-y: info/Position
	FillConsoleOutputCharacter							;-- clear screen
		stdout
		20h												;-- #" " = 20h
		rows - SECOND_WORD(x-y) * columns				;-- (rows - y) * columns
		x-y
		:n
]

set-cursor-pos: func [
	line	[red-string!]
	offset	[integer!]
	size	[integer!]
	/local
		x	[integer!]
		y	[integer!]
][
	y: offset / columns
	x: offset // columns
	if all [
		widechar? line
		columns - x = 1
	][
		y: y + 1
		x: 0
	]
	SetConsoleCursorPosition stdout base-y + y << 16 or x
]

output-to-screen: func [/local n][
	n: 0
	WriteConsole stdout buffer (as-integer pbuffer - buffer) / 2 :n null
]

init: func [][
	console?: isatty as int-ptr! stdin
	if console? [
		get-window-size
	]
]

init-console: func [
	/local
		mode	[integer!]
][
	if console? [
		GetConsoleMode stdin :saved-con
		mode: saved-con and (not ENABLE_PROCESSED_INPUT)	;-- turn off PROCESSED_INPUT, so we can handle control-c
		mode: mode or ENABLE_QUICK_EDIT_MODE or ENABLE_WINDOW_INPUT	;-- use the mouse to select and edit text
		SetConsoleMode stdin mode
		buffer: allocate buf-size
	]
]

restore: does [
	SetConsoleMode stdin saved-con free buffer
]

		][
			

#define OS_POLLIN 		1

#case [
	any [OS = 'macOS OS = 'FreeBSD] [
		#define TIOCGWINSZ		40087468h
		#define TERM_TCSADRAIN	1
		#define TERM_VTIME		18
		#define TERM_VMIN		17

		#define TERM_BRKINT		02h
		#define TERM_INPCK		10h
		#define TERM_ISTRIP		20h
		#define TERM_ICRNL		0100h
		#define TERM_IXON		0200h
		#define TERM_OPOST		01h
		#define TERM_CS8		0300h
		#define TERM_ISIG		80h
		#define TERM_ICANON		0100h
		#define TERM_ECHO		08h	
		#define TERM_IEXTEN		4000h

		termios!: alias struct! [
			c_iflag			[integer!]
			c_oflag			[integer!]
			c_cflag			[integer!]
			c_lflag			[integer!]
			c_cc1			[integer!]						;-- c_cc[20]
			c_cc2			[integer!]
			c_cc3			[integer!]
			c_cc4			[integer!]
			c_cc5			[integer!]
			c_ispeed		[integer!]
			c_ospeed		[integer!]
		]
	]
	true [													;-- Linux
		#define TIOCGWINSZ		5413h
		#define TERM_VTIME		6
		#define TERM_VMIN		7

		#define TERM_BRKINT		2
		#define TERM_INPCK		20
		#define TERM_ISTRIP		40
		#define TERM_ICRNL		400
		#define TERM_IXON		2000
		#define TERM_OPOST		1
		#define TERM_CS8		60
		#define TERM_ISIG		1
		#define TERM_ICANON		2
		#define TERM_ECHO		10
		#define TERM_IEXTEN		100000

		#either OS = 'Android [
			#define TERM_TCSADRAIN	5403h

			termios!: alias struct! [
				c_iflag			[integer!]
				c_oflag			[integer!]
				c_cflag			[integer!]
				c_lflag			[integer!]
				;c_line			[byte!]
				c_cc1			[integer!]					;-- c_cc[19]
				c_cc2			[integer!]
				c_cc3			[integer!]
				c_cc4			[integer!]
				c_cc5			[integer!]
			]
		][
			#define TERM_TCSADRAIN	1

			termios!: alias struct! [						;-- sizeof(termios) = 60
				c_iflag			[integer!]
				c_oflag			[integer!]
				c_cflag			[integer!]
				c_lflag			[integer!]
				c_line			[byte!]
				c_cc1			[byte!]						;-- c_cc[32]
				c_cc2			[byte!]
				c_cc3			[byte!]
				c_cc4			[integer!]
				c_cc5			[integer!]
				c_cc6			[integer!]
				c_cc7			[integer!]
				c_cc8			[integer!]
				c_cc9			[integer!]
				c_cc10			[integer!]
				pad				[integer!]					;-- for proper alignment
				c_ispeed		[integer!]
				c_ospeed		[integer!]
			]
		]
	]
]

pollfd!: alias struct! [
	fd				[integer!]
	events			[integer!]						;-- high 16-bit: events
]													;-- low  16-bit: revents

winsize!: alias struct! [
	rowcol			[integer!]
	xypixel			[integer!]
]

#either OS = 'Android [
	tcgetattr: func [
		fd		[integer!]
		termios [termios!]
		return: [integer!]
	][
		ioctl fd 5401h as winsize! termios
	]
	tcsetattr: func [
		fd			[integer!]
		opt_actions [integer!]
		termios 	[termios!]
		return: 	[integer!]
	][
		ioctl fd opt_actions as winsize! termios
	]
][
	#import [
	LIBC-file cdecl [
		tcgetattr: "tcgetattr" [
			fd		[integer!]
			termios [termios!]
			return: [integer!]
		]
		tcsetattr: "tcsetattr" [
			fd			[integer!]
			opt_actions [integer!]
			termios 	[termios!]
			return: 	[integer!]
		]
	]]
]

#import [
	LIBC-file cdecl [
		isatty: "isatty" [
			fd		[integer!]
			return:	[integer!]
		]
		read: "read" [
			fd		[integer!]
			buf		[byte-ptr!]
			size	[integer!]
			return: [integer!]
		]
		write: "write" [
			fd		[integer!]
			buf		[byte-ptr!]
			size	[integer!]
			return: [integer!]
		]
		poll: "poll" [
			fds		[pollfd!]
			nfds	[integer!]
			timeout [integer!]
			return: [integer!]
		]
		ioctl: "ioctl" [
			fd		[integer!]
			request	[integer!]
			ws		[winsize!]
			return: [integer!]
		]
	]
]

old-act:	declare sigaction!
saved-term: declare termios!
utf-char: as-c-string allocate 10
poller: 	declare pollfd!
relative-y:	0
init?:		no

fd-read-char: func [
	timeout [integer!]
	return: [byte!]
	/local
		c [byte!]
][
	c: as-byte -1
	if any [
		zero? poll poller 1 timeout
		1 <> read stdin :c 1
	][
		return as-byte -1
	]
	c
]

fd-read: func [
	return: [integer!]								;-- input codepoint or -1
	/local
		c	[integer!]
		len [integer!]
		i	[integer!]
][
	if 1 <> read stdin as byte-ptr! utf-char 1 [return -1]
	c: as-integer utf-char/1
	case [
		c and 80h = 0	[len: 1]
		c and E0h = C0h [len: 2]
		c and F0h = E0h [len: 3]
		c and F8h = F0h [len: 4]
	]
	if any [len < 1 len > 4][return -1]

	i: 1
	while [i < len][
		if all [
			len >= (i + 1)
			1 <> read stdin as byte-ptr! utf-char + i 1
		][
			return -1
		]
		i: i + 1
	]
	unicode/decode-utf8-char utf-char :len
]

check-special: func [
	return: [integer!]
	/local
		c  [byte!]
		c2 [byte!]
		c3 [byte!]
][
	c: fd-read-char 50
	if (as-integer c) > 127 [return 27]

	c2: fd-read-char 50
	if (as-integer c2) > 127 [return as-integer c2]

	if any [c = #"[" c = #"O"][
		switch c2 [
			#"A" [return KEY_UP]
			#"B" [return KEY_DOWN]
			#"C" [return KEY_RIGHT]
			#"D" [return KEY_LEFT]
			#"F" [return KEY_END]
			#"H" [return KEY_HOME]
			default []
		]
	]
	if all [c = #"[" #"1" <= c2 c2 <= #"8"][
		c: fd-read-char 50
		if c = #"~" [
			switch c2 [
				#"2" [return KEY_INSERT]
				#"3" [return KEY_DELETE]
				#"5" [return KEY_PAGE_UP]
				#"6" [return KEY_PAGE_DOWN]
				#"7" [return KEY_HOME]
				#"8" [return KEY_END]
				default [return KEY_NONE]
			]
		]
		if all [(as-integer c) <> -1 c <> #"~"][
			c3: fd-read-char 50
		]

		if all [c2 = #"2" c = #"0" #"~" = fd-read-char 50][
			pasting?: c3 = #"0"
		]
	]
	KEY_NONE
]

emit: func [c [byte!]][
	write stdout :c 1
]

emit-string: func [
	s [c-string!]
][
	write stdout as byte-ptr! s length? s
]

emit-string-int: func [
	begin [c-string!]
	n	  [integer!]
	end	  [byte!]
][
	emit-string begin
	emit-string integer/form-signed n
	emit end
]

emit-red-char: func [
	cp			[integer!]
][
	if hide-input? [cp: as-integer #"*"]
	case [
		cp <= 7Fh [
			pbuffer/1: as-byte cp
			pbuffer: pbuffer + 1
		]
		cp <= 07FFh [
			pbuffer/1: as-byte cp >> 6 or C0h
			pbuffer/2: as-byte cp and 3Fh or 80h
			pbuffer: pbuffer + 2
		]
		cp <= FFFFh [
			pbuffer/1: as-byte cp >> 12 or E0h
			pbuffer/2: as-byte cp >> 6 and 3Fh or 80h
			pbuffer/3: as-byte cp and 3Fh or 80h
			pbuffer: pbuffer + 3
		]
		cp <= 001FFFFFh [
			pbuffer/1: as-byte cp >> 18 or F0h
			pbuffer/2: as-byte cp >> 12 and 3Fh or 80h
			pbuffer/3: as-byte cp >>  6 and 3Fh or 80h
			pbuffer/4: as-byte cp and 3Fh or 80h
			pbuffer: pbuffer + 4
		]
		true [
			print-line "Error in emit-red-string: codepoint > 1FFFFFh"
		]
	]
]

query-cursor: func [
	col		[int-ptr!]
	return: [logic!]								;-- FALSE: failed to retrieve it
	/local
		c [byte!]
		n [integer!]
][
	emit-string "^[[6n"								;-- ask for cursor location
	if all [
		  esc = fd-read-char 100
		 #"[" = fd-read-char 100
	][
		while [true][
			c: fd-read-char 100
			n: 0
			case [
				c = #";" [n: 0]
				all [c = #"R" n <> 0 n < 1000][
					col/value: n
					return true
				]
				all [#"0" <= c c <= #"9"][
					n: n * 10 + (c - #"0")
				]
				true [
					return true
				]
			]
		]
	]
	false
]

get-window-size: func [
	/local
		ws	 [winsize!]
		size [red-pair!]
][
	ws: declare winsize!

	ioctl stdout TIOCGWINSZ ws
	columns: ws/rowcol >> 16
	rows: ws/rowcol and FFFFh
	size: as red-pair! #get system/console/size
	size/x: columns
	size/y: rows
]

reset-cursor-pos: does [
	if positive? relative-y [emit-string-int "^[[" relative-y #"A"]	;-- move to origin row
	emit cr
]

erase-to-bottom: does [
	emit-string "^[[0J"				;-- erase down to the bottom of the screen
]

set-cursor-pos: func [
	line	[red-string!]
	offset	[integer!]
	size	[integer!]
	/local
		x	[integer!]
		y	[integer!]
][
	relative-y: size / columns		;-- the lines of all outputs occupy
	y: size / columns - (offset / columns)
	x: offset // columns

	if all [						;-- special case: when moving cursor to the first char of a line
		widechar? line				;-- the first char of the line is a widechar
		columns - x = 1				;-- but in pre line only 1 space left
	][
		y: y - 1
		x: 0
	]

	if zero? (size % columns) [emit #"^(0A)"]

	if positive? y [				;-- set cursor position: y
	    emit-string-int "^[[" y #"A"
	    relative-y: relative-y - y
	]
	either zero? x [		 		;-- set cursor position: x
		emit #"^(0D)"
	][
		emit-string-int "^(0D)^[[" x #"C"
	]
]

output-to-screen: does [
	write stdout buffer (as-integer pbuffer - buffer)
]

init: func [][
	console?: 1 = isatty stdin
	if console? [
		get-window-size
	]
]

init-console: func [
	/local
		term [termios!]
		cc	 [byte-ptr!]
		so	 [sigaction! value]
][
	relative-y: 0
	
	if console? [
		sigemptyset (as-integer :so) + 4
		so/sigaction: as-integer :on-resize
		so/flags: 0
		#either OS = 'Linux [
			sigaction SIGWINCH :so null
		][
			sigaction SIGWINCH :so old-act
		]

		term: declare termios!
		tcgetattr stdin saved-term					;@@ check returned value

		copy-memory 
			as byte-ptr! term
			as byte-ptr! saved-term
			size? term

		term/c_iflag: term/c_iflag and not (
			TERM_BRKINT or TERM_ICRNL or TERM_INPCK or TERM_ISTRIP or TERM_IXON
		)
		term/c_oflag: term/c_oflag and not TERM_OPOST
		term/c_cflag: term/c_cflag or TERM_CS8
		term/c_lflag: term/c_lflag and not (
			TERM_ECHO or TERM_ICANON or TERM_IEXTEN or TERM_ISIG
		)
		#case [
			any [OS = 'macOS OS = 'FreeBSD] [
				cc: (as byte-ptr! term) + (4 * size? integer!)
			]
			true [cc: (as byte-ptr! term) + (4 * size? integer!) + 1]
		]
		cc/TERM_VMIN:  as-byte 1
		cc/TERM_VTIME: as-byte 0

		tcsetattr stdin TERM_TCSADRAIN term

		poller/fd: stdin
		poller/events: OS_POLLIN

		buffer: allocate buf-size
		unless init? [
			emit-string "^[[?2004h"		;-- enable bracketed paste mode: https://cirw.in/blog/bracketed-paste
			init?: yes
		]
	]
	#if OS = 'macOS [
		#if modules contains 'View [
			with gui [
				if NSApp <> 0 [do-events yes]
			]
		]
	]
]

restore: does [
	tcsetattr stdin TERM_TCSADRAIN saved-term
	#if OS <> 'Linux [sigaction SIGWINCH old-act null]
	free buffer
]

		]

		console?:	yes
		buffer:		declare byte-ptr!
		pbuffer:	declare byte-ptr!
		input-line: declare red-string!
		prompt:		declare	red-string!
		history:	declare red-block!
		saved-line:	as red-string! 0
		buf-size:	128
		columns:	-1
		rows:		-1
		output?:	yes
		pasting?:	no
		hide-input?: no

		init-globals: func [][
			saved-line: string/rs-make-at ALLOC_TAIL(root) 1
		]

		widechar?: func [
			str			[red-string!]
			return:		[logic!]
			/local
				cp		[integer!]
				unit	[integer!]
				s		[series!]
				offset	[byte-ptr!]
		][
			s: GET_BUFFER(str)
			unit: GET_UNIT(s)
			offset: (as byte-ptr! s/offset) + (str/head << (log-b unit))
			cp: 0
			if offset < as byte-ptr! s/tail [cp: string/get-char offset unit]
			cp > FFh
		]

		on-resize: func [[cdecl] sig [integer!]][
			get-window-size
			refresh
		]

		complete-line: func [
			str			[red-string!]
			return:		[integer!]
			/local
				line	[red-string!]
				result	[red-block!]
				num		[integer!]
				str2	[red-string!]
				head	[integer!]
		][
			#call [red-complete-ctx/complete-input str yes]
			stack/top: stack/arguments + 2
			result: as red-block! stack/top
			num: block/rs-length? result
			unless zero? num [
				head: str/head
				str/head: 0
				_series/copy
					as red-series! str
					as red-series! saved-line
					stack/arguments
					yes
					stack/arguments
				saved-line/head: head
				line: input-line
				string/rs-reset line

				str2: as red-string! block/rs-head result
				head: str2/head
				str2/head: 0
				either num = 1 [
					string/concatenate line str2 -1 0 yes no
					line/head: head
				][
					string/rs-reset saved-line
					string/concatenate saved-line str2 -1 0 yes no
					saved-line/head: head
					block/rs-next result				;-- skip first one
					until [
						string/concatenate line as red-string! block/rs-head result -1 0 yes no
						string/append-char GET_BUFFER(line) 32
						block/rs-next result
						block/rs-tail? result
					]
					line/head: string/rs-abs-length? line
				]
				refresh
			]
			num
		]

		add-history: func [
			str	[red-string!]
		][
			str/head: 0
			if hide-input? [exit]
			unless any [
				zero? string/rs-length? str
				all [
					0 < block/rs-length? history
					zero? string/equal? str as red-string! block/rs-abs-at history 0 COMP_STRICT_EQUAL no
				]
			][
				history/head: 0
				block/insert-value history as red-value! str
			]
		]

		fetch-history: does [
			string/rs-reset input-line
			string/concatenate input-line as red-string! block/rs-head history -1 0 yes no
			input-line/head: string/rs-abs-length? input-line
		]

		init-buffer: func [
			str			[red-string!]
			prompt		[red-string!]
			/local
				unit	[integer!]
				s		[series!]
				size	[integer!]
		][
			s: GET_BUFFER(str)
			unit: GET_UNIT(s)
			if unit < 2 [unit: 2]			;-- always treat string as widechar string
			size: (string/rs-abs-length? str) << (log-b unit)
			size: size + (string/rs-abs-length? prompt) << (log-b unit)
			if size > buf-size [
				buf-size: size
				free buffer
				buffer: allocate size
			]
			pbuffer: buffer
		]

		process-ansi-sequence: func [
			str 	[byte-ptr!]
			tail	[byte-ptr!]
			unit    [integer!]
			print?	[logic!]
			return: [integer!]
			/local
				cp      [integer!]
				bytes   [integer!]
				state   [integer!]
		][
			cp: string/get-char str unit
			if all [
				cp <> as-integer #"["
				cp <> as-integer #"("
			][return 0]

			if print? [emit-red-char cp]
			str: str + unit
			bytes: unit
			state: 1
			while [all [state > 0 str < tail]] [
				cp: string/get-char str unit
				if print? [emit-red-char cp]
				str: str + unit
				bytes: bytes + unit
				switch state [
					1 [
						unless any [
							cp = as-integer #";"
							all [cp >= as-integer #"0" cp <= as-integer #"9"]
						][state: -1]
					]
					2 [
						case [
							all [cp >= as-integer #"0" cp <= as-integer #"9"][0]
							cp = as-integer #";" [state: 3]
							true [ state: -1 ]
						]
					]
					3 [
						case [
							all [cp >= as-integer #"0" cp <= as-integer #"9"][state: 4]
							cp = as-integer #";" [0] ;do nothing
							true [ state: -1 ]
						]
					]
					4 [
						case [
							all [cp >= as-integer #"0" cp <= as-integer #"9"][0]
							cp = as-integer #";" [state: 1]
							true [ state: -1 ]
						]
					]
				]
			]
			bytes
		]

		emit-red-string: func [
			str			[red-string!]
			size		[integer!]
			head-as-tail? [logic!]
			return: 	[integer!]
			/local
				series	[series!]
				offset	[byte-ptr!]
				tail	[byte-ptr!]
				unit	[integer!]
				cp		[integer!]
				bytes	[integer!]
				cnt		[integer!]
				x		[integer!]
				w		[integer!]
				sn		[integer!]
		][
			x:		0
			w:		0
			cnt:	0
			bytes:	0
			series: GET_BUFFER(str)
			unit: 	GET_UNIT(series)
			offset: (as byte-ptr! series/offset) + (str/head << (log-b unit))
			tail:   as byte-ptr! series/tail
			if head-as-tail? [
				tail: offset
				offset: as byte-ptr! series/offset
			]
			sn: 0
			until [
				while [
					all [offset < tail cnt < size]
				][
					either zero? sn [
						cp: string/get-char offset unit
						if cp = 9 [			;-- convert a tab to 4 spaces
							offset: offset - unit
							cp: 32
							sn: 3
						]
						emit-red-char cp
						offset: offset + unit
						if cp = as-integer #"^[" [
							cnt: cnt - 1
							offset: offset + process-ansi-sequence offset tail unit yes
						]
					][
						emit-red-char cp
						sn: sn - 1
						if zero? sn [offset: offset + unit]
					]
					w: either all [0001F300h <= cp cp <= 0001F5FFh][2][wcwidth? cp]
					cnt: switch w [
						1  [cnt + 1]
						2  [either size - cnt = 1 [x: 2 cnt + 3][cnt + 2]]	;-- reach screen edge, handle wide char
						default [0]
					]
				]
				bytes: bytes + cnt
				size: columns - x
				x: 0
				cnt: 0
				offset >= tail
			]
			bytes
		]

		refresh: func [
			/local
				line   [red-string!]
				offset [integer!]
				bytes  [integer!]
				psize  [integer!]
				hide?  [logic!]
		][
			line: input-line

			either output? [					;-- erase down to the bottom of the screen
				reset-cursor-pos
				erase-to-bottom
			][
				#if OS <> 'Windows [reset-cursor-pos][0]
			]
			init-buffer line prompt
			hide?: hide-input?
			hide-input?: no
			bytes: emit-red-string prompt columns no
			hide-input?: hide?

			psize: bytes // columns
			offset: bytes + (emit-red-string line columns - psize yes)	;-- output until reach cursor posistion

			psize: offset // columns
			bytes: offset + (emit-red-string line columns - psize no)	;-- continue until reach tail

			either output? [
				output-to-screen
			][
				#if OS <> 'Windows [
					if all [
						bytes > columns
						positive? (bytes // columns)
					][
						psize: bytes / columns
						emit-string-int "^[[" psize  #"B"
					]
				][0]
			]
			set-cursor-pos line offset bytes
		]

		console-edit: func [
			prompt-str [red-string!]
			/local
				line   [red-string!]
				head   [integer!]
				c	   [integer!]
				n	   [integer!]
				pos	   [integer!]
				max	   [integer!]
		][
			line: input-line
			copy-cell as red-value! prompt-str as red-value! prompt
			history/head: 0
			pos: -1
			max: block/rs-length? history
				
			get-window-size
			if null? saved-line [init-globals]
			unless zero? string/rs-abs-length? saved-line [
				head: saved-line/head
				saved-line/head: 0
				string/concatenate line saved-line -1 0 yes no
				line/head: head
			]
			refresh

			while [true][
				output?: yes
				c: fd-read
				n: 0

				if all [c = KEY_TAB not pasting?][
					n: complete-line line
					if n > 1 [
						string/rs-reset line
						exit
					]
					if n = 1 [c: -1]
				]

				#if OS <> 'Windows [if c = 27 [c: check-special]]

				switch c [
					KEY_ENTER [
						add-history line
						max: max + 1
						string/rs-reset saved-line
						exit
					]
					KEY_CTRL_H
					KEY_BACKSPACE [
						unless zero? line/head [
							line/head: line/head - 1
							string/remove-char line line/head
							if string/rs-tail? line [output?: no]
							refresh
							unless output? [erase-to-bottom]
						]
					]
					KEY_CTRL_B
					KEY_LEFT [
						unless zero? line/head [
							line/head: line/head - 1
							output?: no
							refresh
						]
					]
					KEY_CTRL_F
					KEY_RIGHT [
						if 0 < string/rs-length? line [
							line/head: line/head + 1
							output?: no
							refresh
						]
					]
					KEY_CTRL_N
					KEY_DOWN [
						either pos < 0 [
							string/rs-reset line
						][
							history/head: pos
							fetch-history
							pos: pos - 1
						]
						refresh
					]
					KEY_CTRL_P
					KEY_UP [
						either pos >= (max - 1) [
							string/rs-reset line
						][
							pos: pos + 1
							history/head: pos
							fetch-history
						]
						refresh
					]
					KEY_CTRL_A
					KEY_HOME [
						line/head: 0
						refresh
					]
					KEY_CTRL_E
					KEY_END [
						line/head: string/rs-abs-length? line
						refresh
					]
					KEY_DELETE [
						unless string/rs-tail? line [
							string/remove-char line line/head
							refresh
						]
					]
					KEY_CTRL_K [
						unless string/rs-tail? line [
							string/remove-part line line/head string/rs-length? line
							refresh
						]
					]
					KEY_CTRL_D [
						either string/rs-tail? line [
							if zero? line/head [
								string/rs-reset line
								string/append-char GET_BUFFER(line) as-integer #"q"
								exit
							]
						][
							string/remove-char line line/head
							refresh
						]
					]
					KEY_CTRL_C [
						string/rs-reset line
						string/append-char GET_BUFFER(line) as-integer #"q"
						exit
					]
					KEY_ESCAPE [
						string/append-char GET_BUFFER(line) c
						exit
					]
					default [
						if any [c > 31 c = KEY_TAB][
							#if OS = 'Windows [						;-- optimize for Windows
								if all [D800h <= c c <= DF00h][		;-- USC-4
									c: c and 03FFh << 10			;-- lead surrogate decoding
									c: (03FFh and fd-read) or c + 00010000h
								]
							]
							either string/rs-tail? line [
								string/append-char GET_BUFFER(line) c
								#if OS = 'Windows [					;-- optimize for Windows
									pbuffer: buffer
									emit-red-char c
									output-to-screen
									pbuffer: buffer
									output?: no
								]
							][
								string/insert-char GET_BUFFER(line) line/head c
							]
							line/head: line/head + 1
							refresh
						]
					]
				]
			]
			line/head: 0
		]

		stdin-readline: func [
			in-line  [red-string!]
			/local
				c	 [integer!]
				s	 [series!]
		][
			s: GET_BUFFER(in-line)
			while [true][
				#either OS = 'Windows [
					c: stdin-read
				][
					c: fd-read
				]
				either any [c = -1 c = as-integer lf][exit][
					s: string/append-char s c
				]
			]
		]

		edit: func [
			prompt-str	[red-string!]
			hidden?		[logic!]
		][
			either console? [
				hide-input?: hidden?
				console-edit prompt-str
				restore
				print-line ""
			][
				hide-input?: no
				stdin-readline input-line
			]
		]

		setup: func [
			line [red-string!]
			hist [red-block!]
		][
			copy-cell as red-value! line as red-value! input-line
			copy-cell as red-value! hist as red-value! history

			init-console		;-- enter raw mode
		]
	]
]

_set-buffer-history: routine ["Internal Use Only" line [string!] hist [block!]][
	terminal/setup line hist
]

_read-input: routine ["Internal Use Only" prompt [string!] hidden? [logic!]][
	terminal/edit prompt hidden?
]

_terminate-console: routine [][
	#if OS <> 'Windows [
	#if gui-console? = no [
		if terminal/init? [terminal/emit-string "^[[?2004l"]	;-- disable bracketed paste mode
	]]
]

ask: function [
	"Prompt the user for input"
	question [string!]
	/hide
	return:  [string!]
][
	buffer: make string! 1
	_set-buffer-history buffer head system/console/history
	_read-input question hide
	buffer
]

input: func ["Wait for console user input"] [ask ""]

input-stdin: routine [
	"Temporary function, internal use only"
	/local
		line	[red-value!]
		saved	[integer!]
		mode	[integer!]
][
	line: stack/arguments
	string/rs-make-at line 256
	terminal/stdin-readline as red-string! line
]

read-stdin: routine [
	"Temporary function, internal use only"
	buffer	[binary!]
	buflen	[integer!]
	/local
		sz	[integer!]
		s	[series!]
][
	sz: simple-io/read-data stdin binary/rs-head buffer buflen
	if sz > 0 [
		s: GET_BUFFER(buffer)
		s/tail: as cell! (as byte-ptr! s/tail) + sz
	]
]
