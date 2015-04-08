role Zef::Phase::Building is export {
    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            if do { require ::($p); ::($p).does(Zef::Phase::Building) } {
                self does ::($p);
                say "[PLUGIN] Phase::Building: $p";
            }
        }
    }

    multi method pre-comp { ... }
}