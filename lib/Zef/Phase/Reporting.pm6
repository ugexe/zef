role Zef::Phase::Reporting {
    has @!plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            try require ::($p);
            unless ::($p) ~~ Failure {
                if ::($p).does(Zef::Phase::Reporting) {
                    self does ::($p);
                }
            }
        }
    }

    method report { ... }
}