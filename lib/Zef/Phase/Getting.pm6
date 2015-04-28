role Zef::Phase::Getting is export {
    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            say "[LOAD PLUGIN] trying $p ...";
            if try { require ::($p) } {
                self does ::($p) if ::($p).does(Zef::Phase::Getting);
                say "[PLUGIN LOADED] Zef::Phase::Getting: $p";
            }
        }
    }

    multi method get { ... }
}