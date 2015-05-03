role Zef::Phase::Reporting {
    has @!plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            try require ::($p);
            if ::($p) !~~ Failure {
                if ::($p).does(Zef::Phase::Reporting) {
                    self does ::($p);
                }
            }
            else {
                say "Failed to load: $p";
            }
        }
    }

    method report { ... }
}