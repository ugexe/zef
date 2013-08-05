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
.sub "" :subid("cuid_15_1372180369.18807") :anon :lex
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 1
    .param pmc __args__ :slurpy 
    .const 'Sub' $P5003 = 'cuid_14_1372180369.18807' 
    capture_lex $P5003 
    .const 'Sub' $P5001 = 'cuid_14_1372180369.18807' 
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
.sub "" :subid("cuid_14_1372180369.18807") :anon :lex :outer("cuid_15_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 1
    .const 'Sub' $P5002 = 'cuid_13_1372180369.18807' 
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
    nqp_get_sc_object $P5001, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 120
    .const 'Sub' $P5002 = 'cuid_13_1372180369.18807' 
    capture_lex $P5002
    $P5003 = $P5002()
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 9
    .return ($P5004) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_13_1372180369.18807") :anon :lex :outer("cuid_14_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 16
    .const 'Sub' $P5014 = 'cuid_1_1372180369.18807' 
    capture_lex $P5014 
    .const 'Sub' $P5014 = 'cuid_2_1372180369.18807' 
    capture_lex $P5014 
    .const 'Sub' $P5014 = 'cuid_3_1372180369.18807' 
    capture_lex $P5014 
    .const 'Sub' $P5014 = 'cuid_6_1372180369.18807' 
    capture_lex $P5014 
    .const 'Sub' $P5014 = 'cuid_7_1372180369.18807' 
    capture_lex $P5014 
    .const 'Sub' $P5014 = 'cuid_9_1372180369.18807' 
    capture_lex $P5014 
    .const 'Sub' $P5014 = 'cuid_10_1372180369.18807' 
    capture_lex $P5014 
    .const 'Sub' $P5014 = 'cuid_11_1372180369.18807' 
    capture_lex $P5014 
    .const 'Sub' $P5014 = 'cuid_12_1372180369.18807' 
    capture_lex $P5014 
    .lex "$?PACKAGE", $P101 
    .lex "::?PACKAGE", $P102 
    .lex "$_", $P103 
    .lex "&to-json", $P104 
    .lex "&from-json", $P105 
    nqp_getlexouter $P5001, "$_"
    set $P103, $P5001
    .const 'Sub' $P5002 = 'cuid_1_1372180369.18807' 
    capture_lex $P5002
    $P5002 = $P104."clone"()
    perl6_capture_lex $P5002
    set $P104, $P5002
    .const 'Sub' $P5003 = 'cuid_2_1372180369.18807' 
    capture_lex $P5003
    .const 'Sub' $P5003 = 'cuid_3_1372180369.18807' 
    capture_lex $P5003
    .const 'Sub' $P5003 = 'cuid_6_1372180369.18807' 
    capture_lex $P5003
    .const 'Sub' $P5003 = 'cuid_7_1372180369.18807' 
    capture_lex $P5003
    .const 'Sub' $P5003 = 'cuid_9_1372180369.18807' 
    capture_lex $P5003
    .const 'Sub' $P5003 = 'cuid_10_1372180369.18807' 
    capture_lex $P5003
    .const 'Sub' $P5003 = 'cuid_11_1372180369.18807' 
    capture_lex $P5003
    .const 'Sub' $P5003 = 'cuid_12_1372180369.18807' 
    capture_lex $P5003
    $P5003 = $P105."clone"()
    perl6_capture_lex $P5003
    set $P105, $P5003
.annotate 'line', 18
    null $P5004
    null $P5005
    null $P5006
    null $P5007
    null $P5008
    null $P5009
    null $P5010
    null $P5011
    nqp_get_sc_object $P5012, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 106
    $P5013 = $P5012."clone"()
    perl6_capture_lex $P5013
    .return ($P5013) 
.end
.HLL "perl6"
.namespace []
.sub "to-json" :subid("cuid_1_1372180369.18807") :anon :lex :outer("cuid_13_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 21
    .param pmc CALL_SIG :call_sig 
    .lex "$_", $P101 
    .lex "$/", $P102 
    .lex "$!", $P103 
    .lex "call_sig", $P104 
    .lex "$*DISPATCHER", $P105 
    .lex "&?ROUTINE", $P106 
    set $P5001, CALL_SIG
    set $P104, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    getinterp $P5007
    set $P5007, $P5007['sub']
    get_sub_code_object $P5006, $P5007
    nqp_get_sc_object $P5008, "B9A1DB43DA676D1F1261647412D906DA1B244D1A-1372102072.12878", 26
    repr_get_attr_obj $P5009, $P5006, $P5008, "$!dispatch_cache"
    getinterp $P5010
    set $P5010, $P5010['context']
    multi_cache_find $P5005, $P5009, $P5010
    unless_null $P5005, vivi_1214
    getinterp $P5012
    set $P5012, $P5012['sub']
    get_sub_code_object $P5011, $P5012
    getinterp $P5013
    set $P5013, $P5013['context']
    $P5014 = $P5011."find_best_dispatchee"($P5013)
    set $P5005, $P5014
  vivi_1214:
    getinterp $P5015
    set $P5015, $P5015['context']
    deconstruct_capture $P5015, $P5002, $P5003
    $P5004 = $P5005($P5002 :flat, $P5003 :flat :named)
    .return ($P5004) 
.end
.HLL "perl6"
.namespace []
.sub "to-json" :subid("cuid_2_1372180369.18807") :anon :lex :outer("cuid_13_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 23
    .param pmc CALL_SIG :call_sig 
    .lex "$d", $P101 
    .lex "$_", $P102 
    .lex "$/", $P103 
    .lex "$!", $P104 
    .lex "call_sig", $P105 
    .lex "$*DISPATCHER", $P106 
    .lex "&?ROUTINE", $P107 
    set $P5001, CALL_SIG
    set $P105, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P108, ['parrot';'Continuation']
    set_label $P108, lexotic_15
    .lex "RETURN", $P108
    $P5003 = "&prefix:<~>"($P101)
    perl6_decontainerize_return_value $P5002, $P5003
    goto lexotic_16
  lexotic_15:
    .get_results ($P5002)
  lexotic_16:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 17
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "to-json" :subid("cuid_3_1372180369.18807") :anon :lex :outer("cuid_13_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 24
    .param pmc CALL_SIG :call_sig 
    .lex "$d", $P101 
    .lex "$_", $P102 
    .lex "$/", $P103 
    .lex "$!", $P104 
    .lex "call_sig", $P105 
    .lex "$*DISPATCHER", $P106 
    .lex "&?ROUTINE", $P107 
    set $P5001, CALL_SIG
    set $P105, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P108, ['parrot';'Continuation']
    set_label $P108, lexotic_17
    .lex "RETURN", $P108
    unless $P101 goto if13_else19 
    nqp_get_sc_object $P5003, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 30
    set $P5005, $P5003
    goto if13_end20
  if13_else19:
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 31
    set $P5005, $P5004
  if13_end20:
    perl6_decontainerize_return_value $P5002, $P5005
    goto lexotic_18
  lexotic_17:
    .get_results ($P5002)
  lexotic_18:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 25
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "to-json" :subid("cuid_6_1372180369.18807") :anon :lex :outer("cuid_13_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 25
    .param pmc CALL_SIG :call_sig 
    .const 'Sub' $P5007 = 'cuid_4_1372180369.18807' 
    capture_lex $P5007 
    .const 'Sub' $P5007 = 'cuid_5_1372180369.18807' 
    capture_lex $P5007 
    .lex "$d", $P101 
    .lex "$_", $P102 
    .lex "$/", $P103 
    .lex "$!", $P104 
    .lex "call_sig", $P105 
    .lex "$*DISPATCHER", $P106 
    .lex "&?ROUTINE", $P107 
    .const 'Sub' $P5001 = 'cuid_4_1372180369.18807' 
    capture_lex $P5001
    .const 'Sub' $P5002 = 'cuid_5_1372180369.18807' 
    capture_lex $P5002
    set $P5003, CALL_SIG
    set $P105, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P108, ['parrot';'Continuation']
    set_label $P108, lexotic_31
    .lex "RETURN", $P108
.annotate 'line', 30
.annotate 'line', 27
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 39
.annotate 'line', 29
.annotate 'line', 27
.annotate 'line', 28
.annotate 'line', 27
    nqp_get_sc_object $P5008, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 123
    $P5009 = "&circumfix:<[ ]>"($P5008)
.annotate 'line', 28
    nqp_get_sc_object $P5010, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 124
    $P5011 = "&circumfix:<[ ]>"($P5010)
    $P5012 = "&infix:<=>>"($P5009, $P5011)
    $P5013 = $P101."trans"($P5012)
    nqp_hllize $P5007, $P5013
    nqp_get_sc_object $P5014, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 53
    $P5015 = $P5014."clone"()
    perl6_capture_lex $P5015
    nqp_get_sc_object $P5016, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 58
    $P5017 = $P5016."clone"()
    perl6_capture_lex $P5017
    perl6_booleanize $P5018, 1
    $P5019 = $P5007."subst"($P5015, $P5017, $P5018 :named("g"))
    nqp_hllize $P5006, $P5019
    $P5020 = "&infix:<~>"($P5005, $P5006)
    nqp_get_sc_object $P5021, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 39
    $P5022 = "&infix:<~>"($P5020, $P5021)
    perl6_decontainerize_return_value $P5004, $P5022
    goto lexotic_32
  lexotic_31:
    .get_results ($P5004)
  lexotic_32:
    find_lex $P5005, "&EXHAUST"
    store_lex "RETURN", $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 34
    perl6_type_check_return_value $P5004, $P5006
    .return ($P5004) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_4_1372180369.18807") :anon :lex :outer("cuid_6_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 29
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex utf8:"$\x{a2}", $P103 
    .lex "$?REGEX", $P104 
    .lex "call_sig", $P105 
    .lex "$*DISPATCHER", $P106 
    .local pmc self 
    getinterp $P5002
    set $P5002, $P5002['sub']
    get_sub_code_object $P5001, $P5002
    set $P104, $P5001
    set $P5003, CALL_SIG
    set $P105, $P5003
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    set self, $P101
    .local pmc rx14_start
    .local string rx14_tgt
    .local int rx14_pos
    .local int rx14_off
    .local int rx14_eos
    .local int rx14_rep
    .local pmc rx14_cur
    .local pmc rx14_curclass
    .local pmc rx14_bstack
    .local pmc rx14_cstack
    rx14_start = self."!cursor_start_all"()
    set rx14_cur, rx14_start[0]
    set rx14_tgt, rx14_start[1]
    set rx14_pos, rx14_start[2]
    set rx14_curclass, rx14_start[3]
    set rx14_bstack, rx14_start[4]
    set $I19, rx14_start[5]
    store_lex unicode:"$\x{a2}", rx14_cur
    length rx14_eos, rx14_tgt
    eq $I19, 1, rx14_restart23
    gt rx14_pos, rx14_eos, rx14_fail24
    repr_get_attr_int $I11, self, rx14_curclass, "$!from"
    ne $I11, -1, rxscan15_done30
    goto rxscan15_scan29
  rxscan15_loop28:
    inc rx14_pos
    gt rx14_pos, rx14_eos, rx14_fail24
    repr_bind_attr_int rx14_cur, rx14_curclass, "$!from", rx14_pos
  rxscan15_scan29:
    nqp_rxmark rx14_bstack, rxscan15_loop28, rx14_pos, 0
  rxscan15_done30:
    ge rx14_pos, rx14_eos, rx14_fail24
    substr $S11, rx14_tgt, rx14_pos, 1
    index $I11, ucs4:" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~", $S11
    ge $I11, 0, rx14_fail24
    inc rx14_pos
    rx14_cur."!cursor_pass"(rx14_pos, 'backtrack'=>1)
    .return (rx14_cur)
  rx14_restart23:
    repr_get_attr_obj rx14_cstack, rx14_cur, rx14_curclass, "$!cstack"
  rx14_fail24:
    unless rx14_bstack, rx14_done22
    pop $I19, rx14_bstack
    if_null rx14_cstack, rx14_cstack_done27
    unless rx14_cstack, rx14_cstack_done27
    dec $I19
    set $P11, rx14_cstack[$I19]
  rx14_cstack_done27:
    pop rx14_rep, rx14_bstack
    pop rx14_pos, rx14_bstack
    pop $I19, rx14_bstack
    lt rx14_pos, -1, rx14_done22
    lt rx14_pos, 0, rx14_fail24
    eq $I19, 0, rx14_fail24
    nqp_islist $I20, rx14_cstack
    unless $I20, rx14_jump25
    elements $I18, rx14_bstack
    le $I18, 0, rx14_cut26
    dec $I18
    set $I18, rx14_bstack[$I18]
  rx14_cut26:
    assign rx14_cstack, $I18
  rx14_jump25:
    jump $I19
  rx14_done22:
    rx14_cur."!cursor_fail"()
    .return (rx14_cur) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_5_1372180369.18807") :anon :lex :outer("cuid_6_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 29
    .param pmc CALL_SIG :call_sig 
    .lex "$_", $P101 
    .lex "call_sig", $P102 
    .lex "$*DISPATCHER", $P103 
    set $P5001, CALL_SIG
    set $P102, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    $P5003 = "&prefix:<~>"($P101)
    $P5004 = "&ord"($P5003)
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 59
    $P5006 = $P5004."fmt"($P5005)
    nqp_hllize $P5002, $P5006
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "to-json" :subid("cuid_7_1372180369.18807") :anon :lex :outer("cuid_13_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 32
    .param pmc CALL_SIG :call_sig 
    .lex "$d", $P101 
    .lex "$_", $P102 
    .lex "$/", $P103 
    .lex "$!", $P104 
    .lex "call_sig", $P105 
    .lex "$*DISPATCHER", $P106 
    .lex "&?ROUTINE", $P107 
    set $P5001, CALL_SIG
    set $P105, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P108, ['parrot';'Continuation']
    set_label $P108, lexotic_33
    .lex "RETURN", $P108
.annotate 'line', 33
.annotate 'line', 35
.annotate 'line', 34
    nqp_get_sc_object $P5003, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 71
    find_lex $P5006, "&to-json"
    unless_null $P5006, vivi_1635
    find_lex $P5007, "Nil"
    set $P5006, $P5007
  vivi_1635:
    $P5008 = $P101."map"($P5006)
    nqp_hllize $P5005, $P5008
    nqp_get_sc_object $P5009, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 72
    $P5010 = $P5005."join"($P5009)
    nqp_hllize $P5004, $P5010
    $P5011 = "&infix:<~>"($P5003, $P5004)
    nqp_get_sc_object $P5012, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 73
    $P5013 = "&infix:<~>"($P5011, $P5012)
    $P5014 = "&return"($P5013)
    perl6_decontainerize_return_value $P5002, $P5014
    goto lexotic_34
  lexotic_33:
    .get_results ($P5002)
  lexotic_34:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 66
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "to-json" :subid("cuid_9_1372180369.18807") :anon :lex :outer("cuid_13_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 37
    .param pmc CALL_SIG :call_sig 
    .const 'Sub' $P5006 = 'cuid_8_1372180369.18807' 
    capture_lex $P5006 
    .lex "$d", $P101 
    .lex "$_", $P102 
    .lex "$/", $P103 
    .lex "$!", $P104 
    .lex "call_sig", $P105 
    .lex "$*DISPATCHER", $P106 
    .lex "&?ROUTINE", $P107 
    .const 'Sub' $P5001 = 'cuid_8_1372180369.18807' 
    capture_lex $P5001
    set $P5002, CALL_SIG
    set $P105, $P5002
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P108, ['parrot';'Continuation']
    set_label $P108, lexotic_36
    .lex "RETURN", $P108
.annotate 'line', 38
.annotate 'line', 40
.annotate 'line', 39
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 81
    nqp_get_sc_object $P5007, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 82
    $P5008 = $P5007."clone"()
    perl6_capture_lex $P5008
    $P5009 = $P101."map"($P5008)
    nqp_hllize $P5006, $P5009
    nqp_get_sc_object $P5010, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 72
    $P5011 = $P5006."join"($P5010)
    nqp_hllize $P5005, $P5011
    $P5012 = "&infix:<~>"($P5004, $P5005)
    nqp_get_sc_object $P5013, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 87
    $P5014 = "&infix:<~>"($P5012, $P5013)
    $P5015 = "&return"($P5014)
    perl6_decontainerize_return_value $P5003, $P5015
    goto lexotic_37
  lexotic_36:
    .get_results ($P5003)
  lexotic_37:
    find_lex $P5004, "&EXHAUST"
    store_lex "RETURN", $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 76
    perl6_type_check_return_value $P5003, $P5005
    .return ($P5003) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_8_1372180369.18807") :anon :lex :outer("cuid_9_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 39
    .param pmc CALL_SIG :call_sig 
    .lex "$_", $P101 
    .lex "call_sig", $P102 
    .lex "$*DISPATCHER", $P103 
    set $P5001, CALL_SIG
    set $P102, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    $P5003 = $P101."key"()
    nqp_hllize $P5002, $P5003
    $P5004 = "&to-json"($P5002)
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 83
    $P5006 = "&infix:<~>"($P5004, $P5005)
    $P5008 = $P101."value"()
    nqp_hllize $P5007, $P5008
    $P5009 = "&to-json"($P5007)
    $P5010 = "&infix:<~>"($P5006, $P5009)
    .return ($P5010) 
.end
.HLL "perl6"
.namespace []
.sub "to-json" :subid("cuid_10_1372180369.18807") :anon :lex :outer("cuid_13_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 43
    .param pmc CALL_SIG :call_sig 
    .lex "$_", $P101 
    .lex "$/", $P102 
    .lex "$!", $P103 
    .lex "call_sig", $P104 
    .lex "$*DISPATCHER", $P105 
    .lex "&?ROUTINE", $P106 
    set $P5001, CALL_SIG
    set $P104, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    nqp_get_sc_object $P5003, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 95
    perl6_decontainerize_return_value $P5002, $P5003
    nqp_get_sc_object $P5003, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 90
    perl6_type_check_return_value $P5002, $P5003
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "to-json" :subid("cuid_11_1372180369.18807") :anon :lex :outer("cuid_13_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 44
    .param pmc CALL_SIG :call_sig 
    .lex "$s", $P101 
    .lex "$_", $P102 
    .lex "$/", $P103 
    .lex "$!", $P104 
    .lex "call_sig", $P105 
    .lex "$*DISPATCHER", $P106 
    .lex "&?ROUTINE", $P107 
    set $P5001, CALL_SIG
    set $P105, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P108, ['parrot';'Continuation']
    set_label $P108, lexotic_38
    .lex "RETURN", $P108
.annotate 'line', 45
    nqp_get_sc_object $P5003, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 103
    get_what $P5005, $P101
    $P5006 = $P5005."perl"()
    nqp_hllize $P5004, $P5006
    $P5007 = "&infix:<~>"($P5003, $P5004)
    $P5008 = "&die"($P5007)
    perl6_decontainerize_return_value $P5002, $P5008
    goto lexotic_39
  lexotic_38:
    .get_results ($P5002)
  lexotic_39:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 98
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "from-json" :subid("cuid_12_1372180369.18807") :anon :lex :outer("cuid_13_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
.annotate 'line', 48
    .param pmc CALL_SIG :call_sig 
    .lex "$text", $P101 
    .lex "$_", $P102 
    .lex "$/", $P103 
    .lex "$!", $P104 
    .lex "$a", $P105 
    .lex "$o", $P106 
    .lex "call_sig", $P107 
    .lex "$*DISPATCHER", $P108 
    .lex "&?ROUTINE", $P109 
    set $P5001, CALL_SIG
    set $P107, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P110, ['parrot';'Continuation']
    set_label $P110, lexotic_40
    .lex "RETURN", $P110
.annotate 'line', 49

    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 9
    $P5005 = $P5004."new"()
    nqp_hllize $P5003, $P5005
    perl6_container_store $P105, $P5003
.annotate 'line', 50

    nqp_get_sc_object $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E", 10
    $P5005 = $P5004."parse"($P101, $P105 :named("actions"))
    nqp_hllize $P5003, $P5005
    perl6_container_store $P106, $P5003
.annotate 'line', 51
    $P5004 = $P106."ast"()
    nqp_hllize $P5003, $P5004
    $P5005 = "&return"($P5003)
    perl6_decontainerize_return_value $P5002, $P5005
    goto lexotic_41
  lexotic_40:
    .get_results ($P5002)
  lexotic_41:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 106
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_17_1372180369.18807") :load :init
.annotate 'file', "lib/JSON/Tiny.pm"
    .const 'Sub' $P5001 = 'cuid_16_1372180369.18807' 
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
    .const 'Sub' $P5001 = "cuid_15_1372180369.18807" 
    get_hll_global $P5002, "ModuleLoader"
    $P5003 = $P5002."load_setting"("CORE")
    $P5004 = $P5001."set_outer_ctx"($P5003)
    load_bytecode "ModuleLoader.pbc"
    new $P5002, 'ResizableStringArray'
    push $P5002, "nqp"
    get_root_global $P5001, $P5002, "ModuleLoader"
    $P5001."load_module"("Perl6::ModuleLoader")
    get_hll_global $P5001, "ModuleLoader"
    $P5001."load_module"("JSON::Tiny::Actions", 18 :named("line"))
    load_bytecode "ModuleLoader.pbc"
    new $P5002, 'ResizableStringArray'
    push $P5002, "nqp"
    get_root_global $P5001, $P5002, "ModuleLoader"
    $P5001."load_module"("Perl6::ModuleLoader")
    get_hll_global $P5001, "ModuleLoader"
    $P5001."load_module"("JSON::Tiny::Grammar", 19 :named("line"))
    nqp_create_sc $P5001, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D"
    set cur_sc, $P5001
    $P5002 = cur_sc."set_description"("lib/JSON/Tiny.pm")
    new $P5003, 'ResizablePMCArray'
    set conflicts, $P5003
    new $P5004, 'ResizableStringArray'
    null $S5001
    push $P5004, $S5001
    push $P5004, "Uninstantiable"
    push $P5004, "34AEF0B7DBE5E000126E01B596D8807B78596907"
    push $P5004, "src/gen/CORE.setting"
    push $P5004, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613"
    push $P5004, "src/gen/Metamodel.nqp"
    push $P5004, "B9A1DB43DA676D1F1261647412D906DA1B244D1A-1372102072.12878"
    push $P5004, "src/gen/BOOTSTRAP.nqp"
    push $P5004, "$_"
    push $P5004, "$/"
    push $P5004, "$!"
    push $P5004, "D"
    push $P5004, "$d"
    push $P5004, "true"
    push $P5004, "false"
    push $P5004, "\""
    push $P5004, "\\"
    push $P5004, "\b"
    push $P5004, "\f"
    push $P5004, "\n"
    push $P5004, "\r"
    push $P5004, "\t"
    push $P5004, "\\\""
    push $P5004, "\\\\"
    push $P5004, "\\b"
    push $P5004, "\\f"
    push $P5004, "\\n"
    push $P5004, "\\r"
    push $P5004, "\\t"
    push $P5004, ""
    push $P5004, " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
    push $P5004, "%_"
    push $P5004, unicode:"\\u%04x"
    push $P5004, "g"
    push $P5004, "[ "
    push $P5004, ", "
    push $P5004, " ]"
    push $P5004, "{ "
    push $P5004, " : "
    push $P5004, " }"
    push $P5004, "U"
    push $P5004, "null"
    push $P5004, "$s"
    push $P5004, "Can't serialize an object of type "
    push $P5004, "$a"
    push $P5004, "$o"
    push $P5004, "actions"
    push $P5004, "$text"
    push $P5004, "GLOBAL"
    push $P5004, "JSON"
    push $P5004, "EXPORT"
    push $P5004, "ALL"
    push $P5004, "DEFAULT"
    push $P5004, "JSON::Tiny"
    push $P5004, "Actions"
    push $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10"
    push $P5004, "lib/JSON/Tiny/Actions.pm"
    push $P5004, "Grammar"
    push $P5004, "744F584B7B2AFF7F046570ACF6227BF42A7DA49E"
    push $P5004, "lib/JSON/Tiny/Grammar.pm"
    push $P5004, "Tiny"
    push $P5004, "!UNIT_MARKER"
    push $P5004, "EE42FAAE005FFBB476E24FE506FBB030624E6073-1372101919.29754"
    push $P5004, "src/stage2/QASTNode.nqp"
    push $P5004, "7A67D46DDEA3C60BB73DFB1CA4F76715F3D1212C-1372101917.20204"
    push $P5004, "src/stage2/NQPCORE.setting"
    push $P5004, "p6typecheckrv"
    push $P5004, "p6decontrv"
    push $P5004, "&to-json"
    push $P5004, "&from-json"
    push $P5004, "Ss"
    .const 'Sub' $P5005 = 'cuid_16_1372180369.18807' 
    capture_lex $P5005
    $P5006 = $P5005()
    nqp_deserialize_sc "BQAAAEAAAAAHAAAAeAAAAAoAAADwAAAA6AMAAKMAAAAYDgAAbB8AAAAAAABsHwAAAAAAAGwfAABsHwAAAAAAAAIAAAADAAAABAAAAAUAAAAGAAAABwAAADcAAAA4AAAAOgAAADsAAAA+AAAAPwAAAEAAAABBAAAAAQAAAAAAAABMAAAAAQAAAEwAAACYAAAAAQAAAJgAAADkAAAAAQAAAOQAAAAwAQAAAQAAADABAAB8AQAAAQAAAHwBAADIAQAAAQAAAMgBAAAUAgAAAQAAABQCAABgAgAAAQAAAGACAACsAgAAAQAAAKwCAAD4AgAAAAAAAH0AAAAAAAAAAAAAAAIAAAAAAH4AAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB/AAAAAAAAAAEAAAACAAAAAACAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgQAAAAAAAAAJAAAAAgAAAAAAggAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIMAAAAAAAAACgAAAAIAAAAAAIQAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACFAAAAAAAAAHkAAAACAAAAAACGAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAjwAAAAAAAACJAAAAAgAAAAAAkAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJEAAAAAAAAAigAAAAIAAAAAAJIAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACTAAAAAAAAAIsAAAACAAAAAACUAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAnQAAAAAAAACYAAAAAgAAAAAAngAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJ8AAAAAAAAAmQAAAAIAAAAAAKAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAGoAAAAAAAAAAQAAAAIAAAAtAAAAGAAAAAEAAAABAAAAaAAAAC4AAAABAAAAAgAAAC0AAABEAAAAAQAAAAEAAABoAAAAWgAAAAEAAAACAAAALQAAAHAAAAABAAAAAQAAAGgAAACGAAAAAQAAAAAAAAACAAAAnAAAAAAAAAAAAAAAAwAAAJwAAAAAAAAAAQAAAHwAAACcAAAAAQAAAAEAAABoAAAALAEAAAEAAAABAAAAaAAAAEIBAAABAAAAAQAAAGgAAABYAQAAAQAAAAEAAADWAAAAbgEAAAEAAAABAAAA1wAAAJgBAAABAAAAAQAAAHwAAAC4AQAAAQAAAAEAAACvAAAABgIAAAEAAAACAAAALQAAAAoCAAABAAAAAQAAAGgAAAAgAgAAAQAAAAEAAABoAAAANgIAAAEAAAABAAAAaAAAAEwCAAABAAAAAQAAANYAAABiAgAAAQAAAAEAAADXAAAAlAIAAAEAAAABAAAAfAAAALQCAAABAAAAAgAAAC0AAAACAwAAAQAAAAEAAABoAAAAGAMAAAEAAAABAAAAaAAAAC4DAAABAAAAAQAAAGgAAABEAwAAAQAAAAEAAACvAAAAWgMAAAEAAAABAAAArwAAAF4DAAABAAAAAQAAANYAAABiAwAAAQAAAAEAAADXAAAAlAMAAAEAAAABAAAAfAAAALQDAAABAAAAAgAAAC0AAAACBAAAAQAAAAEAAABoAAAAGAQAAAEAAAABAAAAaAAAAC4EAAABAAAAAQAAAGgAAABEBAAAAQAAAAEAAACvAAAAWgQAAAEAAAABAAAArwAAAF4EAAABAAAAAQAAAK8AAABiBAAAAQAAAAEAAACvAAAAZgQAAAEAAAABAAAArwAAAGoEAAABAAAAAQAAAK8AAABuBAAAAQAAAAEAAACvAAAAcgQAAAEAAAABAAAArwAAAHYEAAABAAAAAQAAAK8AAAB6BAAAAQAAAAEAAACvAAAAfgQAAAEAAAABAAAArwAAAIIEAAABAAAA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PhEAAAEAAAALAAAAAAANAAAAAgAAAAAAegAAAAMAAQACAAMAAAAQAAAAAQAAAAAAAAAIAAAAAgAAAAAAAwAAAAIAAwAAABEAAAABAAIAAwAAABAAAAABAAAAAAAAAAkAAAACAAAAAAAFAAAAAgADAAAAEQAAAAEAAgADAAAAEAAAAAEAAAAAAAAACgAAAAIAAAAAAAcAAAACAAMAAAARAAAAAQALAAAAAAAAAAAAAgAAAAAAEAAAAAMAAQAHAAcAAAACAAAAAAARAAAAAgAAAAAAGQAAAAIAAAAAACIAAAACAAAAAABCAAAAAgAAAAAATAAAAAIAAAAAAFoAAAACAAAAAABiAAAAAwABAAAAAAAAAAAAAQAAAAAAAAAAAAIAAAAAAAkAAAABAAAAAAAAAAMAAwACAAAAAAADAAAAAgADAAAAEQAAAAEAAgAAAAAABQAAAAIAAwAAABEAAAABAAIAAAAAAAcAAAACAAMAAAARAAAAAQAAAAAAAQABAIAAAAAAAAAAAgADAAAAEQAAAAEAAQAAAAAAAQABAAEAAQAHAAEAAAACAAAAAAAPAAAAAQABAAEAAgAAAAAACwAAAAsAAAAAAAEAAAACAAAAAAAYAAAAAwABAAEAAQACAAAAAAALAAAAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACQAAAAAAAAAAAAAAAQABAAsAAAACAAEAAAD1IwAAAAAAAAAAAAAMAAAAAgAAAAAAAwAAAAIAAwAAABEAAAABAAIAAAAAAAUAAAACAAMAAAARAAAAAQACAAAAAAAHAAAAAgADAAAAEQAAAAEADAAAAAEAAQCAAAIAAAAAAAIAAQAAAPUjAAABAAEAAAAAAAEAAQACAAAAAAATAAAAAQAHAAEAAAACAAAAAAAXAAAAAQABAAEAAgAAAAAAEQAAAAsAAAAAAAIAAAACAAAAAAAhAAAAAwABAAEAAQACAAAAAAALAAAAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACQAAAAAAAAAAAAAAAQABAAIAAwAAAC0AAAAAAAAAAAAAAAwAAAACAAAAAAADAAAAAgADAAAAEQAAAAEAAgAAAAAABQAAAAIAAwAAABEAAAABAAIAAAAAAAcAAAACAAMAAAARAAAAAQANAAAADgAAAAwAAAABAAEAgAACAAAAAAACAAMAAAAtAAAAAQABAAAAAAABAAEAAgAAAAAAGgAAAAEABwABAAAAAgAAAAAAIAAAAAEAAQABAAIAAAAAABkAAAALAAAAAAAFAAAAAgAAAAAAQQAAAAMAAQABAAEAAgAAAAAACwAAAAAAAAAAAAAAAQAAAAAAAAAAAAIAAAAAAAkAAAAAAAAAAAAAAAEAAQACAAMAAAAfAAAAAAAAAAAAAAAMAAAAAgAAAAAAAwAAAAIAAwAAABEAAAABAAIAAAAAAAUAAAACAAMAAAARAAAAAQACAAAAAAAHAAAAAgADAAAAEQAAAAEADwAAABAAAAARAAAAEgAAABMAAAAUAAAAFQAAABYAAAAXAAAAGAAAABkAAAAaAAAAGwAAABwAAAALAAAAAAADAAAAAgAAAAAAOQAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAJAAAAAAAAAAAAAAABAAEACgABAAAAHQAAAAQAAAAAAAAAAAAHAAIAAAAHAAAAAAAHAAMAAAAFAAAAAAAAABxABgAeAAAABAAAAAAAAAAAAAEAAAAAAAEAAQDAAAAAAAAAAAIAAwAAABAAAAABAAEAAAAAAAEAAQABAAEAAgADAAAAEAAAAAAAAAAAAAAAHwAAAB8AAAABAAEAkAAAAAAAAAACAAMAAAAQAAAAAQABAAAAAAABAAEAAgAAAAAANwAAAAEABwACAAAAAgAAAAAANgAAAAIAAAAAADgAAAABAAEAAQACAAAAAAA1AAAACwAAAAAABAAAAAIAAAAAAD4AAAADAAEAIAAAAAIAAwAAABAAAAAAAAAAAAAAAAgAAAAIAAAAAQABAABMAAAAAAAAAgADAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAADwAAAABAAcAAQAAAAIAAAAAAD0AAAABAAEAAQACAAAAAAA6AAAAIQAAAAwAAAABAAEAgAACAAAAAAACAAMAAAAfAAAAAQABAAAAAAABAAEAAgAAAAAAIwAAAAEABwABAAAAAgAAAAAAQAAAAAEAAQABAAIAAAAAACIAAAALAAAAAAAGAAAAAgAAAAAASwAAAAMAAQABAAEAAgAAAAAACwAAAAAAAAAAAAAAAQAAAAAAAAAAAAIAAAAAAAkAAAAAAAAAAAAAAAEAAQACAAEAAAANAAAAAAAAAAAAAAAMAAAAAgAAAAAAAwAAAAIAAwAAABEAAAABAAIAAAAAAAUAAAACAAMAAAARAAAAAQACAAAAAAAHAAAAAgADAAAAEQAAAAEAIgAAACMAAAAkAAAADAAAAAEAAQCAAAIAAAAAAAIAAQAAAA0AAAABAAEAAAAAAAEAAQACAAAAAABDAAAAAQAHAAEAAAACAAAAAABKAAAAAQABAAEAAgAAAAAAQgAAAAsAAAAAAAgAAAACAAAAAABZAAAAAwABAAEAAQACAAAAAAALAAAAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACQAAAAAAAAAAAAAAAQABAAIAAQAAABEAAAAAAAAAAAAAAAwAAAACAAAAAAADAAAAAgADAAAAEQAAAAEAAgAAAAAABQAAAAIAAwAAABEAAAABAAIAAAAAAAcAAAACAAMAAAARAAAAAQAlAAAACwAAAAAABwAAAAIAAAAAAFYAAAADAAEAJgAAAAIAAwAAABAAAAAAAAAAAAAAAAgAAAAIAAAAAQABAABMAAAAAAAAAgADAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAAFQAAAABAAcAAQAAAAIAAAAAAFUAAAABAAEAAQACAAAAAABSAAAAJwAAAAwAAAABAAEAgAACAAAAAAACAAEAAAARAAAAAQABAAAAAAABAAEAAgAAAAAATQAAAAEABwABAAAAAgAAAAAAWAAAAAEAAQABAAIAAAAAAEwAAAALAAAAAAAJAAAAAgAAAAAAYQAAAAMAAQABAAEAAgAAAAAACwAAAAAAAAAAAAAAAgAAAAAAhwAAAAAAAAAAAAAAAgAAAAAACQAAAAAAAAAAAAAAAQABACgAAAACAAAAAAADAAAAAgADAAAAEQAAAAEAAgAAAAAABQAAAAIAAwAAABEAAAABAAIAAAAAAAcAAAACAAMAAAARAAAAAQApAAAAAAAAAAEAAQCAAAEAAAAAAAIAAwAAABAAAAABAAEAAAAAAAEAAQABAAEABwABAAAAAgAAAAAAYAAAAAEAAQABAAIAAAAAAFoAAAALAAAAAAAKAAAAAgAAAAAAaQAAAAMAAQABAAEAAgAAAAAACwAAAAAAAAAAAAAAAQAAAAAAAAAAAAIAAAAAAAkAAAAAAAAAAAAAAAEAAQACAAMAAAAQAAAAAAAAAAAAAAAqAAAAAgAAAAAAAwAAAAIAAwAAABEAAAABAAIAAAAAAAUAAAACAAMAAAARAAAAAQACAAAAAAAHAAAAAgADAAAAEQAAAAEAKwAAACoAAAABAAEAgAACAAAAAAACAAMAAAAQAAAAAQABAAAAAAABAAEAAgAAAAAAYwAAAAEABwABAAAAAgAAAAAAaAAAAAEAAQABAAIAAAAAAGIAAAALAAAAAAALAAAAAgAAAAAAdQAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAJAAAAAAAAAAAAAAABAAEAAgAAAAAAAwAAAAIAAwAAABEAAAABAAIAAAAAAAUAAAACAAMAAAARAAAAAQACAAAAAAAHAAAAAgADAAAAEQAAAAEAAgADAAAAEAAAAAEAAAAAAAAALAAAAAIAAAAAAG4AAAACAAMAAAARAAAAAQACAAMAAAAQAAAAAQAAAAAAAAAtAAAAAgAAAAAAcAAAAAIAAwAAABEAAAABAC4AAAACAAMAAAARAAAAAAAAAAAAAAAvAAAALwAAAAEAAQCAAAAAAAAAAAIAAwAAABEAAAABAAEAAAAAAAEAAQACAAAAAABzAAAAAQAHAAEAAAACAAAAAAB0AAAAAQABAAEAAgAAAAAAagAAAAcAAAAAAAEAAQABAAIAAAAAAHcAAAALAAAAAAAMAAAAAgAAAAAAdgAAAAMAAQABAAIAAwAAAIMAAAACAAAAAACIAAAAAQAHAAAAAAABAAEAAQACAAAAAAACAAAABwAHAAAAAgAAAAAAJwAAAAIAAAAAACgAAAACAAAAAAApAAAAAgAAAAAAKgAAAAIAAAAAACsAAAACAAAAAAAsAAAAAgAAAAAALQAAAAcABwAAAAIAAAAAAC4AAAACAAAAAAAvAAAAAgAAAAAAMAAAAAIAAAAAADEAAAACAAAAAAAyAAAAAgAAAAAAMwAAAAIAAAAAADQAAAAEAAEAAAAAAAAABgAwAAAAAQAKAAEAAAAxAAAAAgAAAAAACgAAAAEABAABAAAAAAAAAAYAMgAAAAEACgACAAAAMwAAAAIAAAAAAIkAAAA0AAAAAgAAAAAAigAAAAEABAABAAAAAAAAAAYANQAAAAEAAQABAAoAAwAAADYAAAACAAQAAAAJAAAAOQAAAAIABQAAAAoAAAAyAAAAAgAAAAAAiwAAAAEABAABAAAAAAAAAAYAMQAAAAEACgABAAAAPAAAAAIAAAAAAAkAAAABAAQAAQAAAAAAAAAGAD0AAAABAAoAAAAAAAEABwACAAAAAgAAAAAAjAAAAAIAAAAAAI0AAAAKAAAAAAACAAcAAAAaAAAAAQAAAAAAAAAAAAAAAABCAAAAAAAAAAEAAQAHAAAAAAACAAAAAAB4AAAABwABAAAAAgAAAAAAjgAAAAoAAAAAAAIABwAAABoAAAABAAAAAAAAAAAAAAAAAEMAAAAAAAAABwAAAAAACgAAAAAAAgAHAAAAGgAAAAEAAAAAAAAAAAACAAAAAABaAAAABwABAAAAAgAAAAAAlQAAAAoAAAAAAAIABwAAABoAAAACAAMAAAAfAAAAAAAAAAAAAAABAAQAAQAAAAAAAAACAAAAAACWAAAAAQAKAAIAAABEAAAAAgAAAAAACwAAAEUAAAACAAAAAABqAAAAAQAEAAEAAAAAAAAAAgAAAAAAlwAAAAEACgACAAAARAAAAAIAAAAAAAsAAABFAAAAAgAAAAAAagAAAAEABAABAAAAAAAAAAIAAQAAAGkBAAABAAoAAgAAADMAAAACAAAAAACYAAAANAAAAAIAAAAAAJkAAAABAAcAAQAAAAIAAAAAAJoAAAAKAAAAAAACAAcAAAAaAAAAAgADAAAAHwAAAAAAAAAAAAAAAQACAAEAAAB9AQAAAgABAAAAlAEAAAEAAgABAAAAfQEAAAIAAQAAAJUBAAABAAcAAwAAAAIAAAAAAJsAAAAGAEYAAAACAAAAAACcAAAACgAAAAAAAgAHAAAAGgAAAAIAAwAAAB8AAAAAAAAAAAAAAAcAAAAAAAoAAAAAAAIABwAAABoAAAACAAMAAAAfAAAAAAAAAAAAAAACAAAAAABfAAAABwAAAAAACgAAAAAAAgAHAAAAGgAAAAEAAAAAAAAAAAApAAAABAABAAAAAAAAAAIAAAAAAKEAAAABAAoAAgAAAEQAAAACAAAAAAALAAAARQAAAAIAAAAAAGoAAAABAAQAAQAAAAAAAAACAAAAAACiAAAAAQAKAAIAAABEAAAAAgAAAAAACwAAAEUAAAACAAAAAABqAAAAAQACAAEAAAB9AQAAAgABAAAAlAEAAAEAAgABAAAAfQEAAAIAAQAAAJUBAAABAA==", cur_sc, $P5004, $P5006, conflicts
    unless conflicts goto if17_end43 
    get_hll_global $P5007, "ModuleLoader"
    $P5008 = $P5007."resolve_repossession_conflicts"(conflicts)
  if17_end43:
    .const 'Sub' $P5001 = "cuid_1_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 11
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_2_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 17
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_3_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 25
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_4_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 53
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_5_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 58
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_6_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 34
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_7_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 66
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_8_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 82
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_9_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 76
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_10_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 90
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_11_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 98
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_12_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 106
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_13_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 119
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_14_1372180369.18807" 
    nqp_get_sc_object $P5002, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 2
    set_sub_code_object $P5001, $P5002
    nqp_get_sc_object $P5001, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 0
    set_hll_global "GLOBAL", $P5001
    .const "LexInfo" $P5001 = "cuid_14_1372180369.18807"
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
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 0
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 1
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 0
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 0
    push $P5003, $P5007
    nqp_get_sc_object $P5008, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 4
    push $P5003, $P5008
    nqp_get_sc_object $P5009, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 6
    push $P5003, $P5009
    nqp_get_sc_object $P5010, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 8
    push $P5003, $P5010
    nqp_get_sc_object $P5011, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 10
    push $P5003, $P5011
    nqp_get_sc_object $P5012, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 120
    push $P5003, $P5012
    nqp_get_sc_object $P5013, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 121
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
    .const "LexInfo" $P5001 = "cuid_13_1372180369.18807"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$?PACKAGE"
    push $P5002, "::?PACKAGE"
    push $P5002, "&to-json"
    push $P5002, "&from-json"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 9
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 9
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 11
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 106
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 0
    push $P5008, 0
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_1_1372180369.18807"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$/"
    push $P5002, "$!"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 12
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 13
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 14
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 11
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_2_1372180369.18807"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$/"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 20
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 21
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 22
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 312
    push $P5003, $P5007
    nqp_get_sc_object $P5008, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 17
    push $P5003, $P5008
    new $P5009, 'ResizableIntegerArray'
    push $P5009, 1
    push $P5009, 1
    push $P5009, 1
    push $P5009, 0
    push $P5009, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5009)
    .const "LexInfo" $P5001 = "cuid_3_1372180369.18807"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$/"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 27
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 28
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 29
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 312
    push $P5003, $P5007
    nqp_get_sc_object $P5008, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 25
    push $P5003, $P5008
    new $P5009, 'ResizableIntegerArray'
    push $P5009, 1
    push $P5009, 1
    push $P5009, 1
    push $P5009, 0
    push $P5009, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5009)
    .const "LexInfo" $P5001 = "cuid_6_1372180369.18807"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$/"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 36
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 37
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 38
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 312
    push $P5003, $P5007
    nqp_get_sc_object $P5008, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 34
    push $P5003, $P5008
    new $P5009, 'ResizableIntegerArray'
    push $P5009, 1
    push $P5009, 1
    push $P5009, 1
    push $P5009, 0
    push $P5009, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5009)
    .const "LexInfo" $P5001 = "cuid_4_1372180369.18807"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$*DISPATCHER"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5004
    new $P5005, 'ResizableIntegerArray'
    push $P5005, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5005)
    .const "LexInfo" $P5001 = "cuid_7_1372180369.18807"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$/"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 68
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 69
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 70
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 312
    push $P5003, $P5007
    nqp_get_sc_object $P5008, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 66
    push $P5003, $P5008
    new $P5009, 'ResizableIntegerArray'
    push $P5009, 1
    push $P5009, 1
    push $P5009, 1
    push $P5009, 0
    push $P5009, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5009)
    .const "LexInfo" $P5001 = "cuid_9_1372180369.18807"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$/"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 78
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 79
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 80
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 312
    push $P5003, $P5007
    nqp_get_sc_object $P5008, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 76
    push $P5003, $P5008
    new $P5009, 'ResizableIntegerArray'
    push $P5009, 1
    push $P5009, 1
    push $P5009, 1
    push $P5009, 0
    push $P5009, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5009)
    .const "LexInfo" $P5001 = "cuid_10_1372180369.18807"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$/"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 92
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 93
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 94
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 312
    push $P5003, $P5007
    nqp_get_sc_object $P5008, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 90
    push $P5003, $P5008
    new $P5009, 'ResizableIntegerArray'
    push $P5009, 1
    push $P5009, 1
    push $P5009, 1
    push $P5009, 0
    push $P5009, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5009)
    .const "LexInfo" $P5001 = "cuid_11_1372180369.18807"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$/"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 100
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 101
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 102
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 312
    push $P5003, $P5007
    nqp_get_sc_object $P5008, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 98
    push $P5003, $P5008
    new $P5009, 'ResizableIntegerArray'
    push $P5009, 1
    push $P5009, 1
    push $P5009, 1
    push $P5009, 0
    push $P5009, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5009)
    .const "LexInfo" $P5001 = "cuid_12_1372180369.18807"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$/"
    push $P5002, "$!"
    push $P5002, "$a"
    push $P5002, "$o"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 107
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 108
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 109
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 111
    push $P5003, $P5007
    nqp_get_sc_object $P5008, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 113
    push $P5003, $P5008
    nqp_get_sc_object $P5009, "2AACAEE5A8F132DEF185F1B62461689FF6D3909D", 106
    push $P5003, $P5009
    new $P5010, 'ResizableIntegerArray'
    push $P5010, 1
    push $P5010, 1
    push $P5010, 1
    push $P5010, 1
    push $P5010, 1
    push $P5010, 0
    $P5011 = $P5001."setup_static_lexpad"($P5002, $P5003, $P5010)
    .return ($P5011) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_16_1372180369.18807") :anon :lex :outer("cuid_17_1372180369.18807")
.annotate 'file', "lib/JSON/Tiny.pm"
    new $P5001, 'ResizablePMCArray'
    .const 'Sub' $P5002 = "cuid_1_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_2_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_3_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_4_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_5_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_6_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_7_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_8_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_9_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_10_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_11_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_12_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_13_1372180369.18807" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_14_1372180369.18807" 
    push $P5001, $P5002
    .return ($P5001) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_18_1372180369.18807") :load
.annotate 'file', "lib/JSON/Tiny.pm"
    .const 'Sub' $P5001 = "cuid_15_1372180369.18807" 
    $P5002 = $P5001()
    .return ($P5002) 
.end