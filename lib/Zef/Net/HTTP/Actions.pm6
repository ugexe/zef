# Actions for applying to Net::HTTP::Grammar

role Zef::Net::HTTP::Actions::Header::Accept-Encoding { 
    method Accept-Encoding($/) {
        make $/<accept-encoding-value>>>.made;
    }

    method accept-encoding-value($/) {
        if $/<weight> {
            make [coding => $/<codings>.Str, weight => $/<weight>.[0].made];
        }
        else {
            make [coding => $/<codings>.Str];
        }
    }

    method codings($/) {
        make $/.Str;
    } 
}

role Zef::Net::HTTP::Actions::Header::Accept { 
    method Accept($/) {
        make $/<accept-value>>>.made;
    }

    method accept-value($/) {
        if $/<accept-params> {
            make [range => $/<media-range>.made, $/<accept-params>.made.flat];
        }
        else {
            make [range => $/<media-range>.made];
        }
    }

    method media-range($/) {
        if $/<parameter> {
            make [type => $/<type>.Str, subtype => $/<subtype>.Str, parameters => [$/<parameter>>>.made]];
        }
        else {
            make [type => $/<type>.Str, subtype => $/<subtype>.Str];            
        }
    }

    method parameter($/) { 
        make $/<name>.Str => $/<value>.Str; 
    }

    method accept-params($/) { 
        if $/<accept-ext> {
            make [weight => $/<weight>.made, parameters => [$/<accept-ext>>>.made]];
        }
        else {
            make [weight => $/<weight>.made];
        }
    }

    method weight($/) {
        make $/<qvalue>.made;
    }

    method accept-ext($/) {
        if $/<value> {
            make $/<name>.Str => $/<value>.Str;
        }
        else {
            make $/<name>.Str;
        }
    }

    method qvalue($/) {
        make $/.Str;
    }
}

role Zef::Net::HTTP::Actions::Header::Connection {
    method Connection($/) {
        make [$<connection-option>>>.Str]
    }
}

class Zef::Net::HTTP::Actions {
    also does Zef::Net::HTTP::Actions::Header::Accept;
    also does Zef::Net::HTTP::Actions::Header::Accept-Encoding;
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
        if $/<value>.made {
            make $/<name>.Str => [$/<value>>>.made];
        }
        else {
            make $/<name>.Str => $/<value>.Str;
        }
    }

}

