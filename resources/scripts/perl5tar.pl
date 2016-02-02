use Archive::Tar;

if( $ARGV[0] eq '--list' ) {
    my $extractor = Archive::Tar->new();
    $extractor->read($ARGV[1]);
    print "$_\n" for( $extractor->list_files() );
}
elsif( $ARGV[0] ) {
    my $extractor = Archive::Tar->new();
    $extractor->read($ARGV[0]);
    $extractor->extract();
}
