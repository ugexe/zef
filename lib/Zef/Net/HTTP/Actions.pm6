# Actions for applying to Net::HTTP::Grammar

# todo: this all needs to be refactored

role Zef::Net::HTTP::Actions::Header::Allow {
    method Allow($/) {
        make $/<allow-value>.map(*.made).list;
    }

    method allow-value($/) {
        make $/<method>.made;
    }

    method method($/) {
        make $/.Str;
    }
}

role Zef::Net::HTTP::Actions::Header::Accept-Language {
    method Accept-Language($/) {
        make $/<accept-language-value>.map(*.made).list;
    }

    method accept-language-value($/) {
        if $/<weight> {
            make [tag => $/<language-range>.made, weight => $/<weight>.made];
        }
        else {
            make [tag => $/<language-range>.made];
        }
    }

    method language-range($/) {
        make $/<language-tag>.made;
    }

    method language-tag($/) {
        make $/.Str;
    }

    my method weight($/) {
        make $/<qvalue>.made;
    }
}

role Zef::Net::HTTP::Actions::Header::Accept-Encoding { 
    method Accept-Encoding($/) {
        make $/<accept-encoding-value>.map(*.made).list;
    }

    method accept-encoding-value($/) {
        if $/<weight> {
            make [coding => $/<codings>.Str, weight => $/<weight>.made];
        }
        else {
            make [coding => $/<codings>.Str];
        }
    }

    my method weight($/) {
        make $/<qvalue>.made;
    }

    method codings($/) {
        make $/.Str;
    } 
}

role Zef::Net::HTTP::Actions::Header::Accept { 
    method Accept($/) {
        make $/<accept-value>.map(*.made).list;
    }

    method accept-value($/) {
        if $/<accept-params> {
            make [range => $/<media-range>.made, $/<accept-params>.made];
        }
        else {
            make [range => $/<media-range>.made];
        }
    }

    method media-range($/) {
        if $/<parameter> {
            make [type => $/<type>.Str, subtype => $/<subtype>.Str, parameters => $/<parameter>.map(*.made).list];
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
            make [weight => $/<weight>.made, parameters => $/<accept-ext>.map(*.made).list];
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

role Zef::Net::HTTP::Actions::Header::Content-Type {
    method Content-Type($/) {
        make $<media-type>.made;
    }

    method media-type($/) {
        if $/<parameter> {
            make [type => $/<type>.Str, subtype => $/<subtype>.Str, parameters => [$/<parameter>.map(*.made).list.flat]];
        }
        else {
            make [type => $/<type>.Str, subtype => $/<subtype>.Str];            
        }
    }
}

role Zef::Net::HTTP::Actions::Header::Transfer-Encoding {
    method Transfer-Encoding($/) {
        make $<transfer-encoding-value>.map(*.made).list;
    }

    method transfer-encoding-value($/) {
        make $/<transfer-coding>.made;
    }

    method transfer-coding($/) {
        make $/.Str;
    }
}




class Zef::Net::HTTP::Actions::Response {
    also does Zef::Net::HTTP::Actions::Header::Allow;
    also does Zef::Net::HTTP::Actions::Header::Content-Type;
    also does Zef::Net::HTTP::Actions::Header::Transfer-Encoding;
}

class Zef::Net::HTTP::Actions::Request {
    also does Zef::Net::HTTP::Actions::Header::Accept;
    also does Zef::Net::HTTP::Actions::Header::Accept-Encoding;
    also does Zef::Net::HTTP::Actions::Header::Accept-Language;
    also does Zef::Net::HTTP::Actions::Header::Connection;

}


# todo: eventually phase this out and use the Reponse and Request actions directly.
# This just makes it easier for testing some initial things.
class Zef::Net::HTTP::Actions {
    also is Zef::Net::HTTP::Actions::Request;
    also is Zef::Net::HTTP::Actions::Response;

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
            make $/<name>.Str => $/<value>.ast;
        }
        else {
            make $/<name>.Str => $/<value>.Str;
        }
    }


    # reponse
    method Location($/) {
        make $/.Str;
    }
}

