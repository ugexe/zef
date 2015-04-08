role Zef::Phase::Reporting is export {
    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            if do { require ::($p); ::($p).does(Zef::Phase::Building) } {
                self does ::($p);
                say "[PLUGIN] Phase::Reporting: $p";
            }
        }
    }

    multi method report { ... }
}