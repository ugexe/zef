role Zef::Phase::Building {
    has @!plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            try require $p;
            unless ::($p) ~~ Failure {
                if ::($p).does(Zef::Phase::Building) {
                    self does ::($p);
                }
            }
        }
    }

    method pre-compile { ... }
}