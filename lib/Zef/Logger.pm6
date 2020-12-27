use v6;

unit module Zef::Logger;

my $logger = Nil;

our sub get-logger() {
    $logger = Supplier.new unless $logger;
    return $logger;
}

our sub register-listener(&f) {
    get-logger.Supply.tap(&f);
}

