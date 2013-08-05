.include 'cclass.pasm'
.include 'except_severity.pasm'
.include 'except_types.pasm'
.include 'iglobals.pasm'
.include 'interpinfo.pasm'
.include 'iterator.pasm'
.include 'sysinfo.pasm'
.include 'stat.pasm'
.include 'datatypes.pasm'
.include 'libpaths.pasm'
.include 'nqp_const.pir'
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_21_1372180368.15198") :anon :lex
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 1
    .param pmc __args__ :slurpy 
    .const 'Sub' $P5003 = 'cuid_20_1372180368.15198' 
    capture_lex $P5003 
    .const 'Sub' $P5001 = 'cuid_20_1372180368.15198' 
    capture_lex $P5001
    $P5002 = $P5001()
    .return ($P5002) 
.end
.loadlib "nqp_group"
.loadlib "nqp_ops"
.loadlib "perl6_ops"
.loadlib "bit_ops"
.loadlib "math_ops"
.loadlib "trans_ops"
.loadlib "io_ops"
.loadlib "obscure_ops"
.loadlib "os"
.loadlib "file"
.loadlib "sys_ops"
.loadlib "nqp_bigint_ops"
.loadlib "nqp_dyncall_ops"
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_20_1372180368.15198") :anon :lex :outer("cuid_21_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 1
    .const 'Sub' $P5002 = 'cuid_19_1372180368.15198' 
    capture_lex $P5002 
    .lex "GLOBALish", $P101 
    .lex "EXPORT", $P102 
    .lex "$?PACKAGE", $P103 
    .lex "::?PACKAGE", $P104 
    .lex "$_", $P105 
    .lex "$/", $P106 
    .lex "$!", $P107 
    .lex "JSON", $P108 
    .lex "$=pod", $P109 
    .lex "!UNIT_MARKER", $P110 
    .local pmc ctxsave 
    find_dynamic_lex $P5001, "$*CTXSAVE"
    set ctxsave, $P5001
    isnull $I5001, ctxsave
    if $I5001 goto unless10_end11 
    can $I5002, ctxsave, "ctxsave"
    perl6_box_int $P5004, $I5002
    set $P5003, $P5004
    unless $I5002 goto if11_end13 
    $P5002 = ctxsave."ctxsave"()
    set $P5003, $P5002
  if11_end13:
  unless10_end11:
    nqp_get_sc_object $P5001, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 132
    .const 'Sub' $P5002 = 'cuid_19_1372180368.15198' 
    capture_lex $P5002
    $P5003 = $P5002()
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 10
    .return ($P5004) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_19_1372180368.15198") :anon :lex :outer("cuid_20_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 2
    .const 'Sub' $P5037 = 'cuid_1_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_2_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_3_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_4_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_5_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_6_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_7_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_8_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_9_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_10_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_11_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_12_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_13_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_14_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_16_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_17_1372180368.15198' 
    capture_lex $P5037 
    .const 'Sub' $P5037 = 'cuid_18_1372180368.15198' 
    capture_lex $P5037 
    .lex "$?PACKAGE", $P101 
    .lex "::?PACKAGE", $P102 
    .lex "$?CLASS", $P103 
    .lex "::?CLASS", $P104 
    .lex "$_", $P105 
    nqp_getlexouter $P5001, "$_"
    set $P105, $P5001
    .const 'Sub' $P5002 = 'cuid_1_1372180368.15198' 
    capture_lex $P5002
    .const 'Sub' $P5003 = 'cuid_2_1372180368.15198' 
    capture_lex $P5003
    .const 'Sub' $P5004 = 'cuid_3_1372180368.15198' 
    capture_lex $P5004
    .const 'Sub' $P5005 = 'cuid_4_1372180368.15198' 
    capture_lex $P5005
    .const 'Sub' $P5006 = 'cuid_5_1372180368.15198' 
    capture_lex $P5006
    .const 'Sub' $P5007 = 'cuid_6_1372180368.15198' 
    capture_lex $P5007
    .const 'Sub' $P5008 = 'cuid_7_1372180368.15198' 
    capture_lex $P5008
    .const 'Sub' $P5009 = 'cuid_8_1372180368.15198' 
    capture_lex $P5009
    .const 'Sub' $P5010 = 'cuid_9_1372180368.15198' 
    capture_lex $P5010
    .const 'Sub' $P5011 = 'cuid_10_1372180368.15198' 
    capture_lex $P5011
    .const 'Sub' $P5012 = 'cuid_11_1372180368.15198' 
    capture_lex $P5012
    .const 'Sub' $P5013 = 'cuid_12_1372180368.15198' 
    capture_lex $P5013
    .const 'Sub' $P5014 = 'cuid_13_1372180368.15198' 
    capture_lex $P5014
    .const 'Sub' $P5015 = 'cuid_14_1372180368.15198' 
    capture_lex $P5015
    .const 'Sub' $P5016 = 'cuid_16_1372180368.15198' 
    capture_lex $P5016
    .const 'Sub' $P5017 = 'cuid_17_1372180368.15198' 
    capture_lex $P5017
    .const 'Sub' $P5018 = 'cuid_18_1372180368.15198' 
    capture_lex $P5018
.annotate 'line', 4
    null $P5019
    null $P5020
    null $P5021
    null $P5022
    null $P5023
    null $P5024
    null $P5025
    null $P5026
    null $P5027
    null $P5028
    null $P5029
    null $P5030
    null $P5031
    null $P5032
    null $P5033
    null $P5034
    nqp_get_sc_object $P5035, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 124
    $P5036 = $P5035."clone"()
    perl6_capture_lex $P5036
    .return ($P5036) 
.end
.HLL "perl6"
.namespace []
.sub "TOP" :subid("cuid_1_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 4
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx12_start
    .local string rx12_tgt
    .local int rx12_pos
    .local int rx12_off
    .local int rx12_eos
    .local int rx12_rep
    .local pmc rx12_cur
    .local pmc rx12_curclass
    .local pmc rx12_bstack
    .local pmc rx12_cstack
    rx12_start = self."!cursor_start_all"()
    set rx12_cur, rx12_start[0]
    set rx12_tgt, rx12_start[1]
    set rx12_pos, rx12_start[2]
    set rx12_curclass, rx12_start[3]
    set rx12_bstack, rx12_start[4]
    set $I19, rx12_start[5]
    store_lex unicode:"$\x{a2}", rx12_cur
    length rx12_eos, rx12_tgt
    eq $I19, 1, rx12_restart16
    gt rx12_pos, rx12_eos, rx12_fail17
    repr_get_attr_int $I11, self, rx12_curclass, "$!from"
    ne $I11, -1, rxscan13_done23
    goto rxscan13_scan22
  rxscan13_loop21:
    inc rx12_pos
    gt rx12_pos, rx12_eos, rx12_fail17
    repr_bind_attr_int rx12_cur, rx12_curclass, "$!from", rx12_pos
  rxscan13_scan22:
    nqp_rxmark rx12_bstack, rxscan13_loop21, rx12_pos, 0
  rxscan13_done23:
    ne rx12_pos, 0, rx12_fail17
    nqp_rxmark rx12_bstack, rxquantr15_done26, rx12_pos, 0
  rxquantr15_loop25:
    ge rx12_pos, rx12_eos, rx12_fail17
    is_cclass $I11, .CCLASS_WHITESPACE, rx12_tgt, rx12_pos
    unless $I11, rx12_fail17
    add rx12_pos, 1
    nqp_rxpeek $I19, rx12_bstack, rxquantr15_done26
    inc $I19
    inc $I19
    set rx12_rep, rx12_bstack[$I19]
    nqp_rxcommit rx12_bstack, rxquantr15_done26
    inc rx12_rep
    nqp_rxmark rx12_bstack, rxquantr15_done26, rx12_pos, rx12_rep
    goto rxquantr15_loop25
  rxquantr15_done26:
    new $P11, "ResizableIntegerArray"
    nqp_push_label $P11, alt16_028
    nqp_push_label $P11, alt16_130
    nqp_rxmark rx12_bstack, alt16_end27, -1, 0
    rx12_cur."!alt"(rx12_pos, "alt_nfa__1_1372180368.61486", $P11)
    goto rx12_fail17
  alt16_028:
    repr_bind_attr_int rx12_cur, rx12_curclass, "$!pos", rx12_pos
    $P11 = rx12_cur."object"()
    repr_get_attr_int $I11, $P11, rx12_curclass, "$!pos"
    lt $I11, 0, rx12_fail17
    nqp_rxmark rx12_bstack, rxsubrule17_pass29, -1, 0
  rxsubrule17_pass29:
    rx12_cstack = rx12_cur."!cursor_capture"($P11, "object")
    repr_get_attr_int rx12_pos, $P11, rx12_curclass, "$!pos"
    goto alt16_end27
  alt16_130:
    repr_bind_attr_int rx12_cur, rx12_curclass, "$!pos", rx12_pos
    $P11 = rx12_cur."array"()
    repr_get_attr_int $I11, $P11, rx12_curclass, "$!pos"
    lt $I11, 0, rx12_fail17
    nqp_rxmark rx12_bstack, rxsubrule18_pass31, -1, 0
  rxsubrule18_pass31:
    rx12_cstack = rx12_cur."!cursor_capture"($P11, "array")
    repr_get_attr_int rx12_pos, $P11, rx12_curclass, "$!pos"
    goto alt16_end27
  alt16_end27:
    nqp_rxcommit rx12_bstack, alt16_end27
    nqp_rxmark rx12_bstack, rxquantr19_done33, rx12_pos, 0
  rxquantr19_loop32:
    ge rx12_pos, rx12_eos, rx12_fail17
    is_cclass $I11, .CCLASS_WHITESPACE, rx12_tgt, rx12_pos
    unless $I11, rx12_fail17
    add rx12_pos, 1
    nqp_rxpeek $I19, rx12_bstack, rxquantr19_done33
    inc $I19
    inc $I19
    set rx12_rep, rx12_bstack[$I19]
    nqp_rxcommit rx12_bstack, rxquantr19_done33
    inc rx12_rep
    nqp_rxmark rx12_bstack, rxquantr19_done33, rx12_pos, rx12_rep
    goto rxquantr19_loop32
  rxquantr19_done33:
    lt rx12_pos, rx12_eos, rx12_fail17
    rx12_cur."!cursor_pass"(rx12_pos, "TOP", 'backtrack'=>1)
    .return (rx12_cur)
  rx12_restart16:
    repr_get_attr_obj rx12_cstack, rx12_cur, rx12_curclass, "$!cstack"
  rx12_fail17:
    unless rx12_bstack, rx12_done15
    pop $I19, rx12_bstack
    if_null rx12_cstack, rx12_cstack_done20
    unless rx12_cstack, rx12_cstack_done20
    dec $I19
    set $P11, rx12_cstack[$I19]
  rx12_cstack_done20:
    pop rx12_rep, rx12_bstack
    pop rx12_pos, rx12_bstack
    pop $I19, rx12_bstack
    lt rx12_pos, -1, rx12_done15
    lt rx12_pos, 0, rx12_fail17
    eq $I19, 0, rx12_fail17
    nqp_islist $I20, rx12_cstack
    unless $I20, rx12_jump18
    elements $I18, rx12_bstack
    le $I18, 0, rx12_cut19
    dec $I18
    set $I18, rx12_bstack[$I18]
  rx12_cut19:
    assign rx12_cstack, $I18
  rx12_jump18:
    jump $I19
  rx12_done15:
    rx12_cur."!cursor_fail"()
    .return (rx12_cur) 
.end
.HLL "perl6"
.namespace []
.sub "object" :subid("cuid_2_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 5
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx21_start
    .local string rx21_tgt
    .local int rx21_pos
    .local int rx21_off
    .local int rx21_eos
    .local int rx21_rep
    .local pmc rx21_cur
    .local pmc rx21_curclass
    .local pmc rx21_bstack
    .local pmc rx21_cstack
    rx21_start = self."!cursor_start_all"()
    set rx21_cur, rx21_start[0]
    set rx21_tgt, rx21_start[1]
    set rx21_pos, rx21_start[2]
    set rx21_curclass, rx21_start[3]
    set rx21_bstack, rx21_start[4]
    set $I19, rx21_start[5]
    store_lex unicode:"$\x{a2}", rx21_cur
    length rx21_eos, rx21_tgt
    eq $I19, 1, rx21_restart37
    gt rx21_pos, rx21_eos, rx21_fail38
    repr_get_attr_int $I11, self, rx21_curclass, "$!from"
    ne $I11, -1, rxscan22_done44
    goto rxscan22_scan43
  rxscan22_loop42:
    inc rx21_pos
    gt rx21_pos, rx21_eos, rx21_fail38
    repr_bind_attr_int rx21_cur, rx21_curclass, "$!from", rx21_pos
  rxscan22_scan43:
    nqp_rxmark rx21_bstack, rxscan22_loop42, rx21_pos, 0
  rxscan22_done44:
    repr_bind_attr_int rx21_cur, rx21_curclass, "$!pos", rx21_pos
    $P11 = rx21_cur."ws"()
    repr_get_attr_int $I11, $P11, rx21_curclass, "$!pos"
    lt $I11, 0, rx21_fail38
    repr_get_attr_int rx21_pos, $P11, rx21_curclass, "$!pos"
    add $I11, rx21_pos, 1
    gt $I11, rx21_eos, rx21_fail38
    substr $S10, rx21_tgt, rx21_pos, 1
    ne $S10, ucs4:"{", rx21_fail38
    add rx21_pos, 1
    repr_bind_attr_int rx21_cur, rx21_curclass, "$!pos", rx21_pos
    $P11 = rx21_cur."ws"()
    repr_get_attr_int $I11, $P11, rx21_curclass, "$!pos"
    lt $I11, 0, rx21_fail38
    repr_get_attr_int rx21_pos, $P11, rx21_curclass, "$!pos"
    repr_bind_attr_int rx21_cur, rx21_curclass, "$!pos", rx21_pos
    $P11 = rx21_cur."pairlist"()
    repr_get_attr_int $I11, $P11, rx21_curclass, "$!pos"
    lt $I11, 0, rx21_fail38
    nqp_rxmark rx21_bstack, rxsubrule25_pass47, -1, 0
  rxsubrule25_pass47:
    rx21_cstack = rx21_cur."!cursor_capture"($P11, "pairlist")
    repr_get_attr_int rx21_pos, $P11, rx21_curclass, "$!pos"
  alt26_049:
    nqp_rxmark rx21_bstack, alt26_150, rx21_pos, 0
    add $I11, rx21_pos, 1
    gt $I11, rx21_eos, rx21_fail38
    substr $S10, rx21_tgt, rx21_pos, 1
    ne $S10, ucs4:"}", rx21_fail38
    add rx21_pos, 1
    goto alt26_end48
  alt26_150:
    repr_bind_attr_int rx21_cur, rx21_curclass, "$!pos", rx21_pos
    $P11 = rx21_cur."FAILGOAL"("'}'")
    repr_get_attr_int $I11, $P11, rx21_curclass, "$!pos"
    lt $I11, 0, rx21_fail38
    goto rxsubrule27_pass51
  rxsubrule27_back52:
    $P11 = $P11."!cursor_next"()
    repr_get_attr_int $I11, $P11, rx21_curclass, "$!pos"
    lt $I11, 0, rx21_fail38
  rxsubrule27_pass51:
    rx21_cstack = rx21_cur."!cursor_push_cstack"($P11)
    set_addr $I11, rxsubrule27_back52
    push rx21_bstack, $I11
    push rx21_bstack, 0
    push rx21_bstack, rx21_pos
    elements $I11, rx21_cstack
    push rx21_bstack, $I11
    repr_get_attr_int rx21_pos, $P11, rx21_curclass, "$!pos"
  alt26_end48:
    repr_bind_attr_int rx21_cur, rx21_curclass, "$!pos", rx21_pos
    $P11 = rx21_cur."ws"()
    repr_get_attr_int $I11, $P11, rx21_curclass, "$!pos"
    lt $I11, 0, rx21_fail38
    repr_get_attr_int rx21_pos, $P11, rx21_curclass, "$!pos"
    rx21_cur."!cursor_pass"(rx21_pos, "object", 'backtrack'=>1)
    .return (rx21_cur)
  rx21_restart37:
    repr_get_attr_obj rx21_cstack, rx21_cur, rx21_curclass, "$!cstack"
  rx21_fail38:
    unless rx21_bstack, rx21_done36
    pop $I19, rx21_bstack
    if_null rx21_cstack, rx21_cstack_done41
    unless rx21_cstack, rx21_cstack_done41
    dec $I19
    set $P11, rx21_cstack[$I19]
  rx21_cstack_done41:
    pop rx21_rep, rx21_bstack
    pop rx21_pos, rx21_bstack
    pop $I19, rx21_bstack
    lt rx21_pos, -1, rx21_done36
    lt rx21_pos, 0, rx21_fail38
    eq $I19, 0, rx21_fail38
    nqp_islist $I20, rx21_cstack
    unless $I20, rx21_jump39
    elements $I18, rx21_bstack
    le $I18, 0, rx21_cut40
    dec $I18
    set $I18, rx21_bstack[$I18]
  rx21_cut40:
    assign rx21_cstack, $I18
  rx21_jump39:
    jump $I19
  rx21_done36:
    rx21_cur."!cursor_fail"()
    .return (rx21_cur) 
.end
.HLL "perl6"
.namespace []
.sub "pairlist" :subid("cuid_3_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 6
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx29_start
    .local string rx29_tgt
    .local int rx29_pos
    .local int rx29_off
    .local int rx29_eos
    .local int rx29_rep
    .local pmc rx29_cur
    .local pmc rx29_curclass
    .local pmc rx29_bstack
    .local pmc rx29_cstack
    rx29_start = self."!cursor_start_all"()
    set rx29_cur, rx29_start[0]
    set rx29_tgt, rx29_start[1]
    set rx29_pos, rx29_start[2]
    set rx29_curclass, rx29_start[3]
    set rx29_bstack, rx29_start[4]
    set $I19, rx29_start[5]
    store_lex unicode:"$\x{a2}", rx29_cur
    length rx29_eos, rx29_tgt
    eq $I19, 1, rx29_restart56
    gt rx29_pos, rx29_eos, rx29_fail57
    repr_get_attr_int $I11, self, rx29_curclass, "$!from"
    ne $I11, -1, rxscan30_done63
    goto rxscan30_scan62
  rxscan30_loop61:
    inc rx29_pos
    gt rx29_pos, rx29_eos, rx29_fail57
    repr_bind_attr_int rx29_cur, rx29_curclass, "$!from", rx29_pos
  rxscan30_scan62:
    nqp_rxmark rx29_bstack, rxscan30_loop61, rx29_pos, 0
  rxscan30_done63:
    repr_bind_attr_int rx29_cur, rx29_curclass, "$!pos", rx29_pos
    $P11 = rx29_cur."ws"()
    repr_get_attr_int $I11, $P11, rx29_curclass, "$!pos"
    lt $I11, 0, rx29_fail57
    repr_get_attr_int rx29_pos, $P11, rx29_curclass, "$!pos"
    repr_bind_attr_int rx29_cur, rx29_curclass, "$!pos", rx29_pos
    $P11 = rx29_cur."ws"()
    repr_get_attr_int $I11, $P11, rx29_curclass, "$!pos"
    lt $I11, 0, rx29_fail57
    repr_get_attr_int rx29_pos, $P11, rx29_curclass, "$!pos"
    nqp_rxmark rx29_bstack, rxquantr34_done68, rx29_pos, 0
  rxquantr34_loop67:
    repr_bind_attr_int rx29_cur, rx29_curclass, "$!pos", rx29_pos
    $P11 = rx29_cur."pair"()
    repr_get_attr_int $I11, $P11, rx29_curclass, "$!pos"
    lt $I11, 0, rx29_fail57
    goto rxsubrule35_pass69
  rxsubrule35_back70:
    $P11 = $P11."!cursor_next"()
    repr_get_attr_int $I11, $P11, rx29_curclass, "$!pos"
    lt $I11, 0, rx29_fail57
  rxsubrule35_pass69:
    rx29_cstack = rx29_cur."!cursor_capture"($P11, "pair")
    set_addr $I11, rxsubrule35_back70
    push rx29_bstack, $I11
    push rx29_bstack, 0
    push rx29_bstack, rx29_pos
    elements $I11, rx29_cstack
    push rx29_bstack, $I11
    repr_get_attr_int rx29_pos, $P11, rx29_curclass, "$!pos"
    nqp_rxpeek $I19, rx29_bstack, rxquantr34_done68
    inc $I19
    inc $I19
    set rx29_rep, rx29_bstack[$I19]
    nqp_rxcommit rx29_bstack, rxquantr34_done68
    inc rx29_rep
    nqp_rxmark rx29_bstack, rxquantr34_done68, rx29_pos, rx29_rep
    add $I11, rx29_pos, 1
    gt $I11, rx29_eos, rx29_fail57
    substr $S10, rx29_tgt, rx29_pos, 1
    ne $S10, ucs4:",", rx29_fail57
    add rx29_pos, 1
    goto rxquantr34_loop67
  rxquantr34_done68:
    repr_bind_attr_int rx29_cur, rx29_curclass, "$!pos", rx29_pos
    $P11 = rx29_cur."ws"()
    repr_get_attr_int $I11, $P11, rx29_curclass, "$!pos"
    lt $I11, 0, rx29_fail57
    repr_get_attr_int rx29_pos, $P11, rx29_curclass, "$!pos"
    rx29_cur."!cursor_pass"(rx29_pos, "pairlist", 'backtrack'=>1)
    .return (rx29_cur)
  rx29_restart56:
    repr_get_attr_obj rx29_cstack, rx29_cur, rx29_curclass, "$!cstack"
  rx29_fail57:
    unless rx29_bstack, rx29_done55
    pop $I19, rx29_bstack
    if_null rx29_cstack, rx29_cstack_done60
    unless rx29_cstack, rx29_cstack_done60
    dec $I19
    set $P11, rx29_cstack[$I19]
  rx29_cstack_done60:
    pop rx29_rep, rx29_bstack
    pop rx29_pos, rx29_bstack
    pop $I19, rx29_bstack
    lt rx29_pos, -1, rx29_done55
    lt rx29_pos, 0, rx29_fail57
    eq $I19, 0, rx29_fail57
    nqp_islist $I20, rx29_cstack
    unless $I20, rx29_jump58
    elements $I18, rx29_bstack
    le $I18, 0, rx29_cut59
    dec $I18
    set $I18, rx29_bstack[$I18]
  rx29_cut59:
    assign rx29_cstack, $I18
  rx29_jump58:
    jump $I19
  rx29_done55:
    rx29_cur."!cursor_fail"()
    .return (rx29_cur) 
.end
.HLL "perl6"
.namespace []
.sub "pair" :subid("cuid_4_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 7
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx37_start
    .local string rx37_tgt
    .local int rx37_pos
    .local int rx37_off
    .local int rx37_eos
    .local int rx37_rep
    .local pmc rx37_cur
    .local pmc rx37_curclass
    .local pmc rx37_bstack
    .local pmc rx37_cstack
    rx37_start = self."!cursor_start_all"()
    set rx37_cur, rx37_start[0]
    set rx37_tgt, rx37_start[1]
    set rx37_pos, rx37_start[2]
    set rx37_curclass, rx37_start[3]
    set rx37_bstack, rx37_start[4]
    set $I19, rx37_start[5]
    store_lex unicode:"$\x{a2}", rx37_cur
    length rx37_eos, rx37_tgt
    eq $I19, 1, rx37_restart74
    gt rx37_pos, rx37_eos, rx37_fail75
    repr_get_attr_int $I11, self, rx37_curclass, "$!from"
    ne $I11, -1, rxscan38_done81
    goto rxscan38_scan80
  rxscan38_loop79:
    inc rx37_pos
    gt rx37_pos, rx37_eos, rx37_fail75
    repr_bind_attr_int rx37_cur, rx37_curclass, "$!from", rx37_pos
  rxscan38_scan80:
    nqp_rxmark rx37_bstack, rxscan38_loop79, rx37_pos, 0
  rxscan38_done81:
    repr_bind_attr_int rx37_cur, rx37_curclass, "$!pos", rx37_pos
    $P11 = rx37_cur."ws"()
    repr_get_attr_int $I11, $P11, rx37_curclass, "$!pos"
    lt $I11, 0, rx37_fail75
    repr_get_attr_int rx37_pos, $P11, rx37_curclass, "$!pos"
    repr_bind_attr_int rx37_cur, rx37_curclass, "$!pos", rx37_pos
    $P11 = rx37_cur."ws"()
    repr_get_attr_int $I11, $P11, rx37_curclass, "$!pos"
    lt $I11, 0, rx37_fail75
    repr_get_attr_int rx37_pos, $P11, rx37_curclass, "$!pos"
    repr_bind_attr_int rx37_cur, rx37_curclass, "$!pos", rx37_pos
    $P11 = rx37_cur."string"()
    repr_get_attr_int $I11, $P11, rx37_curclass, "$!pos"
    lt $I11, 0, rx37_fail75
    nqp_rxmark rx37_bstack, rxsubrule42_pass85, -1, 0
  rxsubrule42_pass85:
    rx37_cstack = rx37_cur."!cursor_capture"($P11, "string")
    repr_get_attr_int rx37_pos, $P11, rx37_curclass, "$!pos"
    repr_bind_attr_int rx37_cur, rx37_curclass, "$!pos", rx37_pos
    $P11 = rx37_cur."ws"()
    repr_get_attr_int $I11, $P11, rx37_curclass, "$!pos"
    lt $I11, 0, rx37_fail75
    repr_get_attr_int rx37_pos, $P11, rx37_curclass, "$!pos"
    add $I11, rx37_pos, 1
    gt $I11, rx37_eos, rx37_fail75
    substr $S10, rx37_tgt, rx37_pos, 1
    ne $S10, ucs4:":", rx37_fail75
    add rx37_pos, 1
    repr_bind_attr_int rx37_cur, rx37_curclass, "$!pos", rx37_pos
    $P11 = rx37_cur."ws"()
    repr_get_attr_int $I11, $P11, rx37_curclass, "$!pos"
    lt $I11, 0, rx37_fail75
    repr_get_attr_int rx37_pos, $P11, rx37_curclass, "$!pos"
    repr_bind_attr_int rx37_cur, rx37_curclass, "$!pos", rx37_pos
    $P11 = rx37_cur."value"()
    repr_get_attr_int $I11, $P11, rx37_curclass, "$!pos"
    lt $I11, 0, rx37_fail75
    nqp_rxmark rx37_bstack, rxsubrule45_pass88, -1, 0
  rxsubrule45_pass88:
    rx37_cstack = rx37_cur."!cursor_capture"($P11, "value")
    repr_get_attr_int rx37_pos, $P11, rx37_curclass, "$!pos"
    repr_bind_attr_int rx37_cur, rx37_curclass, "$!pos", rx37_pos
    $P11 = rx37_cur."ws"()
    repr_get_attr_int $I11, $P11, rx37_curclass, "$!pos"
    lt $I11, 0, rx37_fail75
    repr_get_attr_int rx37_pos, $P11, rx37_curclass, "$!pos"
    rx37_cur."!cursor_pass"(rx37_pos, "pair", 'backtrack'=>1)
    .return (rx37_cur)
  rx37_restart74:
    repr_get_attr_obj rx37_cstack, rx37_cur, rx37_curclass, "$!cstack"
  rx37_fail75:
    unless rx37_bstack, rx37_done73
    pop $I19, rx37_bstack
    if_null rx37_cstack, rx37_cstack_done78
    unless rx37_cstack, rx37_cstack_done78
    dec $I19
    set $P11, rx37_cstack[$I19]
  rx37_cstack_done78:
    pop rx37_rep, rx37_bstack
    pop rx37_pos, rx37_bstack
    pop $I19, rx37_bstack
    lt rx37_pos, -1, rx37_done73
    lt rx37_pos, 0, rx37_fail75
    eq $I19, 0, rx37_fail75
    nqp_islist $I20, rx37_cstack
    unless $I20, rx37_jump76
    elements $I18, rx37_bstack
    le $I18, 0, rx37_cut77
    dec $I18
    set $I18, rx37_bstack[$I18]
  rx37_cut77:
    assign rx37_cstack, $I18
  rx37_jump76:
    jump $I19
  rx37_done73:
    rx37_cur."!cursor_fail"()
    .return (rx37_cur) 
.end
.HLL "perl6"
.namespace []
.sub "array" :subid("cuid_5_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 8
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx47_start
    .local string rx47_tgt
    .local int rx47_pos
    .local int rx47_off
    .local int rx47_eos
    .local int rx47_rep
    .local pmc rx47_cur
    .local pmc rx47_curclass
    .local pmc rx47_bstack
    .local pmc rx47_cstack
    rx47_start = self."!cursor_start_all"()
    set rx47_cur, rx47_start[0]
    set rx47_tgt, rx47_start[1]
    set rx47_pos, rx47_start[2]
    set rx47_curclass, rx47_start[3]
    set rx47_bstack, rx47_start[4]
    set $I19, rx47_start[5]
    store_lex unicode:"$\x{a2}", rx47_cur
    length rx47_eos, rx47_tgt
    eq $I19, 1, rx47_restart92
    gt rx47_pos, rx47_eos, rx47_fail93
    repr_get_attr_int $I11, self, rx47_curclass, "$!from"
    ne $I11, -1, rxscan48_done99
    goto rxscan48_scan98
  rxscan48_loop97:
    inc rx47_pos
    gt rx47_pos, rx47_eos, rx47_fail93
    repr_bind_attr_int rx47_cur, rx47_curclass, "$!from", rx47_pos
  rxscan48_scan98:
    nqp_rxmark rx47_bstack, rxscan48_loop97, rx47_pos, 0
  rxscan48_done99:
    repr_bind_attr_int rx47_cur, rx47_curclass, "$!pos", rx47_pos
    $P11 = rx47_cur."ws"()
    repr_get_attr_int $I11, $P11, rx47_curclass, "$!pos"
    lt $I11, 0, rx47_fail93
    repr_get_attr_int rx47_pos, $P11, rx47_curclass, "$!pos"
    add $I11, rx47_pos, 1
    gt $I11, rx47_eos, rx47_fail93
    substr $S10, rx47_tgt, rx47_pos, 1
    ne $S10, ucs4:"[", rx47_fail93
    add rx47_pos, 1
    repr_bind_attr_int rx47_cur, rx47_curclass, "$!pos", rx47_pos
    $P11 = rx47_cur."ws"()
    repr_get_attr_int $I11, $P11, rx47_curclass, "$!pos"
    lt $I11, 0, rx47_fail93
    repr_get_attr_int rx47_pos, $P11, rx47_curclass, "$!pos"
    repr_bind_attr_int rx47_cur, rx47_curclass, "$!pos", rx47_pos
    $P11 = rx47_cur."arraylist"()
    repr_get_attr_int $I11, $P11, rx47_curclass, "$!pos"
    lt $I11, 0, rx47_fail93
    nqp_rxmark rx47_bstack, rxsubrule51_pass102, -1, 0
  rxsubrule51_pass102:
    rx47_cstack = rx47_cur."!cursor_capture"($P11, "arraylist")
    repr_get_attr_int rx47_pos, $P11, rx47_curclass, "$!pos"
  alt52_0104:
    nqp_rxmark rx47_bstack, alt52_1105, rx47_pos, 0
    add $I11, rx47_pos, 1
    gt $I11, rx47_eos, rx47_fail93
    substr $S10, rx47_tgt, rx47_pos, 1
    ne $S10, ucs4:"]", rx47_fail93
    add rx47_pos, 1
    goto alt52_end103
  alt52_1105:
    repr_bind_attr_int rx47_cur, rx47_curclass, "$!pos", rx47_pos
    $P11 = rx47_cur."FAILGOAL"("']'")
    repr_get_attr_int $I11, $P11, rx47_curclass, "$!pos"
    lt $I11, 0, rx47_fail93
    goto rxsubrule53_pass106
  rxsubrule53_back107:
    $P11 = $P11."!cursor_next"()
    repr_get_attr_int $I11, $P11, rx47_curclass, "$!pos"
    lt $I11, 0, rx47_fail93
  rxsubrule53_pass106:
    rx47_cstack = rx47_cur."!cursor_push_cstack"($P11)
    set_addr $I11, rxsubrule53_back107
    push rx47_bstack, $I11
    push rx47_bstack, 0
    push rx47_bstack, rx47_pos
    elements $I11, rx47_cstack
    push rx47_bstack, $I11
    repr_get_attr_int rx47_pos, $P11, rx47_curclass, "$!pos"
  alt52_end103:
    repr_bind_attr_int rx47_cur, rx47_curclass, "$!pos", rx47_pos
    $P11 = rx47_cur."ws"()
    repr_get_attr_int $I11, $P11, rx47_curclass, "$!pos"
    lt $I11, 0, rx47_fail93
    repr_get_attr_int rx47_pos, $P11, rx47_curclass, "$!pos"
    rx47_cur."!cursor_pass"(rx47_pos, "array", 'backtrack'=>1)
    .return (rx47_cur)
  rx47_restart92:
    repr_get_attr_obj rx47_cstack, rx47_cur, rx47_curclass, "$!cstack"
  rx47_fail93:
    unless rx47_bstack, rx47_done91
    pop $I19, rx47_bstack
    if_null rx47_cstack, rx47_cstack_done96
    unless rx47_cstack, rx47_cstack_done96
    dec $I19
    set $P11, rx47_cstack[$I19]
  rx47_cstack_done96:
    pop rx47_rep, rx47_bstack
    pop rx47_pos, rx47_bstack
    pop $I19, rx47_bstack
    lt rx47_pos, -1, rx47_done91
    lt rx47_pos, 0, rx47_fail93
    eq $I19, 0, rx47_fail93
    nqp_islist $I20, rx47_cstack
    unless $I20, rx47_jump94
    elements $I18, rx47_bstack
    le $I18, 0, rx47_cut95
    dec $I18
    set $I18, rx47_bstack[$I18]
  rx47_cut95:
    assign rx47_cstack, $I18
  rx47_jump94:
    jump $I19
  rx47_done91:
    rx47_cur."!cursor_fail"()
    .return (rx47_cur) 
.end
.HLL "perl6"
.namespace []
.sub "arraylist" :subid("cuid_6_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 9
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx55_start
    .local string rx55_tgt
    .local int rx55_pos
    .local int rx55_off
    .local int rx55_eos
    .local int rx55_rep
    .local pmc rx55_cur
    .local pmc rx55_curclass
    .local pmc rx55_bstack
    .local pmc rx55_cstack
    rx55_start = self."!cursor_start_all"()
    set rx55_cur, rx55_start[0]
    set rx55_tgt, rx55_start[1]
    set rx55_pos, rx55_start[2]
    set rx55_curclass, rx55_start[3]
    set rx55_bstack, rx55_start[4]
    set $I19, rx55_start[5]
    store_lex unicode:"$\x{a2}", rx55_cur
    length rx55_eos, rx55_tgt
    eq $I19, 1, rx55_restart111
    gt rx55_pos, rx55_eos, rx55_fail112
    repr_get_attr_int $I11, self, rx55_curclass, "$!from"
    ne $I11, -1, rxscan56_done118
    goto rxscan56_scan117
  rxscan56_loop116:
    inc rx55_pos
    gt rx55_pos, rx55_eos, rx55_fail112
    repr_bind_attr_int rx55_cur, rx55_curclass, "$!from", rx55_pos
  rxscan56_scan117:
    nqp_rxmark rx55_bstack, rxscan56_loop116, rx55_pos, 0
  rxscan56_done118:
    repr_bind_attr_int rx55_cur, rx55_curclass, "$!pos", rx55_pos
    $P11 = rx55_cur."ws"()
    repr_get_attr_int $I11, $P11, rx55_curclass, "$!pos"
    lt $I11, 0, rx55_fail112
    repr_get_attr_int rx55_pos, $P11, rx55_curclass, "$!pos"
    repr_bind_attr_int rx55_cur, rx55_curclass, "$!pos", rx55_pos
    $P11 = rx55_cur."ws"()
    repr_get_attr_int $I11, $P11, rx55_curclass, "$!pos"
    lt $I11, 0, rx55_fail112
    repr_get_attr_int rx55_pos, $P11, rx55_curclass, "$!pos"
    nqp_rxmark rx55_bstack, rxquantr60_done123, rx55_pos, 0
  rxquantr60_loop122:
    repr_bind_attr_int rx55_cur, rx55_curclass, "$!pos", rx55_pos
    $P11 = rx55_cur."value"()
    repr_get_attr_int $I11, $P11, rx55_curclass, "$!pos"
    lt $I11, 0, rx55_fail112
    goto rxsubrule61_pass124
  rxsubrule61_back125:
    $P11 = $P11."!cursor_next"()
    repr_get_attr_int $I11, $P11, rx55_curclass, "$!pos"
    lt $I11, 0, rx55_fail112
  rxsubrule61_pass124:
    rx55_cstack = rx55_cur."!cursor_capture"($P11, "value")
    set_addr $I11, rxsubrule61_back125
    push rx55_bstack, $I11
    push rx55_bstack, 0
    push rx55_bstack, rx55_pos
    elements $I11, rx55_cstack
    push rx55_bstack, $I11
    repr_get_attr_int rx55_pos, $P11, rx55_curclass, "$!pos"
    nqp_rxpeek $I19, rx55_bstack, rxquantr60_done123
    inc $I19
    inc $I19
    set rx55_rep, rx55_bstack[$I19]
    nqp_rxcommit rx55_bstack, rxquantr60_done123
    inc rx55_rep
    nqp_rxmark rx55_bstack, rxquantr60_done123, rx55_pos, rx55_rep
    repr_bind_attr_int rx55_cur, rx55_curclass, "$!pos", rx55_pos
    $P11 = rx55_cur."ws"()
    repr_get_attr_int $I11, $P11, rx55_curclass, "$!pos"
    lt $I11, 0, rx55_fail112
    repr_get_attr_int rx55_pos, $P11, rx55_curclass, "$!pos"
    add $I11, rx55_pos, 1
    gt $I11, rx55_eos, rx55_fail112
    substr $S10, rx55_tgt, rx55_pos, 1
    ne $S10, ucs4:",", rx55_fail112
    add rx55_pos, 1
    repr_bind_attr_int rx55_cur, rx55_curclass, "$!pos", rx55_pos
    $P11 = rx55_cur."ws"()
    repr_get_attr_int $I11, $P11, rx55_curclass, "$!pos"
    lt $I11, 0, rx55_fail112
    repr_get_attr_int rx55_pos, $P11, rx55_curclass, "$!pos"
    goto rxquantr60_loop122
  rxquantr60_done123:
    repr_bind_attr_int rx55_cur, rx55_curclass, "$!pos", rx55_pos
    $P11 = rx55_cur."ws"()
    repr_get_attr_int $I11, $P11, rx55_curclass, "$!pos"
    lt $I11, 0, rx55_fail112
    repr_get_attr_int rx55_pos, $P11, rx55_curclass, "$!pos"
    rx55_cur."!cursor_pass"(rx55_pos, "arraylist", 'backtrack'=>1)
    .return (rx55_cur)
  rx55_restart111:
    repr_get_attr_obj rx55_cstack, rx55_cur, rx55_curclass, "$!cstack"
  rx55_fail112:
    unless rx55_bstack, rx55_done110
    pop $I19, rx55_bstack
    if_null rx55_cstack, rx55_cstack_done115
    unless rx55_cstack, rx55_cstack_done115
    dec $I19
    set $P11, rx55_cstack[$I19]
  rx55_cstack_done115:
    pop rx55_rep, rx55_bstack
    pop rx55_pos, rx55_bstack
    pop $I19, rx55_bstack
    lt rx55_pos, -1, rx55_done110
    lt rx55_pos, 0, rx55_fail112
    eq $I19, 0, rx55_fail112
    nqp_islist $I20, rx55_cstack
    unless $I20, rx55_jump113
    elements $I18, rx55_bstack
    le $I18, 0, rx55_cut114
    dec $I18
    set $I18, rx55_bstack[$I18]
  rx55_cut114:
    assign rx55_cstack, $I18
  rx55_jump113:
    jump $I19
  rx55_done110:
    rx55_cur."!cursor_fail"()
    .return (rx55_cur) 
.end
.HLL "perl6"
.namespace []
.sub "value" :subid("cuid_7_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 11
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$?REGEX", $P103 
    .lex "call_sig", $P104 
    .lex "$*DISPATCHER", $P105 
    .lex "&?ROUTINE", $P106 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P103, $P5001
    set $P5003, CALL_SIG
    set $P104, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    $P5004 = self."!protoregex"("value")
    .return ($P5004) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<number>" :subid("cuid_8_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 12
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx65_start
    .local string rx65_tgt
    .local int rx65_pos
    .local int rx65_off
    .local int rx65_eos
    .local int rx65_rep
    .local pmc rx65_cur
    .local pmc rx65_curclass
    .local pmc rx65_bstack
    .local pmc rx65_cstack
    rx65_start = self."!cursor_start_all"()
    set rx65_cur, rx65_start[0]
    set rx65_tgt, rx65_start[1]
    set rx65_pos, rx65_start[2]
    set rx65_curclass, rx65_start[3]
    set rx65_bstack, rx65_start[4]
    set $I19, rx65_start[5]
    store_lex unicode:"$\x{a2}", rx65_cur
    length rx65_eos, rx65_tgt
    eq $I19, 1, rx65_restart131
    gt rx65_pos, rx65_eos, rx65_fail132
    repr_get_attr_int $I11, self, rx65_curclass, "$!from"
    ne $I11, -1, rxscan66_done138
    goto rxscan66_scan137
  rxscan66_loop136:
    inc rx65_pos
    gt rx65_pos, rx65_eos, rx65_fail132
    repr_bind_attr_int rx65_cur, rx65_curclass, "$!from", rx65_pos
  rxscan66_scan137:
    nqp_rxmark rx65_bstack, rxscan66_loop136, rx65_pos, 0
  rxscan66_done138:
    nqp_rxmark rx65_bstack, rxquantr67_done140, rx65_pos, 0
  rxquantr67_loop139:
    add $I11, rx65_pos, 1
    gt $I11, rx65_eos, rx65_fail132
    substr $S10, rx65_tgt, rx65_pos, 1
    ne $S10, ucs4:"-", rx65_fail132
    add rx65_pos, 1
    nqp_rxpeek $I19, rx65_bstack, rxquantr67_done140
    inc $I19
    inc $I19
    set rx65_rep, rx65_bstack[$I19]
    nqp_rxcommit rx65_bstack, rxquantr67_done140
    inc rx65_rep
  rxquantr67_done140:
    new $P11, "ResizableIntegerArray"
    nqp_push_label $P11, alt68_0142
    nqp_push_label $P11, alt68_1143
    nqp_rxmark rx65_bstack, alt68_end141, -1, 0
    rx65_cur."!alt"(rx65_pos, "alt_nfa__2_1372180368.73311", $P11)
    goto rx65_fail132
  alt68_0142:
    add $I11, rx65_pos, 1
    gt $I11, rx65_eos, rx65_fail132
    substr $S10, rx65_tgt, rx65_pos, 1
    ne $S10, ucs4:"0", rx65_fail132
    add rx65_pos, 1
    goto alt68_end141
  alt68_1143:
    ge rx65_pos, rx65_eos, rx65_fail132
    substr $S11, rx65_tgt, rx65_pos, 1
    index $I11, ucs4:"123456789", $S11
    lt $I11, 0, rx65_fail132
    inc rx65_pos
    nqp_rxmark rx65_bstack, rxquantr69_done145, rx65_pos, 0
  rxquantr69_loop144:
    ge rx65_pos, rx65_eos, rx65_fail132
    substr $S11, rx65_tgt, rx65_pos, 1
    index $I11, ucs4:"0123456789", $S11
    lt $I11, 0, rx65_fail132
    inc rx65_pos
    nqp_rxpeek $I19, rx65_bstack, rxquantr69_done145
    inc $I19
    inc $I19
    set rx65_rep, rx65_bstack[$I19]
    nqp_rxcommit rx65_bstack, rxquantr69_done145
    inc rx65_rep
    nqp_rxmark rx65_bstack, rxquantr69_done145, rx65_pos, rx65_rep
    goto rxquantr69_loop144
  rxquantr69_done145:
    goto alt68_end141
  alt68_end141:
    nqp_rxcommit rx65_bstack, alt68_end141
    nqp_rxmark rx65_bstack, rxquantr70_done147, rx65_pos, 0
  rxquantr70_loop146:
    add $I11, rx65_pos, 1
    gt $I11, rx65_eos, rx65_fail132
    substr $S10, rx65_tgt, rx65_pos, 1
    ne $S10, ucs4:".", rx65_fail132
    add rx65_pos, 1
    nqp_rxmark rx65_bstack, rxquantr71_done149, -1, 0
  rxquantr71_loop148:
    ge rx65_pos, rx65_eos, rx65_fail132
    substr $S11, rx65_tgt, rx65_pos, 1
    index $I11, ucs4:"0123456789", $S11
    lt $I11, 0, rx65_fail132
    inc rx65_pos
    nqp_rxpeek $I19, rx65_bstack, rxquantr71_done149
    inc $I19
    inc $I19
    set rx65_rep, rx65_bstack[$I19]
    nqp_rxcommit rx65_bstack, rxquantr71_done149
    inc rx65_rep
    nqp_rxmark rx65_bstack, rxquantr71_done149, rx65_pos, rx65_rep
    goto rxquantr71_loop148
  rxquantr71_done149:
    nqp_rxpeek $I19, rx65_bstack, rxquantr70_done147
    inc $I19
    inc $I19
    set rx65_rep, rx65_bstack[$I19]
    nqp_rxcommit rx65_bstack, rxquantr70_done147
    inc rx65_rep
  rxquantr70_done147:
    nqp_rxmark rx65_bstack, rxquantr72_done151, rx65_pos, 0
  rxquantr72_loop150:
    ge rx65_pos, rx65_eos, rx65_fail132
    substr $S11, rx65_tgt, rx65_pos, 1
    index $I11, ucs4:"eE", $S11
    lt $I11, 0, rx65_fail132
    inc rx65_pos
    nqp_rxmark rx65_bstack, rxquantr73_done153, rx65_pos, 0
  rxquantr73_loop152:
    new $P11, "ResizableIntegerArray"
    nqp_push_label $P11, alt74_0155
    nqp_push_label $P11, alt74_1156
    nqp_rxmark rx65_bstack, alt74_end154, -1, 0
    rx65_cur."!alt"(rx65_pos, "alt_nfa__3_1372180368.73335", $P11)
    goto rx65_fail132
  alt74_0155:
    add $I11, rx65_pos, 1
    gt $I11, rx65_eos, rx65_fail132
    substr $S10, rx65_tgt, rx65_pos, 1
    ne $S10, ucs4:"+", rx65_fail132
    add rx65_pos, 1
    goto alt74_end154
  alt74_1156:
    add $I11, rx65_pos, 1
    gt $I11, rx65_eos, rx65_fail132
    substr $S10, rx65_tgt, rx65_pos, 1
    ne $S10, ucs4:"-", rx65_fail132
    add rx65_pos, 1
    goto alt74_end154
  alt74_end154:
    nqp_rxpeek $I19, rx65_bstack, rxquantr73_done153
    inc $I19
    inc $I19
    set rx65_rep, rx65_bstack[$I19]
    nqp_rxcommit rx65_bstack, rxquantr73_done153
    inc rx65_rep
  rxquantr73_done153:
    nqp_rxmark rx65_bstack, rxquantr75_done158, -1, 0
  rxquantr75_loop157:
    ge rx65_pos, rx65_eos, rx65_fail132
    substr $S11, rx65_tgt, rx65_pos, 1
    index $I11, ucs4:"0123456789", $S11
    lt $I11, 0, rx65_fail132
    inc rx65_pos
    nqp_rxpeek $I19, rx65_bstack, rxquantr75_done158
    inc $I19
    inc $I19
    set rx65_rep, rx65_bstack[$I19]
    nqp_rxcommit rx65_bstack, rxquantr75_done158
    inc rx65_rep
    nqp_rxmark rx65_bstack, rxquantr75_done158, rx65_pos, rx65_rep
    goto rxquantr75_loop157
  rxquantr75_done158:
    nqp_rxpeek $I19, rx65_bstack, rxquantr72_done151
    inc $I19
    inc $I19
    set rx65_rep, rx65_bstack[$I19]
    nqp_rxcommit rx65_bstack, rxquantr72_done151
    inc rx65_rep
  rxquantr72_done151:
    rx65_cur."!cursor_pass"(rx65_pos, "value:sym<number>", 'backtrack'=>1)
    .return (rx65_cur)
  rx65_restart131:
    repr_get_attr_obj rx65_cstack, rx65_cur, rx65_curclass, "$!cstack"
  rx65_fail132:
    unless rx65_bstack, rx65_done130
    pop $I19, rx65_bstack
    if_null rx65_cstack, rx65_cstack_done135
    unless rx65_cstack, rx65_cstack_done135
    dec $I19
    set $P11, rx65_cstack[$I19]
  rx65_cstack_done135:
    pop rx65_rep, rx65_bstack
    pop rx65_pos, rx65_bstack
    pop $I19, rx65_bstack
    lt rx65_pos, -1, rx65_done130
    lt rx65_pos, 0, rx65_fail132
    eq $I19, 0, rx65_fail132
    nqp_islist $I20, rx65_cstack
    unless $I20, rx65_jump133
    elements $I18, rx65_bstack
    le $I18, 0, rx65_cut134
    dec $I18
    set $I18, rx65_bstack[$I18]
  rx65_cut134:
    assign rx65_cstack, $I18
  rx65_jump133:
    jump $I19
  rx65_done130:
    rx65_cur."!cursor_fail"()
    .return (rx65_cur) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<true>" :subid("cuid_9_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 18
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx76_start
    .local string rx76_tgt
    .local int rx76_pos
    .local int rx76_off
    .local int rx76_eos
    .local int rx76_rep
    .local pmc rx76_cur
    .local pmc rx76_curclass
    .local pmc rx76_bstack
    .local pmc rx76_cstack
    rx76_start = self."!cursor_start_all"()
    set rx76_cur, rx76_start[0]
    set rx76_tgt, rx76_start[1]
    set rx76_pos, rx76_start[2]
    set rx76_curclass, rx76_start[3]
    set rx76_bstack, rx76_start[4]
    set $I19, rx76_start[5]
    store_lex unicode:"$\x{a2}", rx76_cur
    length rx76_eos, rx76_tgt
    eq $I19, 1, rx76_restart161
    gt rx76_pos, rx76_eos, rx76_fail162
    repr_get_attr_int $I11, self, rx76_curclass, "$!from"
    ne $I11, -1, rxscan77_done168
    goto rxscan77_scan167
  rxscan77_loop166:
    inc rx76_pos
    gt rx76_pos, rx76_eos, rx76_fail162
    repr_bind_attr_int rx76_cur, rx76_curclass, "$!from", rx76_pos
  rxscan77_scan167:
    nqp_rxmark rx76_bstack, rxscan77_loop166, rx76_pos, 0
  rxscan77_done168:
    nqp_rxmark rx76_bstack, rxcap78_fail170, rx76_pos, 0
    add $I11, rx76_pos, 4
    gt $I11, rx76_eos, rx76_fail162
    substr $S10, rx76_tgt, rx76_pos, 4
    ne $S10, ucs4:"true", rx76_fail162
    add rx76_pos, 4
    nqp_rxpeek $I19, rx76_bstack, rxcap78_fail170
    inc $I19
    set $I11, rx76_bstack[$I19]
    repr_bind_attr_int rx76_cur, rx76_curclass, "$!pos", rx76_pos
    $P11 = rx76_cur."!cursor_start_subcapture"($I11)
    $P11."!cursor_pass"(rx76_pos)
    rx76_cstack = rx76_cur."!cursor_capture"($P11, "sym")
    goto rxcap78_done169
  rxcap78_fail170:
    goto rx76_fail162
  rxcap78_done169:
    rx76_cur."!cursor_pass"(rx76_pos, "value:sym<true>", 'backtrack'=>1)
    .return (rx76_cur)
  rx76_restart161:
    repr_get_attr_obj rx76_cstack, rx76_cur, rx76_curclass, "$!cstack"
  rx76_fail162:
    unless rx76_bstack, rx76_done160
    pop $I19, rx76_bstack
    if_null rx76_cstack, rx76_cstack_done165
    unless rx76_cstack, rx76_cstack_done165
    dec $I19
    set $P11, rx76_cstack[$I19]
  rx76_cstack_done165:
    pop rx76_rep, rx76_bstack
    pop rx76_pos, rx76_bstack
    pop $I19, rx76_bstack
    lt rx76_pos, -1, rx76_done160
    lt rx76_pos, 0, rx76_fail162
    eq $I19, 0, rx76_fail162
    nqp_islist $I20, rx76_cstack
    unless $I20, rx76_jump163
    elements $I18, rx76_bstack
    le $I18, 0, rx76_cut164
    dec $I18
    set $I18, rx76_bstack[$I18]
  rx76_cut164:
    assign rx76_cstack, $I18
  rx76_jump163:
    jump $I19
  rx76_done160:
    rx76_cur."!cursor_fail"()
    .return (rx76_cur) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<false>" :subid("cuid_10_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 19
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx79_start
    .local string rx79_tgt
    .local int rx79_pos
    .local int rx79_off
    .local int rx79_eos
    .local int rx79_rep
    .local pmc rx79_cur
    .local pmc rx79_curclass
    .local pmc rx79_bstack
    .local pmc rx79_cstack
    rx79_start = self."!cursor_start_all"()
    set rx79_cur, rx79_start[0]
    set rx79_tgt, rx79_start[1]
    set rx79_pos, rx79_start[2]
    set rx79_curclass, rx79_start[3]
    set rx79_bstack, rx79_start[4]
    set $I19, rx79_start[5]
    store_lex unicode:"$\x{a2}", rx79_cur
    length rx79_eos, rx79_tgt
    eq $I19, 1, rx79_restart173
    gt rx79_pos, rx79_eos, rx79_fail174
    repr_get_attr_int $I11, self, rx79_curclass, "$!from"
    ne $I11, -1, rxscan80_done180
    goto rxscan80_scan179
  rxscan80_loop178:
    inc rx79_pos
    gt rx79_pos, rx79_eos, rx79_fail174
    repr_bind_attr_int rx79_cur, rx79_curclass, "$!from", rx79_pos
  rxscan80_scan179:
    nqp_rxmark rx79_bstack, rxscan80_loop178, rx79_pos, 0
  rxscan80_done180:
    nqp_rxmark rx79_bstack, rxcap81_fail182, rx79_pos, 0
    add $I11, rx79_pos, 5
    gt $I11, rx79_eos, rx79_fail174
    substr $S10, rx79_tgt, rx79_pos, 5
    ne $S10, ucs4:"false", rx79_fail174
    add rx79_pos, 5
    nqp_rxpeek $I19, rx79_bstack, rxcap81_fail182
    inc $I19
    set $I11, rx79_bstack[$I19]
    repr_bind_attr_int rx79_cur, rx79_curclass, "$!pos", rx79_pos
    $P11 = rx79_cur."!cursor_start_subcapture"($I11)
    $P11."!cursor_pass"(rx79_pos)
    rx79_cstack = rx79_cur."!cursor_capture"($P11, "sym")
    goto rxcap81_done181
  rxcap81_fail182:
    goto rx79_fail174
  rxcap81_done181:
    rx79_cur."!cursor_pass"(rx79_pos, "value:sym<false>", 'backtrack'=>1)
    .return (rx79_cur)
  rx79_restart173:
    repr_get_attr_obj rx79_cstack, rx79_cur, rx79_curclass, "$!cstack"
  rx79_fail174:
    unless rx79_bstack, rx79_done172
    pop $I19, rx79_bstack
    if_null rx79_cstack, rx79_cstack_done177
    unless rx79_cstack, rx79_cstack_done177
    dec $I19
    set $P11, rx79_cstack[$I19]
  rx79_cstack_done177:
    pop rx79_rep, rx79_bstack
    pop rx79_pos, rx79_bstack
    pop $I19, rx79_bstack
    lt rx79_pos, -1, rx79_done172
    lt rx79_pos, 0, rx79_fail174
    eq $I19, 0, rx79_fail174
    nqp_islist $I20, rx79_cstack
    unless $I20, rx79_jump175
    elements $I18, rx79_bstack
    le $I18, 0, rx79_cut176
    dec $I18
    set $I18, rx79_bstack[$I18]
  rx79_cut176:
    assign rx79_cstack, $I18
  rx79_jump175:
    jump $I19
  rx79_done172:
    rx79_cur."!cursor_fail"()
    .return (rx79_cur) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<null>" :subid("cuid_11_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 20
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx82_start
    .local string rx82_tgt
    .local int rx82_pos
    .local int rx82_off
    .local int rx82_eos
    .local int rx82_rep
    .local pmc rx82_cur
    .local pmc rx82_curclass
    .local pmc rx82_bstack
    .local pmc rx82_cstack
    rx82_start = self."!cursor_start_all"()
    set rx82_cur, rx82_start[0]
    set rx82_tgt, rx82_start[1]
    set rx82_pos, rx82_start[2]
    set rx82_curclass, rx82_start[3]
    set rx82_bstack, rx82_start[4]
    set $I19, rx82_start[5]
    store_lex unicode:"$\x{a2}", rx82_cur
    length rx82_eos, rx82_tgt
    eq $I19, 1, rx82_restart185
    gt rx82_pos, rx82_eos, rx82_fail186
    repr_get_attr_int $I11, self, rx82_curclass, "$!from"
    ne $I11, -1, rxscan83_done192
    goto rxscan83_scan191
  rxscan83_loop190:
    inc rx82_pos
    gt rx82_pos, rx82_eos, rx82_fail186
    repr_bind_attr_int rx82_cur, rx82_curclass, "$!from", rx82_pos
  rxscan83_scan191:
    nqp_rxmark rx82_bstack, rxscan83_loop190, rx82_pos, 0
  rxscan83_done192:
    nqp_rxmark rx82_bstack, rxcap84_fail194, rx82_pos, 0
    add $I11, rx82_pos, 4
    gt $I11, rx82_eos, rx82_fail186
    substr $S10, rx82_tgt, rx82_pos, 4
    ne $S10, ucs4:"null", rx82_fail186
    add rx82_pos, 4
    nqp_rxpeek $I19, rx82_bstack, rxcap84_fail194
    inc $I19
    set $I11, rx82_bstack[$I19]
    repr_bind_attr_int rx82_cur, rx82_curclass, "$!pos", rx82_pos
    $P11 = rx82_cur."!cursor_start_subcapture"($I11)
    $P11."!cursor_pass"(rx82_pos)
    rx82_cstack = rx82_cur."!cursor_capture"($P11, "sym")
    goto rxcap84_done193
  rxcap84_fail194:
    goto rx82_fail186
  rxcap84_done193:
    rx82_cur."!cursor_pass"(rx82_pos, "value:sym<null>", 'backtrack'=>1)
    .return (rx82_cur)
  rx82_restart185:
    repr_get_attr_obj rx82_cstack, rx82_cur, rx82_curclass, "$!cstack"
  rx82_fail186:
    unless rx82_bstack, rx82_done184
    pop $I19, rx82_bstack
    if_null rx82_cstack, rx82_cstack_done189
    unless rx82_cstack, rx82_cstack_done189
    dec $I19
    set $P11, rx82_cstack[$I19]
  rx82_cstack_done189:
    pop rx82_rep, rx82_bstack
    pop rx82_pos, rx82_bstack
    pop $I19, rx82_bstack
    lt rx82_pos, -1, rx82_done184
    lt rx82_pos, 0, rx82_fail186
    eq $I19, 0, rx82_fail186
    nqp_islist $I20, rx82_cstack
    unless $I20, rx82_jump187
    elements $I18, rx82_bstack
    le $I18, 0, rx82_cut188
    dec $I18
    set $I18, rx82_bstack[$I18]
  rx82_cut188:
    assign rx82_cstack, $I18
  rx82_jump187:
    jump $I19
  rx82_done184:
    rx82_cur."!cursor_fail"()
    .return (rx82_cur) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<object>" :subid("cuid_12_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 21
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx85_start
    .local string rx85_tgt
    .local int rx85_pos
    .local int rx85_off
    .local int rx85_eos
    .local int rx85_rep
    .local pmc rx85_cur
    .local pmc rx85_curclass
    .local pmc rx85_bstack
    .local pmc rx85_cstack
    rx85_start = self."!cursor_start_all"()
    set rx85_cur, rx85_start[0]
    set rx85_tgt, rx85_start[1]
    set rx85_pos, rx85_start[2]
    set rx85_curclass, rx85_start[3]
    set rx85_bstack, rx85_start[4]
    set $I19, rx85_start[5]
    store_lex unicode:"$\x{a2}", rx85_cur
    length rx85_eos, rx85_tgt
    eq $I19, 1, rx85_restart197
    gt rx85_pos, rx85_eos, rx85_fail198
    repr_get_attr_int $I11, self, rx85_curclass, "$!from"
    ne $I11, -1, rxscan86_done204
    goto rxscan86_scan203
  rxscan86_loop202:
    inc rx85_pos
    gt rx85_pos, rx85_eos, rx85_fail198
    repr_bind_attr_int rx85_cur, rx85_curclass, "$!from", rx85_pos
  rxscan86_scan203:
    nqp_rxmark rx85_bstack, rxscan86_loop202, rx85_pos, 0
  rxscan86_done204:
    repr_bind_attr_int rx85_cur, rx85_curclass, "$!pos", rx85_pos
    $P11 = rx85_cur."object"()
    repr_get_attr_int $I11, $P11, rx85_curclass, "$!pos"
    lt $I11, 0, rx85_fail198
    nqp_rxmark rx85_bstack, rxsubrule87_pass205, -1, 0
  rxsubrule87_pass205:
    rx85_cstack = rx85_cur."!cursor_capture"($P11, "object")
    repr_get_attr_int rx85_pos, $P11, rx85_curclass, "$!pos"
    rx85_cur."!cursor_pass"(rx85_pos, "value:sym<object>", 'backtrack'=>1)
    .return (rx85_cur)
  rx85_restart197:
    repr_get_attr_obj rx85_cstack, rx85_cur, rx85_curclass, "$!cstack"
  rx85_fail198:
    unless rx85_bstack, rx85_done196
    pop $I19, rx85_bstack
    if_null rx85_cstack, rx85_cstack_done201
    unless rx85_cstack, rx85_cstack_done201
    dec $I19
    set $P11, rx85_cstack[$I19]
  rx85_cstack_done201:
    pop rx85_rep, rx85_bstack
    pop rx85_pos, rx85_bstack
    pop $I19, rx85_bstack
    lt rx85_pos, -1, rx85_done196
    lt rx85_pos, 0, rx85_fail198
    eq $I19, 0, rx85_fail198
    nqp_islist $I20, rx85_cstack
    unless $I20, rx85_jump199
    elements $I18, rx85_bstack
    le $I18, 0, rx85_cut200
    dec $I18
    set $I18, rx85_bstack[$I18]
  rx85_cut200:
    assign rx85_cstack, $I18
  rx85_jump199:
    jump $I19
  rx85_done196:
    rx85_cur."!cursor_fail"()
    .return (rx85_cur) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<array>" :subid("cuid_13_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 22
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx88_start
    .local string rx88_tgt
    .local int rx88_pos
    .local int rx88_off
    .local int rx88_eos
    .local int rx88_rep
    .local pmc rx88_cur
    .local pmc rx88_curclass
    .local pmc rx88_bstack
    .local pmc rx88_cstack
    rx88_start = self."!cursor_start_all"()
    set rx88_cur, rx88_start[0]
    set rx88_tgt, rx88_start[1]
    set rx88_pos, rx88_start[2]
    set rx88_curclass, rx88_start[3]
    set rx88_bstack, rx88_start[4]
    set $I19, rx88_start[5]
    store_lex unicode:"$\x{a2}", rx88_cur
    length rx88_eos, rx88_tgt
    eq $I19, 1, rx88_restart208
    gt rx88_pos, rx88_eos, rx88_fail209
    repr_get_attr_int $I11, self, rx88_curclass, "$!from"
    ne $I11, -1, rxscan89_done215
    goto rxscan89_scan214
  rxscan89_loop213:
    inc rx88_pos
    gt rx88_pos, rx88_eos, rx88_fail209
    repr_bind_attr_int rx88_cur, rx88_curclass, "$!from", rx88_pos
  rxscan89_scan214:
    nqp_rxmark rx88_bstack, rxscan89_loop213, rx88_pos, 0
  rxscan89_done215:
    repr_bind_attr_int rx88_cur, rx88_curclass, "$!pos", rx88_pos
    $P11 = rx88_cur."array"()
    repr_get_attr_int $I11, $P11, rx88_curclass, "$!pos"
    lt $I11, 0, rx88_fail209
    nqp_rxmark rx88_bstack, rxsubrule90_pass216, -1, 0
  rxsubrule90_pass216:
    rx88_cstack = rx88_cur."!cursor_capture"($P11, "array")
    repr_get_attr_int rx88_pos, $P11, rx88_curclass, "$!pos"
    rx88_cur."!cursor_pass"(rx88_pos, "value:sym<array>", 'backtrack'=>1)
    .return (rx88_cur)
  rx88_restart208:
    repr_get_attr_obj rx88_cstack, rx88_cur, rx88_curclass, "$!cstack"
  rx88_fail209:
    unless rx88_bstack, rx88_done207
    pop $I19, rx88_bstack
    if_null rx88_cstack, rx88_cstack_done212
    unless rx88_cstack, rx88_cstack_done212
    dec $I19
    set $P11, rx88_cstack[$I19]
  rx88_cstack_done212:
    pop rx88_rep, rx88_bstack
    pop rx88_pos, rx88_bstack
    pop $I19, rx88_bstack
    lt rx88_pos, -1, rx88_done207
    lt rx88_pos, 0, rx88_fail209
    eq $I19, 0, rx88_fail209
    nqp_islist $I20, rx88_cstack
    unless $I20, rx88_jump210
    elements $I18, rx88_bstack
    le $I18, 0, rx88_cut211
    dec $I18
    set $I18, rx88_bstack[$I18]
  rx88_cut211:
    assign rx88_cstack, $I18
  rx88_jump210:
    jump $I19
  rx88_done207:
    rx88_cur."!cursor_fail"()
    .return (rx88_cur) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<string>" :subid("cuid_14_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 23
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx91_start
    .local string rx91_tgt
    .local int rx91_pos
    .local int rx91_off
    .local int rx91_eos
    .local int rx91_rep
    .local pmc rx91_cur
    .local pmc rx91_curclass
    .local pmc rx91_bstack
    .local pmc rx91_cstack
    rx91_start = self."!cursor_start_all"()
    set rx91_cur, rx91_start[0]
    set rx91_tgt, rx91_start[1]
    set rx91_pos, rx91_start[2]
    set rx91_curclass, rx91_start[3]
    set rx91_bstack, rx91_start[4]
    set $I19, rx91_start[5]
    store_lex unicode:"$\x{a2}", rx91_cur
    length rx91_eos, rx91_tgt
    eq $I19, 1, rx91_restart219
    gt rx91_pos, rx91_eos, rx91_fail220
    repr_get_attr_int $I11, self, rx91_curclass, "$!from"
    ne $I11, -1, rxscan92_done226
    goto rxscan92_scan225
  rxscan92_loop224:
    inc rx91_pos
    gt rx91_pos, rx91_eos, rx91_fail220
    repr_bind_attr_int rx91_cur, rx91_curclass, "$!from", rx91_pos
  rxscan92_scan225:
    nqp_rxmark rx91_bstack, rxscan92_loop224, rx91_pos, 0
  rxscan92_done226:
    repr_bind_attr_int rx91_cur, rx91_curclass, "$!pos", rx91_pos
    $P11 = rx91_cur."string"()
    repr_get_attr_int $I11, $P11, rx91_curclass, "$!pos"
    lt $I11, 0, rx91_fail220
    nqp_rxmark rx91_bstack, rxsubrule93_pass227, -1, 0
  rxsubrule93_pass227:
    rx91_cstack = rx91_cur."!cursor_capture"($P11, "string")
    repr_get_attr_int rx91_pos, $P11, rx91_curclass, "$!pos"
    rx91_cur."!cursor_pass"(rx91_pos, "value:sym<string>", 'backtrack'=>1)
    .return (rx91_cur)
  rx91_restart219:
    repr_get_attr_obj rx91_cstack, rx91_cur, rx91_curclass, "$!cstack"
  rx91_fail220:
    unless rx91_bstack, rx91_done218
    pop $I19, rx91_bstack
    if_null rx91_cstack, rx91_cstack_done223
    unless rx91_cstack, rx91_cstack_done223
    dec $I19
    set $P11, rx91_cstack[$I19]
  rx91_cstack_done223:
    pop rx91_rep, rx91_bstack
    pop rx91_pos, rx91_bstack
    pop $I19, rx91_bstack
    lt rx91_pos, -1, rx91_done218
    lt rx91_pos, 0, rx91_fail220
    eq $I19, 0, rx91_fail220
    nqp_islist $I20, rx91_cstack
    unless $I20, rx91_jump221
    elements $I18, rx91_bstack
    le $I18, 0, rx91_cut222
    dec $I18
    set $I18, rx91_bstack[$I18]
  rx91_cut222:
    assign rx91_cstack, $I18
  rx91_jump221:
    jump $I19
  rx91_done218:
    rx91_cur."!cursor_fail"()
    .return (rx91_cur) 
.end
.HLL "perl6"
.namespace []
.sub "string" :subid("cuid_16_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 25
    .param pmc CALL_SIG :call_sig 
    .const 'Sub' $P5005 = 'cuid_15_1372180368.15198' 
    capture_lex $P5005 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx94_start
    .local string rx94_tgt
    .local int rx94_pos
    .local int rx94_off
    .local int rx94_eos
    .local int rx94_rep
    .local pmc rx94_cur
    .local pmc rx94_curclass
    .local pmc rx94_bstack
    .local pmc rx94_cstack
    rx94_start = self."!cursor_start_all"()
    set rx94_cur, rx94_start[0]
    set rx94_tgt, rx94_start[1]
    set rx94_pos, rx94_start[2]
    set rx94_curclass, rx94_start[3]
    set rx94_bstack, rx94_start[4]
    set $I19, rx94_start[5]
    store_lex unicode:"$\x{a2}", rx94_cur
    length rx94_eos, rx94_tgt
    eq $I19, 1, rx94_restart230
    gt rx94_pos, rx94_eos, rx94_fail231
    repr_get_attr_int $I11, self, rx94_curclass, "$!from"
    ne $I11, -1, rxscan95_done237
    goto rxscan95_scan236
  rxscan95_loop235:
    inc rx94_pos
    gt rx94_pos, rx94_eos, rx94_fail231
    repr_bind_attr_int rx94_cur, rx94_curclass, "$!from", rx94_pos
  rxscan95_scan236:
    nqp_rxmark rx94_bstack, rxscan95_loop235, rx94_pos, 0
  rxscan95_done237:
    add $I11, rx94_pos, 1
    gt $I11, rx94_eos, rx94_fail231
    substr $S10, rx94_tgt, rx94_pos, 1
    ne $S10, ucs4:"\"", rx94_fail231
    add rx94_pos, 1
    nqp_rxmark rx94_bstack, rxquantr96_done239, rx94_pos, 0
  rxquantr96_loop238:
    .const 'Sub' $P5004 = 'cuid_15_1372180368.15198' 
    capture_lex $P5004
    repr_bind_attr_int rx94_cur, rx94_curclass, "$!pos", rx94_pos
    $P11 = rx94_cur.$P5004()
    repr_get_attr_int $I11, $P11, rx94_curclass, "$!pos"
    lt $I11, 0, rx94_fail231
    goto rxsubrule102_pass255
  rxsubrule102_back256:
    $P11 = $P11."!cursor_next"()
    repr_get_attr_int $I11, $P11, rx94_curclass, "$!pos"
    lt $I11, 0, rx94_fail231
  rxsubrule102_pass255:
    rx94_cstack = rx94_cur."!cursor_capture"($P11, "0")
    set_addr $I11, rxsubrule102_back256
    push rx94_bstack, $I11
    push rx94_bstack, 0
    push rx94_bstack, rx94_pos
    elements $I11, rx94_cstack
    push rx94_bstack, $I11
    repr_get_attr_int rx94_pos, $P11, rx94_curclass, "$!pos"
    nqp_rxpeek $I19, rx94_bstack, rxquantr96_done239
    inc $I19
    inc $I19
    set rx94_rep, rx94_bstack[$I19]
    nqp_rxcommit rx94_bstack, rxquantr96_done239
    inc rx94_rep
    nqp_rxmark rx94_bstack, rxquantr96_done239, rx94_pos, rx94_rep
    goto rxquantr96_loop238
  rxquantr96_done239:
  alt103_0258:
    nqp_rxmark rx94_bstack, alt103_1259, rx94_pos, 0
    add $I11, rx94_pos, 1
    gt $I11, rx94_eos, rx94_fail231
    substr $S10, rx94_tgt, rx94_pos, 1
    ne $S10, ucs4:"\"", rx94_fail231
    add rx94_pos, 1
    goto alt103_end257
  alt103_1259:
    repr_bind_attr_int rx94_cur, rx94_curclass, "$!pos", rx94_pos
    $P11 = rx94_cur."FAILGOAL"("\\\"")
    repr_get_attr_int $I11, $P11, rx94_curclass, "$!pos"
    lt $I11, 0, rx94_fail231
    goto rxsubrule104_pass260
  rxsubrule104_back261:
    $P11 = $P11."!cursor_next"()
    repr_get_attr_int $I11, $P11, rx94_curclass, "$!pos"
    lt $I11, 0, rx94_fail231
  rxsubrule104_pass260:
    rx94_cstack = rx94_cur."!cursor_push_cstack"($P11)
    set_addr $I11, rxsubrule104_back261
    push rx94_bstack, $I11
    push rx94_bstack, 0
    push rx94_bstack, rx94_pos
    elements $I11, rx94_cstack
    push rx94_bstack, $I11
    repr_get_attr_int rx94_pos, $P11, rx94_curclass, "$!pos"
  alt103_end257:
    rx94_cur."!cursor_pass"(rx94_pos, "string", 'backtrack'=>1)
    .return (rx94_cur)
  rx94_restart230:
    repr_get_attr_obj rx94_cstack, rx94_cur, rx94_curclass, "$!cstack"
  rx94_fail231:
    unless rx94_bstack, rx94_done229
    pop $I19, rx94_bstack
    if_null rx94_cstack, rx94_cstack_done234
    unless rx94_cstack, rx94_cstack_done234
    dec $I19
    set $P11, rx94_cstack[$I19]
  rx94_cstack_done234:
    pop rx94_rep, rx94_bstack
    pop rx94_pos, rx94_bstack
    pop $I19, rx94_bstack
    lt rx94_pos, -1, rx94_done229
    lt rx94_pos, 0, rx94_fail231
    eq $I19, 0, rx94_fail231
    nqp_islist $I20, rx94_cstack
    unless $I20, rx94_jump232
    elements $I18, rx94_bstack
    le $I18, 0, rx94_cut233
    dec $I18
    set $I18, rx94_bstack[$I18]
  rx94_cut233:
    assign rx94_cstack, $I18
  rx94_jump232:
    jump $I19
  rx94_done229:
    rx94_cur."!cursor_fail"()
    .return (rx94_cur) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_15_1372180368.15198") :anon :lex :outer("cuid_16_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
    .param pmc self 
    .lex utf8:"$\x{a2}", $P101 
    .local pmc rx97_start
    .local string rx97_tgt
    .local int rx97_pos
    .local int rx97_off
    .local int rx97_eos
    .local int rx97_rep
    .local pmc rx97_cur
    .local pmc rx97_curclass
    .local pmc rx97_bstack
    .local pmc rx97_cstack
    rx97_start = self."!cursor_start_all"()
    set rx97_cur, rx97_start[0]
    set rx97_tgt, rx97_start[1]
    set rx97_pos, rx97_start[2]
    set rx97_curclass, rx97_start[3]
    set rx97_bstack, rx97_start[4]
    set $I19, rx97_start[5]
    store_lex unicode:"$\x{a2}", rx97_cur
    length rx97_eos, rx97_tgt
    eq $I19, 1, rx97_restart242
    gt rx97_pos, rx97_eos, rx97_fail243
    repr_get_attr_int $I11, self, rx97_curclass, "$!from"
    ne $I11, -1, rxscan98_done249
    goto rxscan98_scan248
  rxscan98_loop247:
    inc rx97_pos
    gt rx97_pos, rx97_eos, rx97_fail243
    repr_bind_attr_int rx97_cur, rx97_curclass, "$!from", rx97_pos
  rxscan98_scan248:
    nqp_rxmark rx97_bstack, rxscan98_loop247, rx97_pos, 0
  rxscan98_done249:
    new $P11, "ResizableIntegerArray"
    nqp_push_label $P11, alt99_0251
    nqp_push_label $P11, alt99_1253
    nqp_rxmark rx97_bstack, alt99_end250, -1, 0
    rx97_cur."!alt"(rx97_pos, "alt_nfa__4_1372180368.81379", $P11)
    goto rx97_fail243
  alt99_0251:
    repr_bind_attr_int rx97_cur, rx97_curclass, "$!pos", rx97_pos
    $P11 = rx97_cur."str"()
    repr_get_attr_int $I11, $P11, rx97_curclass, "$!pos"
    lt $I11, 0, rx97_fail243
    nqp_rxmark rx97_bstack, rxsubrule100_pass252, -1, 0
  rxsubrule100_pass252:
    rx97_cstack = rx97_cur."!cursor_capture"($P11, "str")
    repr_get_attr_int rx97_pos, $P11, rx97_curclass, "$!pos"
    goto alt99_end250
  alt99_1253:
    add $I11, rx97_pos, 1
    gt $I11, rx97_eos, rx97_fail243
    substr $S10, rx97_tgt, rx97_pos, 1
    ne $S10, ucs4:"\\", rx97_fail243
    add rx97_pos, 1
    repr_bind_attr_int rx97_cur, rx97_curclass, "$!pos", rx97_pos
    $P11 = rx97_cur."str_escape"()
    repr_get_attr_int $I11, $P11, rx97_curclass, "$!pos"
    lt $I11, 0, rx97_fail243
    nqp_rxmark rx97_bstack, rxsubrule101_pass254, -1, 0
  rxsubrule101_pass254:
    rx97_cstack = rx97_cur."!cursor_capture"($P11, "str_escape")
    repr_get_attr_int rx97_pos, $P11, rx97_curclass, "$!pos"
    goto alt99_end250
  alt99_end250:
    rx97_cur."!cursor_pass"(rx97_pos, 'backtrack'=>1)
    .return (rx97_cur)
  rx97_restart242:
    repr_get_attr_obj rx97_cstack, rx97_cur, rx97_curclass, "$!cstack"
  rx97_fail243:
    unless rx97_bstack, rx97_done241
    pop $I19, rx97_bstack
    if_null rx97_cstack, rx97_cstack_done246
    unless rx97_cstack, rx97_cstack_done246
    dec $I19
    set $P11, rx97_cstack[$I19]
  rx97_cstack_done246:
    pop rx97_rep, rx97_bstack
    pop rx97_pos, rx97_bstack
    pop $I19, rx97_bstack
    lt rx97_pos, -1, rx97_done241
    lt rx97_pos, 0, rx97_fail243
    eq $I19, 0, rx97_fail243
    nqp_islist $I20, rx97_cstack
    unless $I20, rx97_jump244
    elements $I18, rx97_bstack
    le $I18, 0, rx97_cut245
    dec $I18
    set $I18, rx97_bstack[$I18]
  rx97_cut245:
    assign rx97_cstack, $I18
  rx97_jump244:
    jump $I19
  rx97_done241:
    rx97_cur."!cursor_fail"()
    .return (rx97_cur) 
.end
.HLL "perl6"
.namespace []
.sub "str" :subid("cuid_17_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 29
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx105_start
    .local string rx105_tgt
    .local int rx105_pos
    .local int rx105_off
    .local int rx105_eos
    .local int rx105_rep
    .local pmc rx105_cur
    .local pmc rx105_curclass
    .local pmc rx105_bstack
    .local pmc rx105_cstack
    rx105_start = self."!cursor_start_all"()
    set rx105_cur, rx105_start[0]
    set rx105_tgt, rx105_start[1]
    set rx105_pos, rx105_start[2]
    set rx105_curclass, rx105_start[3]
    set rx105_bstack, rx105_start[4]
    set $I19, rx105_start[5]
    store_lex unicode:"$\x{a2}", rx105_cur
    length rx105_eos, rx105_tgt
    eq $I19, 1, rx105_restart264
    gt rx105_pos, rx105_eos, rx105_fail265
    repr_get_attr_int $I11, self, rx105_curclass, "$!from"
    ne $I11, -1, rxscan106_done271
    goto rxscan106_scan270
  rxscan106_loop269:
    inc rx105_pos
    gt rx105_pos, rx105_eos, rx105_fail265
    repr_bind_attr_int rx105_cur, rx105_curclass, "$!from", rx105_pos
  rxscan106_scan270:
    nqp_rxmark rx105_bstack, rxscan106_loop269, rx105_pos, 0
  rxscan106_done271:
    nqp_rxmark rx105_bstack, rxquantr107_done273, -1, 0
  rxquantr107_loop272:
    nqp_rxmark rx105_bstack, rxconj108_fail274, rx105_pos, 0
    goto rxconj108_first275
  rxconj108_fail274:
    goto rx105_fail265
  rxconj108_first275:
    add $I11, rx105_pos, 1
    gt $I11, rx105_eos, rx105_fail265
    substr $S10, rx105_tgt, rx105_pos, 1
    eq $S10, ucs4:"\\", rx105_fail265
    add rx105_pos, 1
    nqp_rxpeek $I19, rx105_bstack, rxconj108_fail274
    inc $I19
    set $I11, rx105_bstack[$I19]
    nqp_rxmark rx105_bstack, rxconj108_fail274, $I11, rx105_pos
    set rx105_pos, $I11
    ge rx105_pos, rx105_eos, rx105_fail265
    substr $S11, rx105_tgt, rx105_pos, 1
    index $I11, ucs4:"\t", $S11
    ge $I11, 0, rx105_fail265
    inc rx105_pos
    nqp_rxpeek $I19, rx105_bstack, rxconj108_fail274
    inc $I19
    set $I11, rx105_bstack[$I19]
    inc $I19
    set $I12, rx105_bstack[$I19]
    ne rx105_pos, $I12, rx105_fail265
    set rx105_pos, $I11
    ge rx105_pos, rx105_eos, rx105_fail265
    is_cclass $I11, .CCLASS_NEWLINE, rx105_tgt, rx105_pos
    if $I11, rx105_fail265
    substr $S10, rx105_tgt, rx105_pos, 2
    iseq $I11, $S10, "\r\n"
    add rx105_pos, $I11
    add rx105_pos, 1
    nqp_rxpeek $I19, rx105_bstack, rxconj108_fail274
    inc $I19
    set $I11, rx105_bstack[$I19]
    inc $I19
    set $I12, rx105_bstack[$I19]
    ne rx105_pos, $I12, rx105_fail265
    set rx105_pos, $I11
    ge rx105_pos, rx105_eos, rx105_fail265
    substr $S11, rx105_tgt, rx105_pos, 1
    index $I11, ucs4:"\"", $S11
    ge $I11, 0, rx105_fail265
    inc rx105_pos
    nqp_rxpeek $I19, rx105_bstack, rxconj108_fail274
    inc $I19
    set $I11, rx105_bstack[$I19]
    inc $I19
    set $I12, rx105_bstack[$I19]
    ne rx105_pos, $I12, rx105_fail265
    set rx105_pos, $I11
    ge rx105_pos, rx105_eos, rx105_fail265
    add rx105_pos, 1
    nqp_rxpeek $I19, rx105_bstack, rxquantr107_done273
    inc $I19
    inc $I19
    set rx105_rep, rx105_bstack[$I19]
    nqp_rxcommit rx105_bstack, rxquantr107_done273
    inc rx105_rep
    nqp_rxmark rx105_bstack, rxquantr107_done273, rx105_pos, rx105_rep
    goto rxquantr107_loop272
  rxquantr107_done273:
    rx105_cur."!cursor_pass"(rx105_pos, "str", 'backtrack'=>1)
    .return (rx105_cur)
  rx105_restart264:
    repr_get_attr_obj rx105_cstack, rx105_cur, rx105_curclass, "$!cstack"
  rx105_fail265:
    unless rx105_bstack, rx105_done263
    pop $I19, rx105_bstack
    if_null rx105_cstack, rx105_cstack_done268
    unless rx105_cstack, rx105_cstack_done268
    dec $I19
    set $P11, rx105_cstack[$I19]
  rx105_cstack_done268:
    pop rx105_rep, rx105_bstack
    pop rx105_pos, rx105_bstack
    pop $I19, rx105_bstack
    lt rx105_pos, -1, rx105_done263
    lt rx105_pos, 0, rx105_fail265
    eq $I19, 0, rx105_fail265
    nqp_islist $I20, rx105_cstack
    unless $I20, rx105_jump266
    elements $I18, rx105_bstack
    le $I18, 0, rx105_cut267
    dec $I18
    set $I18, rx105_bstack[$I18]
  rx105_cut267:
    assign rx105_cstack, $I18
  rx105_jump266:
    jump $I19
  rx105_done263:
    rx105_cur."!cursor_fail"()
    .return (rx105_cur) 
.end
.HLL "perl6"
.namespace []
.sub "str_escape" :subid("cuid_18_1372180368.15198") :anon :lex :outer("cuid_19_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
.annotate 'line', 33
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$/", $P104 
    .lex "$?REGEX", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P105, $P5001
    set $P5003, CALL_SIG
    set $P106, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx109_start
    .local string rx109_tgt
    .local int rx109_pos
    .local int rx109_off
    .local int rx109_eos
    .local int rx109_rep
    .local pmc rx109_cur
    .local pmc rx109_curclass
    .local pmc rx109_bstack
    .local pmc rx109_cstack
    rx109_start = self."!cursor_start_all"()
    set rx109_cur, rx109_start[0]
    set rx109_tgt, rx109_start[1]
    set rx109_pos, rx109_start[2]
    set rx109_curclass, rx109_start[3]
    set rx109_bstack, rx109_start[4]
    set $I19, rx109_start[5]
    store_lex unicode:"$\x{a2}", rx109_cur
    length rx109_eos, rx109_tgt
    eq $I19, 1, rx109_restart278
    gt rx109_pos, rx109_eos, rx109_fail279
    repr_get_attr_int $I11, self, rx109_curclass, "$!from"
    ne $I11, -1, rxscan110_done285
    goto rxscan110_scan284
  rxscan110_loop283:
    inc rx109_pos
    gt rx109_pos, rx109_eos, rx109_fail279
    repr_bind_attr_int rx109_cur, rx109_curclass, "$!from", rx109_pos
  rxscan110_scan284:
    nqp_rxmark rx109_bstack, rxscan110_loop283, rx109_pos, 0
  rxscan110_done285:
    new $P11, "ResizableIntegerArray"
    nqp_push_label $P11, alt111_0287
    nqp_push_label $P11, alt111_1291
    nqp_rxmark rx109_bstack, alt111_end286, -1, 0
    rx109_cur."!alt"(rx109_pos, "alt_nfa__5_1372180368.83725", $P11)
    goto rx109_fail279
  alt111_0287:
  alt112_0289:
    nqp_rxmark rx109_bstack, alt112_1290, rx109_pos, 0
    add $I11, rx109_pos, 1
    gt $I11, rx109_eos, rx109_fail279
    substr $S10, rx109_tgt, rx109_pos, 1
    ne $S10, ucs4:"\\", rx109_fail279
    add rx109_pos, 1
    goto alt112_end288
  alt112_1290:
    ge rx109_pos, rx109_eos, rx109_fail279
    substr $S11, rx109_tgt, rx109_pos, 1
    index $I11, ucs4:"\"/bfnrt", $S11
    lt $I11, 0, rx109_fail279
    inc rx109_pos
  alt112_end288:
    goto alt111_end286
  alt111_1291:
    add $I11, rx109_pos, 1
    gt $I11, rx109_eos, rx109_fail279
    substr $S10, rx109_tgt, rx109_pos, 1
    ne $S10, ucs4:"u", rx109_fail279
    add rx109_pos, 1
    nqp_rxmark rx109_bstack, rxquantr113_done293, -1, 0
  rxquantr113_loop292:
    repr_bind_attr_int rx109_cur, rx109_curclass, "$!pos", rx109_pos
    $P11 = rx109_cur."xdigit"()
    repr_get_attr_int $I11, $P11, rx109_curclass, "$!pos"
    lt $I11, 0, rx109_fail279
    goto rxsubrule114_pass294
  rxsubrule114_back295:
    $P11 = $P11."!cursor_next"()
    repr_get_attr_int $I11, $P11, rx109_curclass, "$!pos"
    lt $I11, 0, rx109_fail279
  rxsubrule114_pass294:
    rx109_cstack = rx109_cur."!cursor_capture"($P11, "xdigit")
    set_addr $I11, rxsubrule114_back295
    push rx109_bstack, $I11
    push rx109_bstack, 0
    push rx109_bstack, rx109_pos
    elements $I11, rx109_cstack
    push rx109_bstack, $I11
    repr_get_attr_int rx109_pos, $P11, rx109_curclass, "$!pos"
    nqp_rxpeek $I19, rx109_bstack, rxquantr113_done293
    inc $I19
    inc $I19
    set rx109_rep, rx109_bstack[$I19]
    nqp_rxcommit rx109_bstack, rxquantr113_done293
    inc rx109_rep
    ge rx109_rep, 4, rxquantr113_done293
    nqp_rxmark rx109_bstack, rxquantr113_done293, rx109_pos, rx109_rep
    goto rxquantr113_loop292
  rxquantr113_done293:
    lt rx109_rep, 4, rx109_fail279
    goto alt111_end286
  alt111_end286:
    rx109_cur."!cursor_pass"(rx109_pos, "str_escape", 'backtrack'=>1)
    .return (rx109_cur)
  rx109_restart278:
    repr_get_attr_obj rx109_cstack, rx109_cur, rx109_curclass, "$!cstack"
  rx109_fail279:
    unless rx109_bstack, rx109_done277
    pop $I19, rx109_bstack
    if_null rx109_cstack, rx109_cstack_done282
    unless rx109_cstack, rx109_cstack_done282
    dec $I19
    set $P11, rx109_cstack[$I19]
  rx109_cstack_done282:
    pop rx109_rep, rx109_bstack
    pop rx109_pos, rx109_bstack
    pop $I19, rx109_bstack
    lt rx109_pos, -1, rx109_done277
    lt rx109_pos, 0, rx109_fail279
    eq $I19, 0, rx109_fail279
    nqp_islist $I20, rx109_cstack
    unless $I20, rx109_jump280
    elements $I18, rx109_bstack
    le $I18, 0, rx109_cut281
    dec $I18
    set $I18, rx109_bstack[$I18]
  rx109_cut281:
    assign rx109_cstack, $I18
  rx109_jump280:
    jump $I19
  rx109_done277:
    rx109_cur."!cursor_fail"()
    .return (rx109_cur) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_23_1372180368.15198") :load :init
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
    .const 'Sub' $P5001 = 'cuid_22_1372180368.15198' 
    capture_lex $P5001 
    .local pmc cur_sc 
    .local pmc conflicts 
    nqp_dynop_setup 
    nqp_bigint_setup 
    nqp_native_call_setup 
    rakudo_dynop_setup 
    getinterp $P5001
    get_class $P5002, "LexPad"
    get_class $P5003, "NQPLexPad"
    $P5004 = $P5001."hll_map"($P5002, $P5003)
    load_bytecode "ModuleLoader.pbc"
    new $P5002, 'ResizableStringArray'
    push $P5002, "nqp"
    get_root_global $P5001, $P5002, "ModuleLoader"
    $P5001."load_module"("Perl6::ModuleLoader")
    .const 'Sub' $P5001 = "cuid_21_1372180368.15198" 
    get_hll_global $P5002, "ModuleLoader"
    $P5003 = $P5002."load_setting"("CORE")
    $P5004 = $P5001."set_outer_ctx"($P5003)
    nqp_create_sc $P5001, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E"
    set cur_sc, $P5001
    $P5002 = cur_sc."set_description"("lib/JSON/Tiny/Grammar.pm")
    new $P5003, 'ResizablePMCArray'
    set conflicts, $P5003
    new $P5004, 'ResizableStringArray'
    null $S5001
    push $P5004, $S5001
    push $P5004, "Uninstantiable"
    push $P5004, "P6opaque"
    push $P5004, "ACCEPTS"
    push $P5004, "34AEF0B7DBE5E000126E01B596D8807B78596907"
    push $P5004, "src/gen/CORE.setting"
    push $P5004, "WHERE"
    push $P5004, "WHICH"
    push $P5004, "take"
    push $P5004, "WHY"
    push $P5004, "Bool"
    push $P5004, "so"
    push $P5004, "not"
    push $P5004, "defined"
    push $P5004, "new"
    push $P5004, "CREATE"
    push $P5004, "bless"
    push $P5004, "BUILDALL"
    push $P5004, "BUILD_LEAST_DERIVED"
    push $P5004, "Numeric"
    push $P5004, "Real"
    push $P5004, "Str"
    push $P5004, "Stringy"
    push $P5004, "item"
    push $P5004, "say"
    push $P5004, "print"
    push $P5004, "gist"
    push $P5004, "perl"
    push $P5004, "DUMP"
    push $P5004, "DUMP-PIECES"
    push $P5004, "DUMP-OBJECT-ATTRS"
    push $P5004, "isa"
    push $P5004, "does"
    push $P5004, "can"
    push $P5004, "clone"
    push $P5004, "Capture"
    push $P5004, "dispatch:<var>"
    push $P5004, "dispatch:<::>"
    push $P5004, "dispatch:<!>"
    push $P5004, "dispatch:<.^>"
    push $P5004, "dispatch:<.=>"
    push $P5004, "dispatch:<.?>"
    push $P5004, "dispatch:<.+>"
    push $P5004, "dispatch:<.*>"
    push $P5004, "dispatch:<hyper>"
    push $P5004, "WALK"
    push $P5004, "eager"
    push $P5004, "elems"
    push $P5004, "end"
    push $P5004, "classify"
    push $P5004, "categorize"
    push $P5004, "uniq"
    push $P5004, "infinite"
    push $P5004, "flat"
    push $P5004, "hash"
    push $P5004, "list"
    push $P5004, "lol"
    push $P5004, "pick"
    push $P5004, "roll"
    push $P5004, "reverse"
    push $P5004, "sort"
    push $P5004, "values"
    push $P5004, "keys"
    push $P5004, "kv"
    push $P5004, "pairs"
    push $P5004, "Array"
    push $P5004, "grep"
    push $P5004, "first"
    push $P5004, "join"
    push $P5004, "map"
    push $P5004, "min"
    push $P5004, "max"
    push $P5004, "minmax"
    push $P5004, "push"
    push $P5004, "tree"
    push $P5004, "unshift"
    push $P5004, "postcircumfix:<[ ]>"
    push $P5004, "at_pos"
    push $P5004, "all"
    push $P5004, "any"
    push $P5004, "one"
    push $P5004, "none"
    push $P5004, "postcircumfix:<{ }>"
    push $P5004, "at_key"
    push $P5004, "reduce"
    push $P5004, "FLATTENABLE_LIST"
    push $P5004, "FLATTENABLE_HASH"
    push $P5004, "MATCH"
    push $P5004, "MATCH_SAVE"
    push $P5004, "INTERPOLATE"
    push $P5004, "OTHERGRAMMAR"
    push $P5004, "RECURSE"
    push $P5004, "prior"
    push $P5004, "orig"
    push $P5004, "target"
    push $P5004, "from"
    push $P5004, "pos"
    push $P5004, "CAPHASH"
    push $P5004, "!cursor_init"
    push $P5004, "!cursor_start_all"
    push $P5004, "!cursor_start_cur"
    push $P5004, "!cursor_start_subcapture"
    push $P5004, "!cursor_capture"
    push $P5004, "!cursor_push_cstack"
    push $P5004, "!cursor_pass"
    push $P5004, "!cursor_fail"
    push $P5004, "!cursor_pos"
    push $P5004, "!cursor_next"
    push $P5004, "!cursor_more"
    push $P5004, "!reduce"
    push $P5004, "!reduce_with_match"
    push $P5004, "!shared"
    push $P5004, "!protoregex"
    push $P5004, "!protoregex_nfa"
    push $P5004, "!protoregex_table"
    push $P5004, "!alt"
    push $P5004, "!alt_nfa"
    push $P5004, "!precompute_nfas"
    push $P5004, "!dba"
    push $P5004, "!highwater"
    push $P5004, "!highexpect"
    push $P5004, "!fresh_highexpect"
    push $P5004, "!set_highexpect"
    push $P5004, "!clear_highwater"
    push $P5004, "!BACKREF"
    push $P5004, "!LITERAL"
    push $P5004, "at"
    push $P5004, "before"
    push $P5004, "after"
    push $P5004, "ws"
    push $P5004, "ww"
    push $P5004, "wb"
    push $P5004, "ident"
    push $P5004, "alpha"
    push $P5004, "alnum"
    push $P5004, "upper"
    push $P5004, "lower"
    push $P5004, "digit"
    push $P5004, "xdigit"
    push $P5004, "space"
    push $P5004, "blank"
    push $P5004, "cntrl"
    push $P5004, "punct"
    push $P5004, "FAILGOAL"
    push $P5004, "parse"
    push $P5004, "parsefile"
    push $P5004, "TOP"
    push $P5004, "object"
    push $P5004, "pairlist"
    push $P5004, "pair"
    push $P5004, "array"
    push $P5004, "arraylist"
    push $P5004, "value"
    push $P5004, "value:sym<number>"
    push $P5004, "value:sym<true>"
    push $P5004, "value:sym<false>"
    push $P5004, "value:sym<null>"
    push $P5004, "value:sym<object>"
    push $P5004, "value:sym<array>"
    push $P5004, "value:sym<string>"
    push $P5004, "string"
    push $P5004, "str"
    push $P5004, "str_escape"
    push $P5004, "B9A1DB43DA676D1F1261647412D906DA1B244D1A-1372102072.12878"
    push $P5004, "src/gen/BOOTSTRAP.nqp"
    push $P5004, "5EF9E44C09592595762FECF63739A10E263E396B-1372101921.63247"
    push $P5004, "src/stage2/QRegex.nqp"
    push $P5004, "7A67D46DDEA3C60BB73DFB1CA4F76715F3D1212C-1372101917.20204"
    push $P5004, "src/stage2/NQPCORE.setting"
    push $P5004, "$!ast"
    push $P5004, "$!shared"
    push $P5004, "$!from"
    push $P5004, "$!pos"
    push $P5004, "$!match"
    push $P5004, "$!name"
    push $P5004, "$!bstack"
    push $P5004, "$!cstack"
    push $P5004, "$!regexsub"
    push $P5004, "$!restart"
    push $P5004, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613"
    push $P5004, "src/gen/Metamodel.nqp"
    push $P5004, "$_"
    push $P5004, "$/"
    push $P5004, "$!"
    push $P5004, ""
    push $P5004, "alt_nfa__1_1372180368.61486"
    push $P5004, "%_"
    push $P5004, "{"
    push $P5004, "}"
    push $P5004, ":"
    push $P5004, "["
    push $P5004, "]"
    push $P5004, "123456789"
    push $P5004, "0123456789"
    push $P5004, "eE"
    push $P5004, "alt_nfa__2_1372180368.73311"
    push $P5004, "alt_nfa__3_1372180368.73335"
    push $P5004, "number"
    push $P5004, "sym"
    push $P5004, "-"
    push $P5004, "true"
    push $P5004, "false"
    push $P5004, "null"
    push $P5004, "0"
    push $P5004, "alt_nfa__4_1372180368.81379"
    push $P5004, "alt_nfa__5_1372180368.83725"
    push $P5004, "GLOBAL"
    push $P5004, "JSON"
    push $P5004, "EXPORT"
    push $P5004, "JSON::Tiny::Grammar"
    push $P5004, "Tiny"
    push $P5004, "Grammar"
    push $P5004, "!UNIT_MARKER"
    push $P5004, "6"
    .const 'Sub' $P5005 = 'cuid_22_1372180368.15198' 
    capture_lex $P5005
    $P5006 = $P5005()
    nqp_deserialize_sc "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AwAAAAAAAAAAAAAAAAALAAIAAABNAAAACgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAEAAAAAgAAAAEAAAAAAAAABAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAgABAAAA430AAAIABAAAABoAAAABAAEAAgAEAAAAGgAAAAIABAAAABoAAAACAAQAAAAaAAAAAgAEAAAAGgAAAAIABAAAABoAAAACAAQAAAAaAAAA////////////////////////////////AAAAAAAAAAAFAAAAAAAAAAIAAgAAABAAAAADAAIAAgAAABEAAAADAAIAAQAAAI8uAAAKAAoAAACpAAAABAAAAAAAAAAAAKoAAAAEAAEAAAAAAAAAqwAAAAQAAgAAAAAAAACsAAAABAADAAAAAAAAAK0AAAAEAAQAAAAAAAAArgAAAAQABQAAAAAAAACvAAAABAAGAAAAAAAAALAAAAAEAAcAAAAAAAAAsQAAAAQACAAAAAAAAACyAAAABAAJAAAAAAAAAAIAAgAAADEAAAADAAIAAAAAAAoAAAADAP////////////////////8AAAAAjQAAAAAAAAALAAAAAgAAAAAAjgAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAI8AAAAAAAAADAAAAAIAAAAAAJAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACRAAAAAAAAAIUAAAACAAAAAACSAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAEAAABqAAAAAAAAAAEAAAAFAAAALQAAABgAAAABAAAAAQAAAGgAAAAuAAAAAQAAAAUAAAAtAAAARAAAAAEAAAABAAAAaAAAAFoAAAABAAAABQAAAC0AAABwAAAAAQAAAAEAAABoAAAAhgAAAAEAAAABAAAAywEAAJwAAAABAAAAAAAAAAIAAACwAAAAAAAAAAAAAAADAAAA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AAAAAAQACAAAAAAAAAAGAJYAAAAEAAQAAAAAAAAABwAGAAAABQAAAAAAAAAQQAQAIAAAAAAAAAAEAAQAAAAAAAAABAABAAAAAAAAAAQAAAAAAAAAAAAEAAUAAAAAAAAABwADAAAABAABAAAAAAAAAAQAAAAAAAAAAAAEAAAAAAAAAAAACgABAAAAuQAAAAcAAgAAAAcAAgAAAAcAAAAAAAcAAwAAAAQACAAAAAAAAAAGAJMAAAAEAAAAAAAAAAAABwACAAAABwAAAAAABwADAAAABAAIAAAAAAAAAAYAlgAAAAQAAAAAAAAAAAACAAAAAAAFAAAAAgACAAAAEQAAAAEAAAAAAAEAAQDAAAAAAAAAAAIAAAAAAAoAAAABAAEAAAAAAAEAAQABAAEAAgACAAAAEAAAAAAAAAAAAAAAugAAALoAAAABAAEAkAAAAAAAAAACAAIAAAAQAAAAAQABAAAAAAABAAEAAgAAAAAAEAAAAAEABwACAAAAAgAAAAAADwAAAAIAAAAAABEAAAABAAEAAQACAAAAAAANAAAACwAAAAAAAQAAAAIAAAAAABoAAAADAAEAAQABAAEAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACgAAAAAAAAAAAAAAAQABAAoAAgAAALgAAAAEAAAAAAAAAAAAlAAAAAUAAAAAAAAA8D8EAAAAAAAAAAAAAQC7AAAAvAAAAAIAAAAAAAUAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACgAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAAQAAAAAAAAAAAAAAC6AAAAugAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAAAYAAAAAQAHAAIAAAACAAAAAAAXAAAAAgAAAAAAGQAAAAEAAQABAAIAAAAAABMAAAALAAAAAAACAAAAAgAAAAAAIAAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAKAAAAAAAAAAAAAAABAAEACgACAAAAuAAAAAQAAAAAAAAAAACVAAAABQAAAAAAAAAAQAQAAAAAAAAAAAABAAIAAAAAAAUAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACgAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAAQAAAAAAAAAAAAAAC6AAAAugAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAAAeAAAAAQAHAAIAAAACAAAAAAAdAAAAAgAAAAAAHwAAAAEAAQABAAIAAAAAABsAAAALAAAAAAADAAAAAgAAAAAAJwAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAKAAAAAAAAAAAAAAABAAEACgADAAAAuAAAAAQAAAAAAAAAAACgAAAABQAAAAAAAADwP5gAAAAFAAAAAAAAAPA/BAAAAAAAAAAAAAEAvQAAAAIAAAAAAAUAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACgAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAAQAAAAAAAAAAAAAAC6AAAAugAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAAAlAAAAAQAHAAIAAAACAAAAAAAkAAAAAgAAAAAAJgAAAAEAAQABAAIAAAAAACEAAAALAAAAAAAEAAAAAgAAAAAALwAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAKAAAAAAAAAAAAAAABAAEACgACAAAAuAAAAAQAAAAAAAAAAACXAAAABQAAAAAAAADwPwQAAAAAAAAAAAABAL4AAAC/AAAAAgAAAAAABQAAAAIAAgAAABEAAAABAAAAAAABAAEAwAAAAAAAAAACAAAAAAAKAAAAAQABAAAAAAABAAEAAQABAAIAAgAAABAAAAAAAAAAAAAAALoAAAC6AAAAAQABAJAAAAAAAAAAAgACAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAAC0AAAABAAcAAgAAAAIAAAAAACwAAAACAAAAAAAuAAAAAQABAAEAAgAAAAAAKAAAAAsAAAAAAAUAAAACAAAAAAA1AAAAAwABAAEAAQABAAAAAAAAAAAAAQAAAAAAAAAAAAIAAAAAAAoAAAAAAAAAAAAAAAEAAQAKAAIAAAC4AAAABAAAAAAAAAAAAJgAAAAFAAAAAAAAAABABAAAAAAAAAAAAAEAAgAAAAAABQAAAAIAAgAAABEAAAABAAAAAAABAAEAwAAAAAAAAAACAAAAAAAKAAAAAQABAAAAAAABAAEAAQABAAIAAgAAABAAAAAAAAAAAAAAALoAAAC6AAAAAQABAJAAAAAAAAAAAgACAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAADMAAAABAAcAAgAAAAIAAAAAADIAAAACAAAAAAA0AAAAAQABAAEAAgAAAAAAMAAAAAsAAAAAAAYAAAACAAAAAAA6AAAAAwABAAcAAAAAAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAKAAAAAAAAAAAAAAABAAEAAQABAAEAAAAAAAEAAQDAAAAAAAAAAAIAAAAAAAoAAAABAAEAAAAAAAEAAQABAAEAAgACAAAAEAAAAAAAAAAAAAAAugAAALoAAAABAAEAkAAAAAAAAAACAAIAAAAQAAAAAQABAAAAAAABAAEAAgAAAAAAOAAAAAEABwACAAAAAgAAAAAANwAAAAIAAAAAADkAAAABAAEAAQACAAAAAAA2AAAACwAAAAAABwAAAAIAAAAAAEMAAAADAAEAAQABAAEAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACgAAAAAAAAAAAAAAAQABAAoAAQAAALgAAAAEAAAAAAAAAAAABwANAAAABwAAAAAABwAGAAAABAACAAAAAAAAAAQALQAAAAAAAAAEAAIAAAAAAAAABAABAAAAAAAAAAQAAAAAAAAAAAAEAAIAAAAAAAAABwAGAAAABAACAAAAAAAAAAQAMAAAAAAAAAAEAAMAAAAAAAAABQAAAAAAAAAYQAYAwAAAAAQABAAAAAAAAAAHAAYAAAAEAAIAAAAAAAAABAAuAAAAAAAAAAQABQAAAAAAAAAEAAEAAAAAAAAABAAAAAAAAAAAAAQABwAAAAAAAAAHAAYAAAAFAAAAAAAAABhABgDBAAAABAAEAAAAAAAAAAQAAQAAAAAAAAAEAAAAAAAAAAAABAADAAAAAAAAAAcAAwAAAAQAAQAAAAAAAAAEAAAAAAAAAAAABAAGAAAAAAAAAAcAAwAAAAUAAAAAAAAAGEAGAMEAAAAEAAcAAAAAAAAABwAMAAAABAABAAAAAAAAAAQAAAAAAAAAAAAEAAYAAAAAAAAABAABAAAAAAAAAAQAAAAAAAAAAAAEAAgAAAAAAAAABQAAAAAAAAAYQAYAwgAAAAQACQAAAAAAAAAEAAEAAAAAAAAABAAAAAAAAAAAAAQAAAAAAAAAAAAHAAAAAAAHAAkAAAAEAAIAAAAAAAAABAArAAAAAAAAAAQACgAAAAAAAAAEAAIAAAAAAAAABAAtAAAAAAAAAAQACgAAAAAAAAAEAAEAAAAAAAAABAAAAAAAAAAAAAQACgAAAAAAAAAHAAMAAAAEAAEAAAAAAAAABAAAAAAAAAAAAAQACwAAAAAAAAAHAAMAAAAFAAAAAAAAABhABgDBAAAABAAMAAAAAAAAAAcABgAAAAQAAQAAAAAAAAAEAAAAAAAAAAAABAALAAAAAAAAAAQAAQAAAAAAAAAEAAAAAAAAAAAABAAAAAAAAAAAAAoAAgAAAMMAAAAHAAIAAAAHAAIAAAAHAAAAAAAHAAMAAAAEAAIAAAAAAAAABAAwAAAAAAAAAAQAAAAAAAAAAAAHAAMAAAAHAAAAAAAHAAMAAAAFAAAAAAAAABhABgDAAAAABAACAAAAAAAAAAcABgAAAAUAAAAAAAAAGEAGAMEAAAAEAAIAAAAAAAAABAABAAAAAAAAAAQAAAAAAAAAAAAEAAAAAAAAAAAAxAAAAAcAAgAAAAcAAgAAAAcAAAAAAAcAAwAAAAQAAgAAAAAAAAAEACsAAAAAAAAABAAAAAAAAAAAAAcAAgAAAAcAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAC0AAAAAAAAABAAAAAAAAAAAAMUAAADGAAAAxwAAAAIAAAAAAAUAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACgAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAAQAAAAAAAAAAAAAAC6AAAAugAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAABBAAAAAQAHAAIAAAACAAAAAABAAAAAAgAAAAAAQgAAAAEAAQABAAIAAAAAADsAAAALAAAAAAAIAAAAAgAAAAAASgAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAKAAAAAAAAAAAAAAABAAEACgACAAAAxgAAAAUAAAAAAAAA8D+4AAAABAAAAAAAAAAAAAcABQAAAAcAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAHQAAAAAAAAABAACAAAAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAHIAAAAAAAAABAADAAAAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAHUAAAAAAAAABAAEAAAAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAGUAAAAAAAAABAAAAAAAAAAAAAEAyAAAAAIAAAAAAAUAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACgAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAAQAAAAAAAAAAAAAAC6AAAAugAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAABIAAAAAQAHAAIAAAACAAAAAABHAAAAAgAAAAAASQAAAAEAAQABAAIAAAAAAEQAAAALAAAAAAAJAAAAAgAAAAAAUQAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAKAAAAAAAAAAAAAAABAAEACgACAAAAxgAAAAUAAAAAAAAA8D+4AAAABAAAAAAAAAAAAAcABgAAAAcAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAGYAAAAAAAAABAACAAAAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAGEAAAAAAAAABAADAAAAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAGwAAAAAAAAABAAEAAAAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAHMAAAAAAAAABAAFAAAAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAGUAAAAAAAAABAAAAAAAAAAAAAEAyQAAAAIAAAAAAAUAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACgAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAAQAAAAAAAAAAAAAAC6AAAAugAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAABPAAAAAQAHAAIAAAACAAAAAABOAAAAAgAAAAAAUAAAAAEAAQABAAIAAAAAAEsAAAALAAAAAAAKAAAAAgAAAAAAWAAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAKAAAAAAAAAAAAAAABAAEACgACAAAAxgAAAAUAAAAAAAAA8D+4AAAABAAAAAAAAAAAAAcABQAAAAcAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAG4AAAAAAAAABAACAAAAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAHUAAAAAAAAABAADAAAAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAGwAAAAAAAAABAAEAAAAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAGwAAAAAAAAABAAAAAAAAAAAAAEAygAAAAIAAAAAAAUAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACgAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAAQAAAAAAAAAAAAAAC6AAAAugAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAABWAAAAAQAHAAIAAAACAAAAAABVAAAAAgAAAAAAVwAAAAEAAQABAAIAAAAAAFIAAAALAAAAAAALAAAAAgAAAAAAXwAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAKAAAAAAAAAAAAAAABAAEACgACAAAAkwAAAAUAAAAAAAAA8D+4AAAABAAAAAAAAAAAAAcAAgAAAAcAAAAAAAcAAwAAAAQACAAAAAAAAAAGAJMAAAAEAAAAAAAAAAAAAQCTAAAAAgAAAAAABQAAAAIAAgAAABEAAAABAAAAAAABAAEAwAAAAAAAAAACAAAAAAAKAAAAAQABAAAAAAABAAEAAQABAAIAAgAAABAAAAAAAAAAAAAAALoAAAC6AAAAAQABAJAAAAAAAAAAAgACAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAAF0AAAABAAcAAgAAAAIAAAAAAFwAAAACAAAAAABeAAAAAQABAAEAAgAAAAAAWQAAAAsAAAAAAAwAAAACAAAAAABmAAAAAwABAAEAAQABAAAAAAAAAAAAAQAAAAAAAAAAAAIAAAAAAAoAAAAAAAAAAAAAAAEAAQAKAAIAAACWAAAABQAAAAAAAADwP7gAAAAEAAAAAAAAAAAABwACAAAABwAAAAAABwADAAAABAAIAAAAAAAAAAYAlgAAAAQAAAAAAAAAAAABAJYAAAACAAAAAAAFAAAAAgACAAAAEQAAAAEAAAAAAAEAAQDAAAAAAAAAAAIAAAAAAAoAAAABAAEAAAAAAAEAAQABAAEAAgACAAAAEAAAAAAAAAAAAAAAugAAALoAAAABAAEAkAAAAAAAAAACAAIAAAAQAAAAAQABAAAAAAABAAEAAgAAAAAAZAAAAAEABwACAAAAAgAAAAAAYwAAAAIAAAAAAGUAAAABAAEAAQACAAAAAABgAAAACwAAAAAADQAAAAIAAAAAAG0AAAADAAEAAQABAAEAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACgAAAAAAAAAAAAAAAQABAAoAAgAAAKAAAAAFAAAAAAAAAPA/uAAAAAQAAAAAAAAAAAAHAAIAAAAHAAAAAAAHAAMAAAAEAAgAAAAAAAAABgCgAAAABAAAAAAAAAAAAAEAoAAAAAIAAAAAAAUAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACgAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAAQAAAAAAAAAAAAAAC6AAAAugAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAABrAAAAAQAHAAIAAAACAAAAAABqAAAAAgAAAAAAbAAAAAEAAQABAAIAAAAAAGcAAAALAAAAAAAPAAAAAgAAAAAAdQAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAKAAAAAAAAAAAAAAABAAEACgACAAAAuAAAAAUAAAAAAAAA8D/LAAAABQAAAAAAAAAAQAcABQAAAAcAAAAAAAcAAwAAAAQAAgAAAAAAAAAEACIAAAAAAAAABAACAAAAAAAAAAcACQAAAAQACAAAAAAAAAAGAKEAAAAEAAIAAAAAAAAABAACAAAAAAAAAAQAXAAAAAAAAAAEAAMAAAAAAAAABAABAAAAAAAAAAQAAAAAAAAAAAAEAAQAAAAAAAAABwADAAAABAAIAAAAAAAAAAYAogAAAAQAAgAAAAAAAAAHAAMAAAAEAAAAAAAAAAAABAAAAAAAAAAAAAQAAAAAAAAAAAABAAcAAAAAAAEAAQABAAIAAAAAAHAAAAALAAAAAAAOAAAAAgAAAAAAbwAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAKAAAAAAAAAAAAAAABAAEACgADAAAAoQAAAAQAAQAAAAAAAAC4AAAABAAAAAAAAAAAAKIAAAAEAAEAAAAAAAAABwADAAAABwAAAAAABwAGAAAABAAIAAAAAAAAAAYAoQAAAAQAAAAAAAAAAAAEAAIAAAAAAAAABABcAAAAAAAAAAQAAgAAAAAAAAAHAAMAAAAEAAgAAAAAAAAABgCiAAAABAAAAAAAAAAAAAoAAQAAAMwAAAAHAAIAAAAHAAIAAAAHAAAAAAAHAAMAAAAEAAgAAAAAAAAABgChAAAABAAAAAAAAAAAAAcAAwAAAAcAAAAAAAcAAwAAAAQAAgAAAAAAAAAEAFwAAAAAAAAABAACAAAAAAAAAAcAAwAAAAQACAAAAAAAAAAGAKIAAAAEAAAAAAAAAAAAAgAAAAAABQAAAAIAAgAAABEAAAABAAAAAAABAAEAwAAAAAAAAAACAAAAAAAKAAAAAQABAAAAAAABAAEAAQABAAIAAgAAABAAAAAAAAAAAAAAALoAAAC6AAAAAQABAJAAAAAAAAAAAgACAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAAHMAAAABAAcAAgAAAAIAAAAAAHIAAAACAAAAAAB0AAAAAQABAAEAAgAAAAAAbgAAAAsAAAAAABAAAAACAAAAAAB7AAAAAwABAAEAAQABAAAAAAAAAAAAAQAAAAAAAAAAAAIAAAAAAAoAAAAAAAAAAAAAAAEAAQAKAAEAAAC4AAAABAAAAAAAAAAAAAcABAAAAAcAAAAAAAcAAwAAAAQAAQAAAAAAAAAEAAAAAAAAAAAABAACAAAAAAAAAAcAAwAAAAQAAAAAAAAAAAAEAAAAAAAAAAAABAAAAAAAAAAAAAcABgAAAAQAAQAAAAAAAAAEAAAAAAAAAAAABAACAAAAAAAAAAQAAQAAAAAAAAAEAAAAAAAAAAAABAAAAAAAAAAAAAEAAgAAAAAABQAAAAIAAgAAABEAAAABAAAAAAABAAEAwAAAAAAAAAACAAAAAAAKAAAAAQABAAAAAAABAAEAAQABAAIAAgAAABAAAAAAAAAAAAAAALoAAAC6AAAAAQABAJAAAAAAAAAAAgACAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAAHkAAAABAAcAAgAAAAIAAAAAAHgAAAACAAAAAAB6AAAAAQABAAEAAgAAAAAAdgAAAAsAAAAAABEAAAACAAAAAACBAAAAAwABAAEAAQABAAAAAAAAAAAAAQAAAAAAAAAAAAIAAAAAAAoAAAAAAAAAAAAAAAEAAQAKAAIAAAC4AAAABAAAAAAAAAAAAIoAAAAEAAIAAAAAAAAABwAHAAAABwAAAAAABwAGAAAABAAAAAAAAAAAAAQAAAAAAAAAAAAEAAAAAAAAAAAABAACAAAAAAAAAAQAdQAAAAAAAAAEAAIAAAAAAAAABwADAAAABAAIAAAAAAAAAAYAigAAAAQAAwAAAAAAAAAHAAMAAAAEAAgAAAAAAAAABgCKAAAABAAEAAAAAAAAAAcAAwAAAAQACAAAAAAAAAAGAIoAAAAEAAUAAAAAAAAABwADAAAABAAIAAAAAAAAAAYAigAAAAQABgAAAAAAAAAHAAMAAAAEAAEAAAAAAAAABAAAAAAAAAAAAAQAAAAAAAAAAAAKAAEAAADNAAAABwACAAAABwACAAAABwAAAAAABwAGAAAABAAAAAAAAAAAAAQAAAAAAAAAAAAEAAAAAAAAAAAABAAAAAAAAAAAAAQAAAAAAAAAAAAEAAAAAAAAAAAABwAHAAAABwAAAAAABwADAAAABAACAAAAAAAAAAQAdQAAAAAAAAAEAAIAAAAAAAAABwADAAAABAAIAAAAAAAAAAYAigAAAAQAAwAAAAAAAAAHAAMAAAAEAAgAAAAAAAAABgCKAAAABAAEAAAAAAAAAAcAAwAAAAQACAAAAAAAAAAGAIoAAAAEAAUAAAAAAAAABwADAAAABAAIAAAAAAAAAAYAigAAAAQABgAAAAAAAAAHAAMAAAAEAAEAAAAAAAAABAAAAAAAAAAAAAQAAAAAAAAAAAACAAAAAAAFAAAAAgACAAAAEQAAAAEAAAAAAAEAAQDAAAAAAAAAAAIAAAAAAAoAAAABAAEAAAAAAAEAAQABAAEAAgACAAAAEAAAAAAAAAAAAAAAugAAALoAAAABAAEAkAAAAAAAAAACAAIAAAAQAAAAAQABAAAAAAABAAEAAgAAAAAAfwAAAAEABwACAAAAAgAAAAAAfgAAAAIAAAAAAIAAAAABAAEAAQACAAAAAAB8AAAABwAAAAAAAQABAAEAAgAAAAAAgwAAAAsAAAAAABIAAAACAAAAAACCAAAAAwABAAEAAgACAAAAgwAAAAIAAAAAAJUAAAABAAcAAAAAAAEAAQABAAIAAAAAAAIAAAAEAAEAAAAAAAAABgDOAAAAAQAKAAEAAADPAAAAAgAAAAAACwAAAAEABAABAAAAAAAAAAYA0AAAAAEACgAAAAAAAQAHAAAAAAAHAAAAAAAHAAAAAAAHAAAAAAAEAAEAAAAAAAAABgDRAAAAAQABAAEABwAAAAAACgAAAAAAAQAKABEAAACSAAAAAgAAAAAADQAAAJMAAAACAAAAAAATAAAAlAAAAAIAAAAAABsAAACVAAAAAgAAAAAAIQAAAJYAAAACAAAAAAAoAAAAlwAAAAIAAAAAADAAAACYAAAAAgAAAAAANgAAAJkAAAACAAAAAAA7AAAAmgAAAAIAAAAAAEQAAACbAAAAAgAAAAAASwAAAJwAAAACAAAAAABSAAAAnQAAAAIAAAAAAFkAAACeAAAAAgAAAAAAYAAAAJ8AAAACAAAAAABnAAAAoAAAAAIAAAAAAG4AAAChAAAAAgAAAAAAdgAAAKIAAAACAAAAAAB8AAAACgAAAAAABwARAAAAAgAAAAAADQAAAAIAAAAAABMAAAACAAAAAAAbAAAAAgAAAAAAIQAAAAIAAAAAACgAAAACAAAAAAAwAAAAAgAAAAAANgAAAAIAAAAAADsAAAACAAAAAABEAAAAAgAAAAAASwAAAAIAAAAAAFIAAAACAAAAAABZAAAAAgAAAAAAYAAAAAIAAAAAAGcAAAACAAAAAABuAAAAAgAAAAAAdgAAAAIAAAAAAHwAAAAKAAAAAAAKAAAAAAAHAAAAAAAHAAAAAAAHAAEAAAACAAIAAAAxAAAABwAAAAAAAgAEAAAAGgAAAAcABQAAAAIAAAAAAAoAAAACAAIAAAAxAAAAAgABAAAAjy4AAAIAAgAAABEAAAACAAIAAAAQAAAABwAFAAAAAgAAAAAACgAAAAIAAgAAADEAAAACAAEAAACPLgAAAgACAAAAEQAAAAIAAgAAABAAAAAHAAAAAAAHAAAAAAAHAAAAAAABAAQABQAAAAAAAAAEAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAEACgAAAAAACgAAAAAACgAAAAAAAQAEAAEAAAAAAAAABgDPAAAAAQAKAAEAAADSAAAAAgAAAAAADAAAAAEABAABAAAAAAAAAAYA0gAAAAEACgABAAAA0wAAAAIAAAAAAAoAAAABAAQAAQAAAAAAAAAGANQAAAABAAoAAAAAAAEABwABAAAAAgAAAAAAlgAAAAEAAgAAAAAAlwAAAAIAAQAAAMR0AAACAAEAAADGdAAAAgACAAAAggAAAAEAAQABAAcAAAAAAAIAAAAAAIQAAAACAAEAAAAoPwAAAgAAAAAAmAAAAAEAAgACAAAAFgEAAAIAAgAAABAAAAABANUAAAA=", cur_sc, $P5004, $P5006, conflicts
    unless conflicts goto if115_end297 
    get_hll_global $P5007, "ModuleLoader"
    $P5008 = $P5007."resolve_repossession_conflicts"(conflicts)
  if115_end297:
    .const 'Sub' $P5001 = "cuid_1_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 13
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_2_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 19
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_3_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 27
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_4_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 33
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_5_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 40
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_6_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 48
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_7_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 54
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_8_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 59
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_9_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 68
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_10_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 75
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_11_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 82
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_12_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 89
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_13_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 96
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_14_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 103
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_15_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 112
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_16_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 110
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_17_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 118
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_18_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 124
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_19_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 131
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_20_1372180368.15198" 
    nqp_get_sc_object $P5002, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 2
    set_sub_code_object $P5001, $P5002
    nqp_get_sc_object $P5001, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 0
    set_hll_global "GLOBAL", $P5001
    .const "LexInfo" $P5001 = "cuid_20_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "GLOBALish"
    push $P5002, "EXPORT"
    push $P5002, "$?PACKAGE"
    push $P5002, "::?PACKAGE"
    push $P5002, "$_"
    push $P5002, "$/"
    push $P5002, "$!"
    push $P5002, "JSON"
    push $P5002, "$=pod"
    push $P5002, "!UNIT_MARKER"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 0
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 1
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 0
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 0
    push $P5003, $P5007
    nqp_get_sc_object $P5008, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 4
    push $P5003, $P5008
    nqp_get_sc_object $P5009, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 6
    push $P5003, $P5009
    nqp_get_sc_object $P5010, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 8
    push $P5003, $P5010
    nqp_get_sc_object $P5011, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 11
    push $P5003, $P5011
    nqp_get_sc_object $P5012, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 132
    push $P5003, $P5012
    nqp_get_sc_object $P5013, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 133
    push $P5003, $P5013
    new $P5014, 'ResizableIntegerArray'
    push $P5014, 0
    push $P5014, 0
    push $P5014, 0
    push $P5014, 0
    push $P5014, 1
    push $P5014, 1
    push $P5014, 1
    push $P5014, 0
    push $P5014, 0
    push $P5014, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5014)
    .const "LexInfo" $P5001 = "cuid_19_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$?PACKAGE"
    push $P5002, "::?PACKAGE"
    push $P5002, "$?CLASS"
    push $P5002, "::?CLASS"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 10
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 10
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 10
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 10
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 0
    push $P5008, 0
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_1_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 14
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 13
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_2_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 22
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 19
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_3_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 28
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 27
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_4_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 35
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 33
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_5_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 43
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 40
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_6_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 49
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 48
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_7_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 54
    push $P5003, $P5005
    new $P5006, 'ResizableIntegerArray'
    push $P5006, 0
    push $P5006, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5006)
    .const "LexInfo" $P5001 = "cuid_8_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 63
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 59
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_9_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 70
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 68
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_10_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 77
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 75
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_11_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 84
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 82
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_12_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 91
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 89
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_13_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 98
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 96
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_14_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 105
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 103
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_16_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 113
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 110
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_17_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 119
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 118
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .const "LexInfo" $P5001 = "cuid_18_1372180368.15198"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$/"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 125
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 124
    push $P5003, $P5006
    new $P5007, 'ResizableIntegerArray'
    push $P5007, 1
    push $P5007, 0
    push $P5007, 0
    $P5008 = $P5001."setup_static_lexpad"($P5002, $P5003, $P5007)
    .return ($P5008) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_22_1372180368.15198") :anon :lex :outer("cuid_23_1372180368.15198")
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
    new $P5001, 'ResizablePMCArray'
    .const 'Sub' $P5002 = "cuid_1_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_2_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_3_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_4_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_5_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_6_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_7_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_8_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_9_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_10_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_11_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_12_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_13_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_14_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_15_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_16_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_17_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_18_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_19_1372180368.15198" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_20_1372180368.15198" 
    push $P5001, $P5002
    .return ($P5001) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_24_1372180368.15198") :load
.annotate 'file', "lib/JSON/Tiny/Grammar.pm"
    .const 'Sub' $P5001 = "cuid_21_1372180368.15198" 
    $P5002 = $P5001()
    .return ($P5002) 
.end