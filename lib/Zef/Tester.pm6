role Testing { # base testing role for plugins
    submethod BUILD( ) {
        # Doesn't work...?
        # my @roles = <Zef::Role::P5Prove>;
        # for @roles -> $role {
        #    require ::($role);
        #    self does ::($role);
        # }

        use Zef::Role::P5Prove;
        self does Zef::Role::P5Prove;
    }
}

class Zef::Tester { 
    also does Testing;
};
