class Zef::Net::HTTP::Actions {
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
        make $/<name>.Str => $/<value>.Str;
    }
}
