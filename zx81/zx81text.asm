;;; ----------------------------------------------------------------------
;;;   This header file sets up two macros for Sjasm.
;;;
;;;   - zx81text will reconfigure the map so that ASC produces ZX81 text.
;;;   - zx81inverse does the same, but in reverse video.
;;;
;;;   Including this file will also invoke zx81text for you.
;;; ----------------------------------------------------------------------
        macro   zx81text
        ascmap 0..255, => 0
        ascmap ' ', => 0
        ascmap 10, => $76
        ascmap '"', => 11
        ascmap '#', => 12
        ascmap '$', => 13
        ascmap ':', => 14
        ascmap '?', => 15
        ascmap '(', => 16
        ascmap ')', => 17
        ascmap '>', => 18
        ascmap '<', => 19
        ascmap '=', => 20
        ascmap '+', => 21
        ascmap '-', => 22
        ascmap '*', => 23
        ascmap '/', => 24
        ascmap ';', => 25
        ascmap ',', => 26
        ascmap '.', => 27
        ascmap '0'..'9', => 28
        ascmap 'A'..'Z', => 38
        endmacro

        macro   zx81inverse
        ascmap 0..255, => 0
        ascmap ' ', => 128
        ascmap 10, => $76
        ascmap '"', => 139
        ascmap '#', => 140
        ascmap '$', => 141
        ascmap ':', => 142
        ascmap '?', => 143
        ascmap '(', => 144
        ascmap ')', => 145
        ascmap '>', => 146
        ascmap '<', => 147
        ascmap '=', => 148
        ascmap '+', => 149
        ascmap '-', => 150
        ascmap '*', => 151
        ascmap '/', => 152
        ascmap ';', => 153
        ascmap ',', => 154
        ascmap '.', => 155
        ascmap '0'..'9', => 156
        ascmap 'A'..'Z', => 166
        endmacro

        zx81text
