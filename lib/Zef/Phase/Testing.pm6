role Zef::Phase::Testing is export {
    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            if do { require ::($p); ::($p).does(Zef::Phase::Testing) } {
                self does ::($p);
                say "[PLUGIN] Phase::Testing: $p";
            }
        }
    }

    multi method test { ... }
}