role Zef::Phase::Building is export {
    has @.plugins;

    submethod BUILD(:@!plugins) {
        for @!plugins -> $p { 
            say "[LOAD PLUGIN] trying $p ...";
            try require ::($p);
            unless ::($p) ~~ Failure {
                if ::($p).does(Zef::Phase::Building) { self does ::($p);  }
                say "[PLUGIN LOADED] Zef::Phase::Building: $p";
            }
        }
    }

    multi method pre-comp { ... }
}