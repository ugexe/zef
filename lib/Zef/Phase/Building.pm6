role Zef::Phase::Building is export {
    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            say "[LOAD PLUGIN] trying $p ...";
            if try { require ::($p) } {
                self does ::($p) if ::($p).does(Zef::Phase::Building);
                say "[PLUGIN LOADED] Zef::Phase::Building: $p";
            }
        }
    }

    multi method pre-comp { ... }
}