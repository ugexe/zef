grammar Zef::Test::Grammar {
    token TOP { [<line> \n]+ }

    token line { 
        [
        || <version>? [<plan> || <test>]
        || <diagnostics>?
        ]
    }

    token version { 
        [:i version]
        <.ws>
        [
        | [1 [2..9]]
        | [[2..9] [0..9]]
        | [[1..9] [0..9] [0..9]+]
        ]
    }

    token plan { <digit> '..' <digit> [<.ws> <directive>]? }
    token test { 
        <grade> <.ws> <test-number> 
        [
        || [<.ws> <why>]?
        || [<.ws> <directive>]? 
        ]
    }

    token why         { <-[#] -[\n]>*                    }
    token grade       { 'ok' || 'not ok'                 }
    token directive   { '#' [<.ws> [<todo> || <skip>]]?  }
    token skip        { [:!i [SKIP] \S*] [<.ws> <why>]?  }
    token todo        { [:!i TODO] [<.ws> <why>]?        }
    token test-number { <.digit>+                        }
    token diagnostics { '#' <why>                        }
    token bail-out    { 'Bail out!' <dump>               }
    token dump        { .* }
}
