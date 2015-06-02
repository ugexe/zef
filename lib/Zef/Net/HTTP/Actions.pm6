# Actions for applying to Net::HTTP::Grammar

# todo: make this a separate set of actions
role Zef::Net::HTTP::Actions::Header::Accept { 
    method Accept($/) {
        make [$/<media-range>>>.made];
    }

    method media-range($/) {
        if $/<parameter>.elems {
            make $/<name>.Str => [$/<parameter>>>.made];
        }
        else {
            make $/<name>.Str;
        }
    }

    method weight($/) {
        make $/<qvalue>.Str;
    }

    method parameter($/) { 
        make $/<name>.Str => $/<value>.Str; 
    }

    method accept-params($/) { 
        if $/<accept-ext>.elems {
            make $/<weight>.made => [$/<accept-ext>>>.made];
        }
        else {
            make $/<weight>.made;
        }
    }

    method accept-ext($/) {
        if $/<value>.elems {
            make $/<name>.Str => $/<value>.made;
        }
        else {
            make $/<name>.Str;
        }
    }

}

role Zef::Net::HTTP::Actions::Header::Connection {
    method Connection($/) {
        make [$<connection-option>>>.Str]
    }
}

class Zef::Net::HTTP::Actions {
    also does Zef::Net::HTTP::Actions::Header::Accept;
    also does Zef::Net::HTTP::Actions::Header::Connection;

    method start-line($/) {
        make $/.made;
    }

    method method($/) {
        make ~$/;
    }

    method request-target($/) {
        # todo: use a URI object?
        make $/.Str;
    }

    method header-field($/) {
        if $/<value>.elems {
            make $/<name>.Str => [$/<value>>>.made];
        }
        else {
            make $/<name>.Str => $/<value>.Str;
        }
    }

}

