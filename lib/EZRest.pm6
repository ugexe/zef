#!/usr/bin/env perl6

use JSON::Tiny;


class EZRest::Response {
  has Int $.status     is rw;
  has     $.data       is rw;
  has Str %.headers    is rw;
  has Str $.httpvs     is rw;
  has Str $.statustext is rw;

  method make ( $pinksock ) {
    my Str $line    = '';
    my Int $len     = 0;
    my Int $flag    = 1;
    $.data          = '';
    $.status        = -1;
    $.statustext    = '';
    $.httpvs        = '';

    while  $flag > 0 && my Str @chunker = $pinksock.recv.split("\n") {
      if $flag == 1 { 
        $len = 1;

        my @s = @chunker.unshift.split(' ', 3);
        $.status     = @s[1].Int;
        $.statustext = @s[2];
        $.httpvs     = @s[0];

        for @chunker -> Str $lines {
          $line = $lines.subst(/[\r]/, '');
          $flag = 2 , last if $line eq '';
          %.headers{ $line.split(':')[0] } = $line.split(':', 2)[1].trim if $line ne '';
          $len++;
        }
        @chunker.splice( 0 , $len ) if $flag == 2;
        $len = 0;
      }

      if $flag == 2 { #parse chunks
        $len = -1 if not %.headers<Transfer-Encoding>.defined or %.headers<Transfer-Encoding> ne 'chunked'; 
        $len = :10( %.headers<Content-Length> ) if ( ( %.headers<Transfer-Encoding>.defined && 
                                                   %.headers<Transfer-Encoding> ne 'chunked' ) ||
                                                   %.headers<Content-Length>.defined ) &&
                                                   $len == 0;
        
        $flag = 0, $.data = @chunker.join("\n") if $len == -1;
        for @chunker -> Str $lines {
          $line   = $lines.trim;
          $len    = :16( $line ) , next if $len == 0 && $line ne '';
          $flag   = 0 , last if $len <= 0;
          $.data ~= $lines ~ ( $len == 0 ?? "\n" !! '' );
          $len   -= $lines.chars + ( $len == 0 ?? 1 !! 0 );
        }
      }
    }    
  }
};

#this package is local to ZEF only
class EZRest {
  method req ( :$host = 'zef.pm' , :$endpoint = '/rest/' , Str :$data ) {
    my @urld     = $host.split(':');
    @urld.push(80) if @urld[@urld.elems-1] !~~ /\d+/;
    my $rport    = +( @urld.pop );
    my $rhost    = @urld.join(':'); 
    my $pinksock = IO::Socket::INET.new( :host($rhost) , :port($rport) );
    my $datalen  = $data.chars; # $data.encode('UTF-8').bytes; 
    my $reqbody  = qq:to/END/
POST $endpoint HTTP/1.1
Host: $rhost:$rport
Accept: */*
Content-Type: application/json
Content-Length: {$datalen}

END
;
    $reqbody = $reqbody.subst(rx{ "\n" }, "\r\n", :g) ~ $data;
    $pinksock.send( $reqbody );
    my $resp = EZRest::Response.new;
    $resp.make( $pinksock );
    $pinksock.close;
    return $resp;
  }
};
