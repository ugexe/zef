# Actions for applying to Net::HTTP::Grammar
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
        # todo: we have rules for most known headers, so we should create a structure 
        # that matches the Match tree (i.e. $/<value> could be an array or hash, not always a string)
        make $/<name>.Str => $/<value>.Str;
    }
}
