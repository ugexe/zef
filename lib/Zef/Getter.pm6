role Getting { # base testing role for plugins
    submethod BUILD( ) {
        my @roles = <Zef::Role::HTTP-Fetch Zef::Role::Git-Fetch>;
        for @roles -> $role {
            require ::($role);
            self does ::($role);
        }
    }
}

class Zef::Getter { 
    also does Getting;
};
