# todo: actions to finish out the rules, like test counting
grammar Zef::Test::Grammar {
    token TOP { ^^ <line>+ [$$ || $] }

    token line { 
        [
        || [<version>? [<plan> || <test>] [\h* <directive>]?]
        || <diagnostics>
        ]
        \n
    }

    token version { 
        [:i version]
        \h+
        [
        | [1 [2..9]]
        | [[2..9] [0..9]]
        | [[1..9] [0..9] [0..9]+]
        ]
    }

    token plan { $<start>=[<.digit>] '..' $<end>=[<.digit>] }
    token test { 
        <grade> [\h+ <test-number>]? [\h+ <why>]?
    }

    token why         { <[\N] - [#]>*                    }
    token grade       { 'ok' || 'not ok'                 }

    # actions should mark tests with the skip or todo directive as passed
    token directive   { '#' [\h+ [<todo> || <skip>]]?    }
    token skip        { [:!i 'SKIP'] \S* [<.ws> <why>]?  }
    token todo        { [:!i 'TODO'] [\h+ <why>]?        }

    token test-number { <.digit>+                        }
    token diagnostics { '#' <.why>                       }
    token bail-out    { 'Bail out!' <dump>               }
    token dump        { .* }
}
