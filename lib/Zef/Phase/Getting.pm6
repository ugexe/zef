role Zef::Phase::Getting {
    has @!plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            try require ::($p);
            unless ::($p) ~~ Failure {
                if ::($p).does(Zef::Phase::Getting) {
                    self does ::($p);
                }
            }
        }
    }

    method get { ... }
}