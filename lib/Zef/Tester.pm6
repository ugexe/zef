role Testing { # base testing role for plugins
    submethod BUILD( ) {
        my @roles = <Zef::Role::P5Prove>;
        for @roles -> $role {
            require ::($role) :OUR<ALL>;
            self does Zef::Role::P5Prove;
        }
    }
}

class Zef::Tester { 
    also does Testing;
};
