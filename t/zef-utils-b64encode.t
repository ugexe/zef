use Zef::Utils;
use Test;

plan 12;

is Zef::Utils.b64encode(""), '', 'Encoding the empty string';
is Zef::Utils.b64encode("A"), 'QQ==', 'Encoding "A"';
is Zef::Utils.b64encode("Ab"), 'QWI=', 'Encoding "Ab"';
is Zef::Utils.b64encode("Abc"), 'QWJj', 'Encoding "Abc"';
is Zef::Utils.b64encode("Abcd"), 'QWJjZA==', 'Encoding "Abcd"';
is Zef::Utils.b64encode("Perl"), 'UGVybA==', 'Encoding "Perl"';
is Zef::Utils.b64encode("Perl6"), 'UGVybDY=', 'Encoding "Perl6"';
is Zef::Utils.b64encode("Another test!"), 'QW5vdGhlciB0ZXN0IQ==', 'Encoding "Another test!"';
is Zef::Utils.b64encode("username:thisisnotmypassword"), 'dXNlcm5hbWU6dGhpc2lzbm90bXlwYXNzd29yZA==', 'Encoding "username:thisisnotmypassword"';
is Zef::Utils.b64encode(Buf.new(0)), 'AA==', 'encode Test on NULL/0 byte';
is Zef::Utils.b64encode(Buf.new(1)), 'AQ==', 'encode Test on byte value 1';
is Zef::Utils.b64encode(Buf.new(255)), '/w==', 'encode Test on byte value 255';
