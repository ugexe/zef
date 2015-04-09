role Zef::Phase::Reporting is export {
    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            say "[LOAD PLUGIN] trying $p ...";
            if do { require ::($p); ::($p).does(Zef::Phase::Reporting) } {
                self does ::($p);
                say "[PLUGIN LOADED] Zef::Phase::Reporting: $p";
            }
        }
    }

    multi method report { ... }
}