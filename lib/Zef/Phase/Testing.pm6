role Zef::Phase::Testing {
    has @!plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            try require ::($p);
            unless ::($p) ~~ Failure {
                if ::($p).does(Zef::Phase::Testing) {
                    self does ::($p);
                }
            }
        }
    }

    method test { ... }
}