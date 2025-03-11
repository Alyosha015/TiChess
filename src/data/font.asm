;Note: about 2 KB of compiled data
;see src\graphics\sprite.asm for format

FONT_LARGE_TABLE:
    rb 3 * 95

FONT_TABLE:
    dl FONT_CHAR_32
    dl FONT_CHAR_33
    dl FONT_CHAR_34
    dl FONT_CHAR_35
    dl FONT_CHAR_36
    dl FONT_CHAR_37
    dl FONT_CHAR_38
    dl FONT_CHAR_39
    dl FONT_CHAR_40
    dl FONT_CHAR_41
    dl FONT_CHAR_42
    dl FONT_CHAR_43
    dl FONT_CHAR_44
    dl FONT_CHAR_45
    dl FONT_CHAR_46
    dl FONT_CHAR_47
    dl FONT_CHAR_48
    dl FONT_CHAR_49
    dl FONT_CHAR_50
    dl FONT_CHAR_51
    dl FONT_CHAR_52
    dl FONT_CHAR_53
    dl FONT_CHAR_54
    dl FONT_CHAR_55
    dl FONT_CHAR_56
    dl FONT_CHAR_57
    dl FONT_CHAR_58
    dl FONT_CHAR_59
    dl FONT_CHAR_60
    dl FONT_CHAR_61
    dl FONT_CHAR_62
    dl FONT_CHAR_63
    dl FONT_CHAR_64
    dl FONT_CHAR_65
    dl FONT_CHAR_66
    dl FONT_CHAR_67
    dl FONT_CHAR_68
    dl FONT_CHAR_69
    dl FONT_CHAR_70
    dl FONT_CHAR_71
    dl FONT_CHAR_72
    dl FONT_CHAR_73
    dl FONT_CHAR_74
    dl FONT_CHAR_75
    dl FONT_CHAR_76
    dl FONT_CHAR_77
    dl FONT_CHAR_78
    dl FONT_CHAR_79
    dl FONT_CHAR_80
    dl FONT_CHAR_81
    dl FONT_CHAR_82
    dl FONT_CHAR_83
    dl FONT_CHAR_84
    dl FONT_CHAR_85
    dl FONT_CHAR_86
    dl FONT_CHAR_87
    dl FONT_CHAR_88
    dl FONT_CHAR_89
    dl FONT_CHAR_90
    dl FONT_CHAR_91
    dl FONT_CHAR_92
    dl FONT_CHAR_93
    dl FONT_CHAR_94
    dl FONT_CHAR_95
    dl FONT_CHAR_96
    dl FONT_CHAR_97
    dl FONT_CHAR_98
    dl FONT_CHAR_99
    dl FONT_CHAR_100
    dl FONT_CHAR_101
    dl FONT_CHAR_102
    dl FONT_CHAR_103
    dl FONT_CHAR_104
    dl FONT_CHAR_105
    dl FONT_CHAR_106
    dl FONT_CHAR_107
    dl FONT_CHAR_108
    dl FONT_CHAR_109
    dl FONT_CHAR_110
    dl FONT_CHAR_111
    dl FONT_CHAR_112
    dl FONT_CHAR_113
    dl FONT_CHAR_114
    dl FONT_CHAR_115
    dl FONT_CHAR_116
    dl FONT_CHAR_117
    dl FONT_CHAR_118
    dl FONT_CHAR_119
    dl FONT_CHAR_120
    dl FONT_CHAR_121
    dl FONT_CHAR_122
    dl FONT_CHAR_123
    dl FONT_CHAR_124
    dl FONT_CHAR_125
    dl FONT_CHAR_126

FONT_CHAR_32: ;
    db $05, $00
    db $00, $00, $00, $00, $00

FONT_CHAR_33: ;!
    db $02, $08
    db $00, $00, $00, $00, $00
    db $C0, $C0, $C0, $C0, $C0, $00, $C0, $C0

FONT_CHAR_34: ;"
    db $05, $03
    db $00, $00, $00, $00, $00
    db $D8, $D8, $90

FONT_CHAR_35: ;#
    db $09, $08
    db $00, $00, $00, $00, $00
    db $33, $00, $7F, $80, $7F, $80, $33, $00, $66, $00, $FF, $00, $FF, $00, $66, $00

FONT_CHAR_36: ;$
    db $06, $08
    db $00, $00, $00, $00, $00
    db $30, $7C, $C0, $F8, $7C, $0C, $F8, $30

FONT_CHAR_37: ;%
    db $08, $08
    db $00, $00, $00, $00, $00
    db $C3, $C7, $0E, $1C, $38, $70, $E3, $C3

FONT_CHAR_38: ;&
    db $07, $08
    db $00, $00, $00, $00, $00
    db $78, $CC, $EC, $7C, $F8, $DC, $CE, $76

FONT_CHAR_39: ;'
    db $02, $03
    db $00, $00, $00, $00, $00
    db $C0, $C0, $80

FONT_CHAR_40: ;(
    db $04, $08
    db $00, $00, $00, $00, $00
    db $30, $70, $60, $C0, $C0, $60, $70, $30

FONT_CHAR_41: ;)
    db $04, $08
    db $00, $00, $00, $00, $00
    db $C0, $E0, $60, $30, $30, $60, $E0, $C0

FONT_CHAR_42: ;*
    db $07, $05
    db $00, $00, $00, $00, $00
    db $6C, $38, $FE, $38, $6C

FONT_CHAR_43: ;+
    db $06, $06
    db $00, $01, $40, $01, $00
    db $30, $30, $FC, $FC, $30, $30

FONT_CHAR_44: ;,
    db $02, $03
    db $00, $05, $40, $06, $00
    db $C0, $C0, $80

FONT_CHAR_45: ;-
    db $06, $02
    db $00, $03, $C0, $03, $00
    db $FC, $FC

FONT_CHAR_46: ;.
    db $02, $02
    db $00, $05, $40, $06, $00
    db $C0, $C0

FONT_CHAR_47: ;/
    db $08, $08
    db $00, $00, $00, $00, $00
    db $03, $07, $0E, $1C, $38, $70, $E0, $C0

FONT_CHAR_48: ;0
    db $06, $08
    db $00, $00, $00, $00, $00
    db $78, $FC, $CC, $DC, $EC, $CC, $FC, $78

FONT_CHAR_49: ;1
    db $06, $08
    db $00, $00, $00, $00, $00
    db $30, $70, $70, $30, $30, $30, $FC, $FC

FONT_CHAR_50: ;2
    db $07, $08
    db $00, $00, $00, $00, $00
    db $7C, $FE, $06, $7E, $FC, $C0, $FE, $FE

FONT_CHAR_51: ;3
    db $07, $08
    db $00, $00, $00, $00, $00
    db $7C, $FE, $0E, $7C, $7C, $0E, $FE, $7C

FONT_CHAR_52: ;4
    db $07, $08
    db $00, $00, $00, $00, $00
    db $C6, $C6, $C6, $FE, $7E, $06, $06, $06

FONT_CHAR_53: ;5
    db $07, $08
    db $00, $00, $00, $00, $00
    db $FE, $FE, $C0, $FC, $FE, $06, $FE, $7C

FONT_CHAR_54: ;6
    db $07, $08
    db $00, $00, $00, $00, $00
    db $7C, $FE, $C0, $FC, $FE, $C6, $FE, $7C

FONT_CHAR_55: ;7
    db $07, $08
    db $00, $00, $00, $00, $00
    db $FE, $FE, $0E, $1C, $38, $30, $30, $30

FONT_CHAR_56: ;8
    db $07, $08
    db $00, $00, $00, $00, $00
    db $7C, $FE, $C6, $7C, $FE, $C6, $FE, $7C

FONT_CHAR_57: ;9
    db $07, $08
    db $00, $00, $00, $00, $00
    db $7C, $FE, $C6, $FE, $7E, $06, $FE, $7C

FONT_CHAR_58: ;:
    db $02, $06
    db $00, $01, $40, $01, $00
    db $C0, $C0, $00, $00, $C0, $C0

FONT_CHAR_59: ;;
    db $02, $07
    db $00, $01, $40, $01, $00
    db $C0, $C0, $00, $00, $C0, $C0, $80

FONT_CHAR_60: ;<
    db $04, $06
    db $00, $01, $40, $01, $00
    db $30, $60, $C0, $C0, $60, $30

FONT_CHAR_61: ;=
    db $06, $05
    db $00, $02, $80, $02, $00
    db $FC, $FC, $00, $FC, $FC

FONT_CHAR_62: ;>
    db $04, $06
    db $00, $01, $40, $01, $00
    db $C0, $60, $30, $30, $60, $C0

FONT_CHAR_63: ;?
    db $06, $08
    db $00, $00, $00, $00, $00
    db $78, $FC, $CC, $0C, $18, $30, $00, $30

FONT_CHAR_64: ;@
    db $07, $08
    db $00, $00, $00, $00, $00
    db $7C, $FE, $C6, $DE, $DE, $C0, $FE, $7C

FONT_CHAR_65: ;A
    db $08, $08
    db $00, $00, $00, $00, $00
    db $18, $18, $3C, $3C, $66, $7E, $FF, $C3

FONT_CHAR_66: ;B
    db $07, $08
    db $00, $00, $00, $00, $00
    db $FC, $FE, $C6, $FE, $FC, $C6, $FE, $FC

FONT_CHAR_67: ;C
    db $08, $08
    db $00, $00, $00, $00, $00
    db $3C, $7E, $E7, $C0, $C0, $E7, $7E, $3C

FONT_CHAR_68: ;D
    db $07, $08
    db $00, $00, $00, $00, $00
    db $F8, $FC, $CE, $C6, $C6, $CE, $FC, $F8

FONT_CHAR_69: ;E
    db $06, $08
    db $00, $00, $00, $00, $00
    db $FC, $FC, $C0, $F8, $F8, $C0, $FC, $FC

FONT_CHAR_70: ;F
    db $06, $08
    db $00, $00, $00, $00, $00
    db $FC, $FC, $C0, $F8, $F8, $C0, $C0, $C0

FONT_CHAR_71: ;G
    db $08, $08
    db $00, $00, $00, $00, $00
    db $3C, $7E, $E7, $C0, $CF, $E7, $7E, $3C

FONT_CHAR_72: ;H
    db $07, $08
    db $00, $00, $00, $00, $00
    db $C6, $C6, $C6, $FE, $FE, $C6, $C6, $C6

FONT_CHAR_73: ;I
    db $02, $08
    db $00, $00, $00, $00, $00
    db $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0

FONT_CHAR_74: ;J
    db $06, $08
    db $00, $00, $00, $00, $00
    db $3C, $3C, $0C, $0C, $CC, $CC, $FC, $78

FONT_CHAR_75: ;K
    db $06, $08
    db $00, $00, $00, $00, $00
    db $CC, $DC, $F8, $F0, $F0, $F8, $DC, $CC

FONT_CHAR_76: ;L
    db $06, $08
    db $00, $00, $00, $00, $00
    db $C0, $C0, $C0, $C0, $C0, $C0, $FC, $FC

FONT_CHAR_77: ;M
    db $09, $08
    db $00, $00, $00, $00, $00
    db $80, $80, $C1, $80, $E3, $80, $F7, $80, $FF, $80, $DD, $80, $C9, $80, $C1, $80

FONT_CHAR_78: ;N
    db $07, $08
    db $00, $00, $00, $00, $00
    db $C6, $E6, $F6, $FE, $DE, $CE, $C6, $C6

FONT_CHAR_79: ;O
    db $08, $08
    db $00, $00, $00, $00, $00
    db $3C, $7E, $E7, $C3, $C3, $E7, $7E, $3C

FONT_CHAR_80: ;P
    db $07, $08
    db $00, $00, $00, $00, $00
    db $FC, $FE, $C6, $C6, $FE, $FC, $C0, $C0

FONT_CHAR_81: ;Q
    db $08, $08
    db $00, $00, $00, $00, $00
    db $3C, $7E, $E7, $C3, $C3, $E6, $7F, $3B

FONT_CHAR_82: ;R
    db $07, $08
    db $00, $00, $00, $00, $00
    db $FC, $FE, $C6, $C6, $FC, $FE, $C6, $C6

FONT_CHAR_83: ;S
    db $07, $08
    db $00, $00, $00, $00, $00
    db $7C, $FE, $C0, $FC, $7E, $06, $FE, $7C

FONT_CHAR_84: ;T
    db $06, $08
    db $00, $00, $00, $00, $00
    db $FC, $FC, $30, $30, $30, $30, $30, $30

FONT_CHAR_85: ;U
    db $07, $08
    db $00, $00, $00, $00, $00
    db $C6, $C6, $C6, $C6, $C6, $C6, $FE, $7C

FONT_CHAR_86: ;V
    db $09, $08
    db $00, $00, $00, $00, $00
    db $C1, $80, $63, $00, $63, $00, $36, $00, $36, $00, $1C, $00, $1C, $00, $08, $00

FONT_CHAR_87: ;W
    db $09, $08
    db $00, $00, $00, $00, $00
    db $C1, $80, $C1, $80, $C9, $80, $DD, $80, $FF, $80, $F7, $80, $E3, $80, $C1, $80

FONT_CHAR_88: ;X
    db $07, $08
    db $00, $00, $00, $00, $00
    db $C6, $C6, $EE, $7C, $7C, $EE, $C6, $C6

FONT_CHAR_89: ;Y
    db $08, $08
    db $00, $00, $00, $00, $00
    db $C3, $C3, $E7, $7E, $3C, $18, $18, $18

FONT_CHAR_90: ;Z
    db $08, $08
    db $00, $00, $00, $00, $00
    db $FF, $FF, $0E, $1C, $38, $70, $FF, $FF

FONT_CHAR_91: ;[
    db $04, $08
    db $00, $00, $00, $00, $00
    db $F0, $F0, $C0, $C0, $C0, $C0, $F0, $F0

FONT_CHAR_92: ;\
    db $08, $08
    db $00, $00, $00, $00, $00
    db $C0, $E0, $70, $38, $1C, $0E, $07, $03

FONT_CHAR_93: ;]
    db $04, $08
    db $00, $00, $00, $00, $00
    db $F0, $F0, $30, $30, $30, $30, $F0, $F0

FONT_CHAR_94: ;^
    db $05, $04
    db $00, $00, $00, $00, $00
    db $20, $70, $D8, $88

FONT_CHAR_95: ;_
    db $09, $02
    db $00, $06, $80, $07, $00
    db $FF, $80, $FF, $80

FONT_CHAR_96: ;`
    db $04, $04
    db $00, $00, $00, $00, $00
    db $C0, $E0, $70, $30

FONT_CHAR_97: ;a
    db $06, $05
    db $00, $03, $C0, $03, $00
    db $78, $0C, $7C, $CC, $78

FONT_CHAR_98: ;b
    db $06, $08
    db $00, $00, $00, $00, $00
    db $C0, $C0, $C0, $F8, $CC, $CC, $CC, $F8

FONT_CHAR_99: ;c
    db $06, $05
    db $00, $03, $C0, $03, $00
    db $78, $CC, $C0, $CC, $78

FONT_CHAR_100: ;d
    db $06, $08
    db $00, $00, $00, $00, $00
    db $0C, $0C, $0C, $7C, $CC, $CC, $CC, $7C

FONT_CHAR_101: ;e
    db $06, $05
    db $00, $03, $C0, $03, $00
    db $78, $CC, $F8, $C0, $78

FONT_CHAR_102: ;f
    db $06, $08
    db $00, $00, $00, $00, $00
    db $38, $6C, $60, $F8, $60, $60, $60, $60

FONT_CHAR_103: ;g
    db $06, $06
    db $00, $03, $C0, $03, $00
    db $7C, $CC, $CC, $7C, $0C, $F8

FONT_CHAR_104: ;h
    db $06, $08
    db $00, $00, $00, $00, $00
    db $C0, $C0, $C0, $F8, $FC, $CC, $CC, $CC

FONT_CHAR_105: ;i
    db $02, $07
    db $00, $01, $40, $01, $00
    db $C0, $C0, $00, $C0, $C0, $C0, $C0

FONT_CHAR_106: ;j
    db $06, $08
    db $00, $01, $40, $01, $00
    db $0C, $0C, $00, $0C, $0C, $0C, $CC, $78

FONT_CHAR_107: ;k
    db $06, $08
    db $00, $00, $00, $00, $00
    db $C0, $C0, $C0, $CC, $D8, $F0, $D8, $CC

FONT_CHAR_108: ;l
    db $02, $08
    db $00, $00, $00, $00, $00
    db $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0

FONT_CHAR_109: ;m
    db $07, $05
    db $00, $03, $C0, $03, $00
    db $CC, $FE, $D6, $C6, $C6

FONT_CHAR_110: ;n
    db $06, $05
    db $00, $03, $C0, $03, $00
    db $F8, $CC, $CC, $CC, $CC

FONT_CHAR_111: ;o
    db $06, $05
    db $00, $03, $C0, $03, $00
    db $78, $CC, $CC, $CC, $78

FONT_CHAR_112: ;p
    db $06, $06
    db $00, $03, $C0, $03, $00
    db $F8, $CC, $CC, $F8, $C0, $C0

FONT_CHAR_113: ;q
    db $06, $06
    db $00, $03, $C0, $03, $00
    db $7C, $CC, $CC, $7C, $0C, $0C

FONT_CHAR_114: ;r
    db $06, $05
    db $00, $03, $C0, $03, $00
    db $F8, $CC, $C0, $C0, $C0

FONT_CHAR_115: ;s
    db $06, $05
    db $00, $03, $C0, $03, $00
    db $7C, $C0, $78, $0C, $F8

FONT_CHAR_116: ;t
    db $06, $08
    db $00, $00, $00, $00, $00
    db $30, $30, $30, $FC, $30, $30, $30, $30

FONT_CHAR_117: ;u
    db $06, $05
    db $00, $03, $C0, $03, $00
    db $CC, $CC, $CC, $CC, $78

FONT_CHAR_118: ;v
    db $07, $05
    db $00, $03, $C0, $03, $00
    db $C6, $6C, $6C, $38, $10

FONT_CHAR_119: ;w
    db $07, $05
    db $00, $03, $C0, $03, $00
    db $C6, $D6, $D6, $7C, $6C

FONT_CHAR_120: ;x
    db $05, $05
    db $00, $03, $C0, $03, $00
    db $D8, $70, $20, $70, $D8

FONT_CHAR_121: ;y
    db $06, $06
    db $00, $03, $C0, $03, $00
    db $CC, $CC, $CC, $7C, $0C, $F8

FONT_CHAR_122: ;z
    db $06, $05
    db $00, $03, $C0, $03, $00
    db $FC, $18, $30, $60, $FC

FONT_CHAR_123: ;{
    db $04, $08
    db $01, $00, $01, $00, $00
    db $30, $60, $60, $C0, $60, $60, $60, $30

FONT_CHAR_124: ;|
    db $02, $08
    db $00, $00, $00, $00, $00
    db $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0

FONT_CHAR_125: ;}
    db $04, $08
    db $00, $00, $00, $00, $00
    db $C0, $60, $60, $30, $60, $60, $60, $C0

FONT_CHAR_126: ;~
    db $06, $03
    db $00, $01, $40, $01, $00
    db $64, $FC, $98
