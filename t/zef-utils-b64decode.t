use Zef::Utils;
use Test;

plan 12;

is Zef::Utils.b64decode(""), '', 'decoding the empty string';
is Zef::Utils.b64decode("QQ=="), 'A', 'decoding "A"';
is Zef::Utils.b64decode("QWI="), 'Ab', 'decoding "Ab"';
is Zef::Utils.b64decode('QWJj'), "Abc", 'decoding "Abc"';
is Zef::Utils.b64decode('QWJjZA=='), "Abcd", 'decoding "Abcd"';
is Zef::Utils.b64decode('UGVybA=='), "Perl", 'decoding "Perl"';
is Zef::Utils.b64decode('UGVybDY='), "Perl6", 'decoding "Perl6"';
is Zef::Utils.b64decode('QW5vdGhlciB0ZXN0IQ=='), "Another test!", 'decoding "Another test!"';
is Zef::Utils.b64decode('dXNlcm5hbWU6dGhpc2lzbm90bXlwYXNzd29yZA=='), "username:thisisnotmypassword", 'decoding "username:thisisnotmypassword"';
is_deeply Zef::Utils.b64decode('AA==').contents, Buf.new(0).contents, 'decode Test on NULL/0 byte';
is_deeply Zef::Utils.b64decode('AQ==').contents, Buf.new(1).contents, 'decode Test on byte value 1';
is_deeply Zef::Utils.b64decode('/w==').contents, Buf.new(255).contents, 'decode Test on byte value 255';
