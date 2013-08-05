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
.sub "" :subid("cuid_22_1372180366.9901") :anon :lex
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 1
    .param pmc __args__ :slurpy 
    .const 'Sub' $P5003 = 'cuid_21_1372180366.9901' 
    capture_lex $P5003 
    .const 'Sub' $P5001 = 'cuid_21_1372180366.9901' 
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
.sub "" :subid("cuid_21_1372180366.9901") :anon :lex :outer("cuid_22_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 1
    .const 'Sub' $P5002 = 'cuid_20_1372180366.9901' 
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
    nqp_get_sc_object $P5001, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 200
    .const 'Sub' $P5002 = 'cuid_20_1372180366.9901' 
    capture_lex $P5002
    $P5003 = $P5002()
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 9
    .return ($P5004) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_20_1372180366.9901") :anon :lex :outer("cuid_21_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 1
    .const 'Sub' $P5035 = 'cuid_1_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_2_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_3_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_4_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_5_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_6_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_8_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_9_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_10_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_11_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_12_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_13_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_14_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_15_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_16_1372180366.9901' 
    capture_lex $P5035 
    .const 'Sub' $P5035 = 'cuid_19_1372180366.9901' 
    capture_lex $P5035 
    .lex "$?PACKAGE", $P101 
    .lex "::?PACKAGE", $P102 
    .lex "$?CLASS", $P103 
    .lex "::?CLASS", $P104 
    .lex "$_", $P105 
    nqp_getlexouter $P5001, "$_"
    set $P105, $P5001
    .const 'Sub' $P5002 = 'cuid_1_1372180366.9901' 
    capture_lex $P5002
    .const 'Sub' $P5003 = 'cuid_2_1372180366.9901' 
    capture_lex $P5003
    .const 'Sub' $P5004 = 'cuid_3_1372180366.9901' 
    capture_lex $P5004
    .const 'Sub' $P5005 = 'cuid_4_1372180366.9901' 
    capture_lex $P5005
    .const 'Sub' $P5006 = 'cuid_5_1372180366.9901' 
    capture_lex $P5006
    .const 'Sub' $P5007 = 'cuid_6_1372180366.9901' 
    capture_lex $P5007
    .const 'Sub' $P5008 = 'cuid_8_1372180366.9901' 
    capture_lex $P5008
    .const 'Sub' $P5009 = 'cuid_9_1372180366.9901' 
    capture_lex $P5009
    .const 'Sub' $P5010 = 'cuid_10_1372180366.9901' 
    capture_lex $P5010
    .const 'Sub' $P5011 = 'cuid_11_1372180366.9901' 
    capture_lex $P5011
    .const 'Sub' $P5012 = 'cuid_12_1372180366.9901' 
    capture_lex $P5012
    .const 'Sub' $P5013 = 'cuid_13_1372180366.9901' 
    capture_lex $P5013
    .const 'Sub' $P5014 = 'cuid_14_1372180366.9901' 
    capture_lex $P5014
    .const 'Sub' $P5015 = 'cuid_15_1372180366.9901' 
    capture_lex $P5015
    .const 'Sub' $P5016 = 'cuid_16_1372180366.9901' 
    capture_lex $P5016
    .const 'Sub' $P5017 = 'cuid_19_1372180366.9901' 
    capture_lex $P5017
.annotate 'line', 3
    null $P5018
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
    nqp_get_sc_object $P5033, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 168
    $P5034 = $P5033."clone"()
    perl6_capture_lex $P5034
    .return ($P5034) 
.end
.HLL "perl6"
.namespace []
.sub "TOP" :subid("cuid_1_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 3
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_14
    .lex "RETURN", $P109
.annotate 'line', 4
    $P5006 = $P103."values"()
    nqp_hllize $P5005, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 15
    $P5008 = $P5005."postcircumfix:<[ ]>"($P5007)
    nqp_hllize $P5004, $P5008
    $P5009 = $P5004."ast"()
    nqp_hllize $P5003, $P5009
    $P5010 = "&make"($P5003)
    perl6_decontainerize_return_value $P5002, $P5010
    goto lexotic_15
  lexotic_14:
    .get_results ($P5002)
  lexotic_15:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 12
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "object" :subid("cuid_2_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 6
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_16
    .lex "RETURN", $P109
.annotate 'line', 7
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 25
    $P5006 = $P103."postcircumfix:<{ }>"($P5005)
    $P5007 = $P5006."ast"()
    nqp_hllize $P5004, $P5007
    $P5008 = $P5004."hash"()
    nqp_hllize $P5003, $P5008
    $P5009 = "&make"($P5003)
    perl6_decontainerize_return_value $P5002, $P5009
    goto lexotic_17
  lexotic_16:
    .get_results ($P5002)
  lexotic_17:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 22
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "pairlist" :subid("cuid_3_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 10
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_18
    .lex "RETURN", $P109
.annotate 'line', 11
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 35
    $P5006 = $P103."postcircumfix:<{ }>"($P5005)
    $P5007 = $P5006."dispatch:<hyper>"("ast")
    nqp_hllize $P5004, $P5007
    $P5008 = $P5004."flat"()
    nqp_hllize $P5003, $P5008
    $P5009 = "&make"($P5003)
    perl6_decontainerize_return_value $P5002, $P5009
    goto lexotic_19
  lexotic_18:
    .get_results ($P5002)
  lexotic_19:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 32
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "pair" :subid("cuid_4_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 14
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_20
    .lex "RETURN", $P109
.annotate 'line', 15
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 45
    $P5005 = $P103."postcircumfix:<{ }>"($P5004)
    $P5006 = $P5005."ast"()
    nqp_hllize $P5003, $P5006
    nqp_get_sc_object $P5008, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 46
    $P5009 = $P103."postcircumfix:<{ }>"($P5008)
    $P5010 = $P5009."ast"()
    nqp_hllize $P5007, $P5010
    $P5011 = "&infix:<=>>"($P5003, $P5007)
    $P5012 = "&make"($P5011)
    perl6_decontainerize_return_value $P5002, $P5012
    goto lexotic_21
  lexotic_20:
    .get_results ($P5002)
  lexotic_21:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 42
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "array" :subid("cuid_5_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 18
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_22
    .lex "RETURN", $P109
.annotate 'line', 19
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 56
    $P5005 = $P103."postcircumfix:<{ }>"($P5004)
    $P5006 = $P5005."ast"()
    nqp_hllize $P5003, $P5006
    $P5007 = "&make"($P5003)
    perl6_decontainerize_return_value $P5002, $P5007
    goto lexotic_23
  lexotic_22:
    .get_results ($P5002)
  lexotic_23:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 53
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "arraylist" :subid("cuid_6_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 22
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_24
    .lex "RETURN", $P109
.annotate 'line', 23
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 46
    $P5005 = $P103."postcircumfix:<{ }>"($P5004)
    $P5006 = $P5005."dispatch:<hyper>"("ast")
    nqp_hllize $P5003, $P5006
    $P5007 = "&circumfix:<[ ]>"($P5003)
    $P5008 = "&make"($P5007)
    perl6_decontainerize_return_value $P5002, $P5008
    goto lexotic_25
  lexotic_24:
    .get_results ($P5002)
  lexotic_25:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 63
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "string" :subid("cuid_8_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 26
    .param pmc CALL_SIG :call_sig 
    .const 'Sub' $P5006 = 'cuid_7_1372180366.9901' 
    capture_lex $P5006 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    .const 'Sub' $P5001 = 'cuid_7_1372180366.9901' 
    capture_lex $P5001
    set $P5002, CALL_SIG
    set $P106, $P5002
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_28
    .lex "RETURN", $P109
.annotate 'line', 27
    nqp_get_sc_object $P5006, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 15
    $P5007 = $P103."postcircumfix:<[ ]>"($P5006)
    $P5008 = $P5007."elems"()
    nqp_hllize $P5005, $P5008
    nqp_get_sc_object $P5009, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 75
    $P5004 = "&infix:<==>"($P5005, $P5009)
  chain_end_1432:
    unless $P5004 goto if13_else30 
.annotate 'line', 28
    nqp_get_sc_object $P5013, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 15
    $P5014 = $P103."postcircumfix:<[ ]>"($P5013)
    nqp_get_sc_object $P5015, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 15
    $P5016 = $P5014."postcircumfix:<[ ]>"($P5015)
    nqp_hllize $P5012, $P5016
    nqp_get_sc_object $P5017, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 76
    $P5018 = $P5012."postcircumfix:<{ }>"($P5017)
    nqp_hllize $P5011, $P5018
    set $P5027, $P5011
    if $P5011 goto unless15_end34 
    nqp_get_sc_object $P5021, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 15
    $P5022 = $P103."postcircumfix:<[ ]>"($P5021)
    nqp_get_sc_object $P5023, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 15
    $P5024 = $P5022."postcircumfix:<[ ]>"($P5023)
    nqp_hllize $P5020, $P5024
    nqp_get_sc_object $P5025, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 77
    $P5026 = $P5020."postcircumfix:<{ }>"($P5025)
    nqp_hllize $P5019, $P5026
    set $P5027, $P5019
  unless15_end34:
    $P5028 = $P5027."ast"()
    nqp_hllize $P5010, $P5028
    set $P5039, $P5010
    goto if13_end31
  if13_else30:
.annotate 'line', 29
    nqp_get_sc_object $P5029, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 78
    nqp_get_sc_object $P5032, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 15
    $P5033 = $P103."postcircumfix:<[ ]>"($P5032)
    $P5034 = $P5033."list"()
    nqp_hllize $P5031, $P5034
    nqp_get_sc_object $P5035, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 79
    $P5036 = $P5035."clone"()
    perl6_capture_lex $P5036
    $P5037 = $P5031."map"($P5036)
    nqp_hllize $P5030, $P5037
    $P5038 = "&join"($P5029, $P5030)
    set $P5039, $P5038
  if13_end31:
    $P5040 = "&make"($P5039)
    perl6_decontainerize_return_value $P5003, $P5040
    goto lexotic_29
  lexotic_28:
    .get_results ($P5003)
  lexotic_29:
    find_lex $P5004, "&EXHAUST"
    store_lex "RETURN", $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 72
    perl6_type_check_return_value $P5003, $P5005
    .return ($P5003) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_7_1372180366.9901") :anon :lex :outer("cuid_8_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 29
    .param pmc CALL_SIG :call_sig 
    .lex "$_", $P101 
    .lex "call_sig", $P102 
    .lex "$*DISPATCHER", $P103 
    set $P5001, CALL_SIG
    set $P102, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 76
    $P5005 = $P101."postcircumfix:<{ }>"($P5004)
    nqp_hllize $P5003, $P5005
    set $P5009, $P5003
    if $P5003 goto unless12_end27 
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 77
    $P5008 = $P101."postcircumfix:<{ }>"($P5007)
    nqp_hllize $P5006, $P5008
    set $P5009, $P5006
  unless12_end27:
    $P5010 = $P5009."ast"()
    nqp_hllize $P5002, $P5010
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<number>" :subid("cuid_9_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 31
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_35
    .lex "RETURN", $P109
    $P5004 = $P103."Str"()
    nqp_hllize $P5003, $P5004
    $P5005 = "&prefix:<+>"($P5003)
    $P5006 = "&make"($P5005)
    perl6_decontainerize_return_value $P5002, $P5006
    goto lexotic_36
  lexotic_35:
    .get_results ($P5002)
  lexotic_36:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 89
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<string>" :subid("cuid_10_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 32
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_37
    .lex "RETURN", $P109
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 45
    $P5005 = $P103."postcircumfix:<{ }>"($P5004)
    $P5006 = $P5005."ast"()
    nqp_hllize $P5003, $P5006
    $P5007 = "&make"($P5003)
    perl6_decontainerize_return_value $P5002, $P5007
    goto lexotic_38
  lexotic_37:
    .get_results ($P5002)
  lexotic_38:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 100
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<true>" :subid("cuid_11_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 33
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_39
    .lex "RETURN", $P109
    nqp_get_sc_object $P5003, "B9A1DB43DA676D1F1261647412D906DA1B244D1A-1372102072.12878", 131
    $P5004 = "&make"($P5003)
    perl6_decontainerize_return_value $P5002, $P5004
    goto lexotic_40
  lexotic_39:
    .get_results ($P5002)
  lexotic_40:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 109
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<false>" :subid("cuid_12_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 34
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_41
    .lex "RETURN", $P109
    nqp_get_sc_object $P5003, "B9A1DB43DA676D1F1261647412D906DA1B244D1A-1372102072.12878", 130
    $P5004 = "&make"($P5003)
    perl6_decontainerize_return_value $P5002, $P5004
    goto lexotic_42
  lexotic_41:
    .get_results ($P5002)
  lexotic_42:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 119
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<null>" :subid("cuid_13_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 35
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_43
    .lex "RETURN", $P109
    nqp_get_sc_object $P5003, "B9A1DB43DA676D1F1261647412D906DA1B244D1A-1372102072.12878", 17
    $P5004 = "&make"($P5003)
    perl6_decontainerize_return_value $P5002, $P5004
    goto lexotic_44
  lexotic_43:
    .get_results ($P5002)
  lexotic_44:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 129
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<object>" :subid("cuid_14_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 36
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_45
    .lex "RETURN", $P109
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 140
    $P5005 = $P103."postcircumfix:<{ }>"($P5004)
    $P5006 = $P5005."ast"()
    nqp_hllize $P5003, $P5006
    $P5007 = "&make"($P5003)
    perl6_decontainerize_return_value $P5002, $P5007
    goto lexotic_46
  lexotic_45:
    .get_results ($P5002)
  lexotic_46:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 139
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "value:sym<array>" :subid("cuid_15_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 37
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_47
    .lex "RETURN", $P109
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 150
    $P5005 = $P103."postcircumfix:<{ }>"($P5004)
    $P5006 = $P5005."ast"()
    nqp_hllize $P5003, $P5006
    $P5007 = "&make"($P5003)
    perl6_decontainerize_return_value $P5002, $P5007
    goto lexotic_48
  lexotic_47:
    .get_results ($P5002)
  lexotic_48:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 149
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "str" :subid("cuid_16_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 39
    .param pmc CALL_SIG :call_sig 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_49
    .lex "RETURN", $P109
    $P5003 = "&prefix:<~>"($P103)
    $P5004 = "&make"($P5003)
    perl6_decontainerize_return_value $P5002, $P5004
    goto lexotic_50
  lexotic_49:
    .get_results ($P5002)
  lexotic_50:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 159
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "str_escape" :subid("cuid_19_1372180366.9901") :anon :lex :outer("cuid_20_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 41
    .param pmc CALL_SIG :call_sig 
    .const 'Sub' $P5005 = 'cuid_17_1372180366.9901' 
    capture_lex $P5005 
    .const 'Sub' $P5005 = 'cuid_18_1372180366.9901' 
    capture_lex $P5005 
    .lex "self", $P101 
    .lex "%_", $P102 
    .lex "$/", $P103 
    .lex "$_", $P104 
    .lex "$!", $P105 
    .lex "call_sig", $P106 
    .lex "$*DISPATCHER", $P107 
    .lex "&?ROUTINE", $P108 
    set $P5001, CALL_SIG
    set $P106, $P5001
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
    root_new $P109, ['parrot';'Continuation']
    set_label $P109, lexotic_51
    .lex "RETURN", $P109
.annotate 'line', 42
    nqp_get_sc_object $P5003, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 171
    $P5004 = $P103."postcircumfix:<{ }>"($P5003)
    unless $P5004 goto if16_else53 
    .const 'Sub' $P5005 = 'cuid_17_1372180366.9901' 
    capture_lex $P5005
    $P5006 = $P5005()
    set $P5009, $P5006
    goto if16_end54
  if16_else53:
    .const 'Sub' $P5007 = 'cuid_18_1372180366.9901' 
    capture_lex $P5007
    $P5008 = $P5007()
    set $P5009, $P5008
  if16_end54:
    perl6_decontainerize_return_value $P5002, $P5009
    goto lexotic_52
  lexotic_51:
    .get_results ($P5002)
  lexotic_52:
    find_lex $P5003, "&EXHAUST"
    store_lex "RETURN", $P5003
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 168
    perl6_type_check_return_value $P5002, $P5004
    .return ($P5002) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_17_1372180366.9901") :anon :lex :outer("cuid_19_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 42
    .param pmc CALL_SIG :call_sig 
    .lex "$_", $P101 
    .lex "call_sig", $P102 
    .lex "$*DISPATCHER", $P103 
    nqp_getlexouter $P5001, "$_"
    set $P101, $P5001
    set $P5002, CALL_SIG
    set $P102, $P5002
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
.annotate 'line', 44
    nqp_get_sc_object $P5003, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 173
    find_lex $P5005, "$/"
    nqp_get_sc_object $P5006, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 171
    $P5007 = $P5005."postcircumfix:<{ }>"($P5006)
    $P5008 = $P5007."join"()
    nqp_hllize $P5004, $P5008
    $P5009 = "&infix:<~>"($P5003, $P5004)
    $P5010 = "&eval"($P5009)
    $P5011 = "&chr"($P5010)
    $P5012 = "&make"($P5011)
    .return ($P5012) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_18_1372180366.9901") :anon :lex :outer("cuid_19_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
.annotate 'line', 45
    .param pmc CALL_SIG :call_sig 
    .lex "$_", $P101 
    .lex "%h", $P102 
    .lex "call_sig", $P103 
    .lex "$*DISPATCHER", $P104 
    nqp_getlexouter $P5001, "$_"
    set $P101, $P5001
    set $P5002, CALL_SIG
    set $P103, $P5002
    bind_signature 
    nqp_takedispatcher "$*DISPATCHER"
.annotate 'line', 46

.annotate 'line', 52
.annotate 'line', 46
    nqp_get_sc_object $P5003, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 178
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 178
    $P5005 = "&infix:<=>>"($P5003, $P5004)
.annotate 'line', 47
    nqp_get_sc_object $P5006, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 179
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 179
    $P5008 = "&infix:<=>>"($P5006, $P5007)
.annotate 'line', 48
    nqp_get_sc_object $P5009, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 180
    nqp_get_sc_object $P5010, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 181
    $P5011 = "&infix:<=>>"($P5009, $P5010)
.annotate 'line', 49
    nqp_get_sc_object $P5012, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 182
    nqp_get_sc_object $P5013, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 183
    $P5014 = "&infix:<=>>"($P5012, $P5013)
.annotate 'line', 50
    nqp_get_sc_object $P5015, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 184
    nqp_get_sc_object $P5016, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 185
    $P5017 = "&infix:<=>>"($P5015, $P5016)
.annotate 'line', 51
    nqp_get_sc_object $P5018, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 186
    nqp_get_sc_object $P5019, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 187
    $P5020 = "&infix:<=>>"($P5018, $P5019)
.annotate 'line', 52
    nqp_get_sc_object $P5021, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 188
    nqp_get_sc_object $P5022, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 189
    $P5023 = "&infix:<=>>"($P5021, $P5022)
.annotate 'line', 53
    nqp_get_sc_object $P5024, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 190
    nqp_get_sc_object $P5025, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 190
    $P5026 = "&infix:<=>>"($P5024, $P5025)
    $P5027 = "&infix:<,>"($P5005, $P5008, $P5011, $P5014, $P5017, $P5020, $P5023, $P5026)
    $P102."STORE"($P5027)
.annotate 'line', 54
    find_lex $P5004, "$/"
    $P5005 = "&prefix:<~>"($P5004)
    $P5006 = $P102."postcircumfix:<{ }>"($P5005)
    nqp_hllize $P5003, $P5006
    $P5007 = "&make"($P5003)
    .return ($P5007) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_24_1372180366.9901") :load :init
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
    .const 'Sub' $P5001 = 'cuid_23_1372180366.9901' 
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
    .const 'Sub' $P5001 = "cuid_22_1372180366.9901" 
    get_hll_global $P5002, "ModuleLoader"
    $P5003 = $P5002."load_setting"("CORE")
    $P5004 = $P5001."set_outer_ctx"($P5003)
    nqp_create_sc $P5001, "724015930C4F12C671F45EADF9AAD9E2E352CF10"
    set cur_sc, $P5001
    $P5002 = cur_sc."set_description"("lib/JSON/Tiny/Actions.pm")
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
    push $P5004, "TOP"
    push $P5004, "object"
    push $P5004, "pairlist"
    push $P5004, "pair"
    push $P5004, "array"
    push $P5004, "arraylist"
    push $P5004, "string"
    push $P5004, "value:sym<number>"
    push $P5004, "value:sym<string>"
    push $P5004, "value:sym<true>"
    push $P5004, "value:sym<false>"
    push $P5004, "value:sym<null>"
    push $P5004, "value:sym<object>"
    push $P5004, "value:sym<array>"
    push $P5004, "str"
    push $P5004, "str_escape"
    push $P5004, "B9A1DB43DA676D1F1261647412D906DA1B244D1A-1372102072.12878"
    push $P5004, "src/gen/BOOTSTRAP.nqp"
    push $P5004, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613"
    push $P5004, "src/gen/Metamodel.nqp"
    push $P5004, "$_"
    push $P5004, "$/"
    push $P5004, "$!"
    push $P5004, "0"
    push $P5004, "%_"
    push $P5004, "value"
    push $P5004, "1"
    push $P5004, ""
    push $P5004, "number"
    push $P5004, "sym"
    push $P5004, "true"
    push $P5004, "false"
    push $P5004, "null"
    push $P5004, "xdigit"
    push $P5004, "0x"
    push $P5004, "%h"
    push $P5004, "\\"
    push $P5004, "/"
    push $P5004, "b"
    push $P5004, "\b"
    push $P5004, "n"
    push $P5004, "\n"
    push $P5004, "t"
    push $P5004, "\t"
    push $P5004, "f"
    push $P5004, "\f"
    push $P5004, "r"
    push $P5004, "\r"
    push $P5004, "\""
    push $P5004, "GLOBAL"
    push $P5004, "JSON"
    push $P5004, "EXPORT"
    push $P5004, "JSON::Tiny::Actions"
    push $P5004, "7A67D46DDEA3C60BB73DFB1CA4F76715F3D1212C-1372101917.20204"
    push $P5004, "src/stage2/NQPCORE.setting"
    push $P5004, "Tiny"
    push $P5004, "Actions"
    push $P5004, "!UNIT_MARKER"
    .const 'Sub' $P5005 = 'cuid_23_1372180366.9901' 
    capture_lex $P5005
    $P5006 = $P5005()
    nqp_deserialize_sc "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AQABAAEAAQACAAIAAAARAAAAAAAAAAAAAABsAAAAbAAAAAEAAQCAAAAAAAAAAAIAAgAAABEAAAABAAEAAAAAAAEAAQACAAAAAAAbAAAAAQACAAIAAAAQAAAAAAAAAAAAAABvAAAAbwAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAAAdAAAAAQAHAAMAAAACAAAAAAAaAAAAAgAAAAAAHAAAAAIAAAAAAB4AAAABAAEAAQACAAAAAAAWAAAACwAAAAAAAgAAAAIAAAAAACkAAAADAAEAAQABAAEAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACQAAAAAAAAAAAAAAAQABAAIAAAAAAAMAAAACAAIAAAARAAAAAQACAAAAAAAHAAAAAgACAAAAEQAAAAEAWgAAAAAAAAABAAEAwAAAAAAAAAACAAAAAAAJAAAAAQABAAAAAAABAAEAAQABAAIAAgAAABEAAAAAAAAAAAAAAGwAAABsAAAAAQABAIAAAAAAAAAAAgACAAAAEQAAAAEAAQAAAAAAAQABAAIAAAAAACUAAAABAAIAAgAAABAAAAAAAAAAAAAAAG8AAABvAAAAAQABAJAAAAAAAAAAAgACAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAACcAAAABAAcAAwAAAAIAAAAAACQAAAACAAAAAAAmAAAAAgAAAAAAKAAAAAEAAQABAAIAAAAAACAAAAALAAAAAAADAAAAAgAAAAAANAAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAJAAAAAAAAAAAAAAABAAEAAgAAAAAAAwAAAAIAAgAAABEAAAABAAIAAAAAAAcAAAACAAIAAAARAAAAAQBdAAAAcAAAAAAAAAABAAEAwAAAAAAAAAACAAAAAAAJAAAAAQABAAAAAAABAAEAAQABAAIAAgAAABEAAAAAAAAAAAAAAGwAAABsAAAAAQABAIAAAAAAAAAAAgACAAAAEQAAAAEAAQAAAAAAAQABAAIAAAAAADAAAAABAAIAAgAAABAAAAAAAAAAAAAAAG8AAABvAAAAAQABAJAAAAAAAAAAAgACAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAADIAAAABAAcAAwAAAAIAAAAAAC8AAAACAAAAAAAxAAAAAgAAAAAAMwAAAAEAAQABAAIAAAAAACoAAAALAAAAAAAEAAAAAgAAAAAAPgAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAJAAAAAAAAAAAAAAABAAEAAgAAAAAAAwAAAAIAAgAAABEAAAABAAIAAAAAAAcAAAACAAIAAAARAAAAAQBcAAAAAAAAAAEAAQDAAAAAAAAAAAIAAAAAAAkAAAABAAEAAAAAAAEAAQABAAEAAgACAAAAEQAAAAAAAAAAAAAAbAAAAGwAAAABAAEAgAAAAAAAAAACAAIAAAARAAAAAQABAAAAAAABAAEAAgAAAAAAOgAAAAEAAgACAAAAEAAAAAAAAAAAAAAAbwAAAG8AAAABAAEAkAAAAAAAAAACAAIAAAAQAAAAAQABAAAAAAABAAEAAgAAAAAAPAAAAAEABwADAAAAAgAAAAAAOQAAAAIAAAAAADsAAAACAAAAAAA9AAAAAQABAAEAAgAAAAAANQAAAAsAAAAAAAUAAAACAAAAAABHAAAAAwABAAEAAQABAAAAAAAAAAAAAQAAAAAAAAAAAAIAAAAAAAkAAAAAAAAAAAAAAAEAAQACAAAAAAADAAAAAgACAAAAEQAAAAEAAgAAAAAABwAAAAIAAgAAABEAAAABAAAAAAABAAEAwAAAAAAAAAACAAAAAAAJAAAAAQABAAAAAAABAAEAAQABAAIAAgAAABEAAAAAAAAAAAAAAGwAAABsAAAAAQABAIAAAAAAAAAAAgACAAAAEQAAAAEAAQAAAAAAAQABAAIAAAAAAEMAAAABAAIAAgAAABAAAAAAAAAAAAAAAG8AAABvAAAAAQABAJAAAAAAAAAAAgACAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAAEUAAAABAAcAAwAAAAIAAAAAAEIAAAACAAAAAABEAAAAAgAAAAAARgAAAAEAAQABAAIAAAAAAD8AAAALAAAAAAAHAAAAAgAAAAAAWAAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAJAAAAAAAAAAAAAAABAAEAAgAAAAAAAwAAAAIAAgAAABEAAAABAAIAAAAAAAcAAAACAAIAAAARAAAAAQBxAAAAZQAAAGYAAAByAAAACwAAAAAABgAAAAIAAAAAAFIAAAADAAEAAgACAAAAEAAAAAAAAAAAAAAAawAAAGsAAAABAAEAAEwAAAAAAAACAAIAAAAQAAAAAQABAAAAAAABAAEAAgAAAAAAUAAAAAEABwABAAAAAgAAAAAAUQAAAAEAAQABAAIAAAAAAE8AAAAAAAAAAQABAMAAAAAAAAAAAgAAAAAACQAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAARAAAAAAAAAAAAAABsAAAAbAAAAAEAAQCAAAAAAAAAAAIAAgAAABEAAAABAAEAAAAAAAEAAQACAAAAAABUAAAAAQACAAIAAAAQAAAAAAAAAAAAAABvAAAAbwAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAABWAAAAAQAHAAMAAAACAAAAAABTAAAAAgAAAAAAVQAAAAIAAAAAAFcAAAABAAEAAQACAAAAAABIAAAACwAAAAAACAAAAAIAAAAAAGMAAAADAAEAAQABAAEAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACQAAAAAAAAAAAAAAAQABAHMAAAB0AAAAAgAAAAAAAwAAAAIAAgAAABEAAAABAAIAAAAAAAcAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACQAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAARAAAAAAAAAAAAAABsAAAAbAAAAAEAAQCAAAAAAAAAAAIAAgAAABEAAAABAAEAAAAAAAEAAQACAAAAAABfAAAAAQACAAIAAAAQAAAAAAAAAAAAAABvAAAAbwAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAABhAAAAAQAHAAMAAAACAAAAAABeAAAAAgAAAAAAYAAAAAIAAAAAAGIAAAABAAEAAQACAAAAAABZAAAACwAAAAAACQAAAAIAAAAAAGwAAAADAAEAAQABAAEAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACQAAAAAAAAAAAAAAAQABAAIAAAAAAAMAAAACAAIAAAARAAAAAQACAAAAAAAHAAAAAgACAAAAEQAAAAEAAAAAAAEAAQDAAAAAAAAAAAIAAAAAAAkAAAABAAEAAAAAAAEAAQABAAEAAgACAAAAEQAAAAAAAAAAAAAAbAAAAGwAAAABAAEAgAAAAAAAAAACAAIAAAARAAAAAQABAAAAAAABAAEAAgAAAAAAaAAAAAEAAgACAAAAEAAAAAAAAAAAAAAAbwAAAG8AAAABAAEAkAAAAAAAAAACAAIAAAAQAAAAAQABAAAAAAABAAEAAgAAAAAAagAAAAEABwADAAAAAgAAAAAAZwAAAAIAAAAAAGkAAAACAAAAAABrAAAAAQABAAEAAgAAAAAAZAAAAAsAAAAAAAoAAAACAAAAAAB2AAAAAwABAAEAAQABAAAAAAAAAAAAAQAAAAAAAAAAAAIAAAAAAAkAAAAAAAAAAAAAAAEAAQB1AAAAAgAAAAAAAwAAAAIAAgAAABEAAAABAAIAAAAAAAcAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACQAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAARAAAAAAAAAAAAAABsAAAAbAAAAAEAAQCAAAAAAAAAAAIAAgAAABEAAAABAAEAAAAAAAEAAQACAAAAAAByAAAAAQACAAIAAAAQAAAAAAAAAAAAAABvAAAAbwAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAAB0AAAAAQAHAAMAAAACAAAAAABxAAAAAgAAAAAAcwAAAAIAAAAAAHUAAAABAAEAAQACAAAAAABtAAAACwAAAAAACwAAAAIAAAAAAIAAAAADAAEAAQABAAEAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACQAAAAAAAAAAAAAAAQABAHYAAAACAAAAAAADAAAAAgACAAAAEQAAAAEAAgAAAAAABwAAAAIAAgAAABEAAAABAAAAAAABAAEAwAAAAAAAAAACAAAAAAAJAAAAAQABAAAAAAABAAEAAQABAAIAAgAAABEAAAAAAAAAAAAAAGwAAABsAAAAAQABAIAAAAAAAAAAAgACAAAAEQAAAAEAAQAAAAAAAQABAAIAAAAAAHwAAAABAAIAAgAAABAAAAAAAAAAAAAAAG8AAABvAAAAAQABAJAAAAAAAAAAAgACAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAAH4AAAABAAcAAwAAAAIAAAAAAHsAAAACAAAAAAB9AAAAAgAAAAAAfwAAAAEAAQABAAIAAAAAAHcAAAALAAAAAAAMAAAAAgAAAAAAigAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAJAAAAAAAAAAAAAAABAAEAdwAAAAIAAAAAAAMAAAACAAIAAAARAAAAAQACAAAAAAAHAAAAAgACAAAAEQAAAAEAAAAAAAEAAQDAAAAAAAAAAAIAAAAAAAkAAAABAAEAAAAAAAEAAQABAAEAAgACAAAAEQAAAAAAAAAAAAAAbAAAAGwAAAABAAEAgAAAAAAAAAACAAIAAAARAAAAAQABAAAAAAABAAEAAgAAAAAAhgAAAAEAAgACAAAAEAAAAAAAAAAAAAAAbwAAAG8AAAABAAEAkAAAAAAAAAACAAIAAAAQAAAAAQABAAAAAAABAAEAAgAAAAAAiAAAAAEABwADAAAAAgAAAAAAhQAAAAIAAAAAAIcAAAACAAAAAACJAAAAAQABAAEAAgAAAAAAgQAAAAsAAAAAAA0AAAACAAAAAACUAAAAAwABAAEAAQABAAAAAAAAAAAAAQAAAAAAAAAAAAIAAAAAAAkAAAAAAAAAAAAAAAEAAQBYAAAAAgAAAAAAAwAAAAIAAgAAABEAAAABAAIAAAAAAAcAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACQAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAARAAAAAAAAAAAAAABsAAAAbAAAAAEAAQCAAAAAAAAAAAIAAgAAABEAAAABAAEAAAAAAAEAAQACAAAAAACQAAAAAQACAAIAAAAQAAAAAAAAAAAAAABvAAAAbwAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAACSAAAAAQAHAAMAAAACAAAAAACPAAAAAgAAAAAAkQAAAAIAAAAAAJMAAAABAAEAAQACAAAAAACLAAAACwAAAAAADgAAAAIAAAAAAJ4AAAADAAEAAQABAAEAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACQAAAAAAAAAAAAAAAQABAFsAAAACAAAAAAADAAAAAgACAAAAEQAAAAEAAgAAAAAABwAAAAIAAgAAABEAAAABAAAAAAABAAEAwAAAAAAAAAACAAAAAAAJAAAAAQABAAAAAAABAAEAAQABAAIAAgAAABEAAAAAAAAAAAAAAGwAAABsAAAAAQABAIAAAAAAAAAAAgACAAAAEQAAAAEAAQAAAAAAAQABAAIAAAAAAJoAAAABAAIAAgAAABAAAAAAAAAAAAAAAG8AAABvAAAAAQABAJAAAAAAAAAAAgACAAAAEAAAAAEAAQAAAAAAAQABAAIAAAAAAJwAAAABAAcAAwAAAAIAAAAAAJkAAAACAAAAAACbAAAAAgAAAAAAnQAAAAEAAQABAAIAAAAAAJUAAAALAAAAAAAPAAAAAgAAAAAApwAAAAMAAQABAAEAAQAAAAAAAAAAAAEAAAAAAAAAAAACAAAAAAAJAAAAAAAAAAAAAAABAAEAAgAAAAAAAwAAAAIAAgAAABEAAAABAAIAAAAAAAcAAAACAAIAAAARAAAAAQAAAAAAAQABAMAAAAAAAAAAAgAAAAAACQAAAAEAAQAAAAAAAQABAAEAAQACAAIAAAARAAAAAAAAAAAAAABsAAAAbAAAAAEAAQCAAAAAAAAAAAIAAgAAABEAAAABAAEAAAAAAAEAAQACAAAAAACjAAAAAQACAAIAAAAQAAAAAAAAAAAAAABvAAAAbwAAAAEAAQCQAAAAAAAAAAIAAgAAABAAAAABAAEAAAAAAAEAAQACAAAAAAClAAAAAQAHAAMAAAACAAAAAACiAAAAAgAAAAAApAAAAAIAAAAAAKYAAAABAAEAAQACAAAAAACfAAAACwAAAAAAEgAAAAIAAAAAAMUAAAADAAEAAQABAAEAAAAAAAAAAAABAAAAAAAAAAAAAgAAAAAACQAAAAAAAAAAAAAAAQABAAIAAAAAAAMAAAACAAIAAAARAAAAAQACAAAAAAAHAAAAAgACAAAAEQAAAAEAeAAAAAsAAAAAABAAAAACAAAAAACuAAAAAwABAHkAAAAHAAAAAAABAAEAAQACAAAAAACsAAAACwAAAAAAEQAAAAIAAAAAAL8AAAADAAEAAgACAAAAEAAAAAEAAAAAAAAAegAAAAEAAgAAAAAAsAAAAHsAAAB8AAAAfQAAAH4AAAB/AAAAgAAAAIEAAACCAAAAgwAAAIQAAACFAAAAhgAAAIcAAAAHAAAAAAABAAEAAQACAAAAAACvAAAAAAAAAAEAAQDAAAAAAAAAAAIAAAAAAAkAAAABAAEAAAAAAAEAAQABAAEAAgACAAAAEQAAAAAAAAAAAAAAbAAAAGwAAAABAAEAgAAAAAAAAAACAAIAAAARAAAAAQABAAAAAAABAAEAAgAAAAAAwQAAAAEAAgACAAAAEAAAAAAAAAAAAAAAbwAAAG8AAAABAAEAkAAAAAAAAAACAAIAAAAQAAAAAQABAAAAAAABAAEAAgAAAAAAwwAAAAEABwADAAAAAgAAAAAAwAAAAAIAAAAAAMIAAAACAAAAAADEAAAAAQABAAEAAgAAAAAAqAAAAAcAAAAAAAEAAQABAAIAAAAAAMcAAAALAAAAAAATAAAAAgAAAAAAxgAAAAMAAQABAAIAAgAAAIMAAAACAAAAAADXAAAAAQAHAAAAAAABAAEAAQACAAAAAAACAAAABAABAAAAAAAAAAYAiAAAAAEACgABAAAAiQAAAAIAAAAAAAoAAAABAAQAAQAAAAAAAAAGAIoAAAABAAoAAAAAAAEABwAAAAAABwAAAAAABwAAAAAABwAAAAAABAABAAAAAAAAAAYAiwAAAAEAAQABAAcAAAAAAAoAAAAAAAEACgAQAAAAVwAAAAIAAAAAAAwAAABYAAAAAgAAAAAAFgAAAFkAAAACAAAAAAAgAAAAWgAAAAIAAAAAACoAAABbAAAAAgAAAAAANQAAAFwAAAACAAAAAAA/AAAAXQAAAAIAAAAAAEgAAABeAAAAAgAAAAAAWQAAAF8AAAACAAAAAABkAAAAYAAAAAIAAAAAAG0AAABhAAAAAgAAAAAAdwAAAGIAAAACAAAAAACBAAAAYwAAAAIAAAAAAIsAAABkAAAAAgAAAAAAlQAAAGUAAAACAAAAAACfAAAAZgAAAAIAAAAAAKgAAAAKAAAAAAAHABAAAAACAAAAAAAMAAAAAgAAAAAAFgAAAAIAAAAAACAAAAACAAAAAAAqAAAAAgAAAAAANQAAAAIAAAAAAD8AAAACAAAAAABIAAAAAgAAAAAAWQAAAAIAAAAAAGQAAAACAAAAAABtAAAAAgAAAAAAdwAAAAIAAAAAAIEAAAACAAAAAACLAAAAAgAAAAAAlQAAAAIAAAAAAJ8AAAACAAAAAACoAAAACgAAAAAACgAAAAAABwAAAAAABwAAAAAABwABAAAAAgACAAAAEQAAAAcAAAAAAAIABAAAABoAAAAHAAMAAAACAAAAAAAJAAAAAgACAAAAEQAAAAIAAgAAABAAAAAHAAMAAAACAAAAAAAJAAAAAgACAAAAEQAAAAIAAgAAABAAAAAHAAAAAAAHAAAAAAAHAAAAAAABAAQABQAAAAAAAAAEAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAEACgAAAAAACgAAAAAACgAAAAAAAQAEAAEAAAAAAAAABgCJAAAAAQAKAAEAAACOAAAAAgAAAAAACwAAAAEABAABAAAAAAAAAAYAjgAAAAEACgABAAAAjwAAAAIAAAAAAAkAAAABAAQAAQAAAAAAAAAGAJAAAAABAAoAAAAAAAEAAQABAAcAAAAAAAIAAAAAAMgAAAA=", cur_sc, $P5004, $P5006, conflicts
    unless conflicts goto if17_end56 
    get_hll_global $P5007, "ModuleLoader"
    $P5008 = $P5007."resolve_repossession_conflicts"(conflicts)
  if17_end56:
    .const 'Sub' $P5001 = "cuid_1_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 12
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_2_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 22
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_3_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 32
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_4_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 42
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_5_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 53
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_6_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 63
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_7_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 79
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_8_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 72
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_9_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 89
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_10_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 100
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_11_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 109
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_12_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 119
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_13_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 129
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_14_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 139
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_15_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 149
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_16_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 159
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_17_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 172
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_18_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 175
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_19_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 168
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_20_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 199
    set_sub_code_object $P5001, $P5002
    .const 'Sub' $P5001 = "cuid_21_1372180366.9901" 
    nqp_get_sc_object $P5002, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 2
    set_sub_code_object $P5001, $P5002
    nqp_get_sc_object $P5001, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 0
    set_hll_global "GLOBAL", $P5001
    .const "LexInfo" $P5001 = "cuid_21_1372180366.9901"
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
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 0
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 1
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 0
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 0
    push $P5003, $P5007
    nqp_get_sc_object $P5008, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 4
    push $P5003, $P5008
    nqp_get_sc_object $P5009, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 6
    push $P5003, $P5009
    nqp_get_sc_object $P5010, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 8
    push $P5003, $P5010
    nqp_get_sc_object $P5011, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 10
    push $P5003, $P5011
    nqp_get_sc_object $P5012, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 200
    push $P5003, $P5012
    nqp_get_sc_object $P5013, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 201
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
    .const "LexInfo" $P5001 = "cuid_20_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$?PACKAGE"
    push $P5002, "::?PACKAGE"
    push $P5002, "$?CLASS"
    push $P5002, "::?CLASS"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 9
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 9
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 9
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 9
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 0
    push $P5008, 0
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_1_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 13
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 14
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 12
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_2_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 23
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 24
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 22
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_3_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 33
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 34
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 32
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_4_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 43
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 44
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 42
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_5_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 54
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 55
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 53
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_6_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 64
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 65
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 63
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_8_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 73
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 74
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 72
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_9_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 92
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 93
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 89
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_10_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 101
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 102
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 100
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_11_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 111
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 112
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 109
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_12_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 121
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 122
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 119
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_13_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 131
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 132
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 129
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_14_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 141
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 142
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 139
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_15_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 151
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 152
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 149
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_16_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 160
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 161
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 159
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_19_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "$_"
    push $P5002, "$!"
    push $P5002, "$*DISPATCHER"
    push $P5002, "&?ROUTINE"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 169
    push $P5003, $P5004
    nqp_get_sc_object $P5005, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 170
    push $P5003, $P5005
    nqp_get_sc_object $P5006, "31969E757C3E893E819422824836ADA52B0F1EAF-1372102063.72613", 308
    push $P5003, $P5006
    nqp_get_sc_object $P5007, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 168
    push $P5003, $P5007
    new $P5008, 'ResizableIntegerArray'
    push $P5008, 1
    push $P5008, 1
    push $P5008, 0
    push $P5008, 0
    $P5001."setup_static_lexpad"($P5002, $P5003, $P5008)
    .const "LexInfo" $P5001 = "cuid_18_1372180366.9901"
    new $P5002, 'ResizableStringArray'
    push $P5002, "%h"
    new $P5003, 'ResizablePMCArray'
    nqp_get_sc_object $P5004, "724015930C4F12C671F45EADF9AAD9E2E352CF10", 177
    push $P5003, $P5004
    new $P5005, 'ResizableIntegerArray'
    push $P5005, 1
    $P5006 = $P5001."setup_static_lexpad"($P5002, $P5003, $P5005)
    .return ($P5006) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_23_1372180366.9901") :anon :lex :outer("cuid_24_1372180366.9901")
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
    new $P5001, 'ResizablePMCArray'
    .const 'Sub' $P5002 = "cuid_1_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_2_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_3_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_4_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_5_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_6_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_7_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_8_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_9_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_10_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_11_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_12_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_13_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_14_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_15_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_16_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_17_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_18_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_19_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_20_1372180366.9901" 
    push $P5001, $P5002
    .const 'Sub' $P5002 = "cuid_21_1372180366.9901" 
    push $P5001, $P5002
    .return ($P5001) 
.end
.HLL "perl6"
.namespace []
.sub "" :subid("cuid_25_1372180366.9901") :load
.annotate 'file', "lib/JSON/Tiny/Actions.pm"
    .const 'Sub' $P5001 = "cuid_22_1372180366.9901" 
    $P5002 = $P5001()
    .return ($P5002) 
.end