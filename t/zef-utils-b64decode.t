use Zef::Utils;
use Test;

plan 12;

ok Zef::Utils.b64decode("", :decode) eq '', 'decoding the empty string';
ok Zef::Utils.b64decode("QQ==", :decode) eq 'A', 'decoding "A"';
ok Zef::Utils.b64decode("QWI=", :decode) eq 'Ab', 'decoding "Ab"';
ok Zef::Utils.b64decode('QWJj', :decode) eq "Abc", 'decoding "Abc"';
ok Zef::Utils.b64decode('QWJjZA==', :decode) eq "Abcd", 'decoding "Abcd"';
ok Zef::Utils.b64decode('UGVybA==', :decode) eq "Perl", 'decoding "Perl"';
ok Zef::Utils.b64decode('UGVybDY=', :decode) eq "Perl6", 'decoding "Perl6"';
ok Zef::Utils.b64decode('QW5vdGhlciB0ZXN0IQ==', :decode) eq "Another test!", 'decoding "Another test!"';
ok Zef::Utils.b64decode('dXNlcm5hbWU6dGhpc2lzbm90bXlwYXNzd29yZA==', :decode) eq "username:thisisnotmypassword", 'decoding "username:thisisnotmypassword"';
is_deeply Zef::Utils.b64decode('AA=='), Buf.new(0), 'decode Test on NULL/0 byte';
is_deeply Zef::Utils.b64decode('AQ=='), Buf.new(1), 'decode Test on byte value 1';
is_deeply Zef::Utils.b64decode('/w=='), Buf.new(255), 'decode Test on byte value 255';
