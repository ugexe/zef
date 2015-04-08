role Zef::Phase::Getting is export {
    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            if do { require ::($p); ::($p).does(Zef::Phase::Getting) } {
                self does ::($p);
                say "[PLUGIN] Phase::Getting: $p";
            }
        }
    }

    multi method get { ... }
}