#!/usr/bin/env perl6

use JSON::Tiny;


class EZRest::Response {
  has Int $.status     is rw;
  has Str $.data       is rw;
  has Str %.headers    is rw;
  has Str $.httpvs     is rw;
  has Str $.statustext is rw;

  method make ( $pinksock ) {
    my Int $len     = 0;
    my Int $flag    = 1;
    $.data;
    $.status        = -1;
    $.statustext;
    $.httpvs;

    while  $flag > 0 && my Str @chunker = $pinksock.recv.split("\n") {
      my Str $line;

      if $flag == 1 { 
        $len = 1;
        for @chunker -> Str $lines {
          map {   $.status      = :10( $_[1] );
                  $.statustext  = $_[2];
                  $.httpvs      = $_[0];
          } $lines.split(' ', 3), next unless $.status;

          $line = $lines.subst(/[\r]/, '');
          $flag = 2 , last if $line eq '';
          %.headers{ $line.split(':')[0] } = $line.split(':', 2)[1].trim if $line ne '';
          $len++;
        }
        @chunker.splice( 0 , $len ) if $flag == 2;
        $len = 0;
      }

      if $flag == 2 { #parse chunks
        $len = %.headers<Content-Length> if %.headers<Transfer-Encoding>.defined && 
                                            %.headers<Transfer-Encoding> ne 'chunked' &&
                                            %.headers<Content-Length>.defined;

        for @chunker -> Str $lines {
          $line  = $lines.subst(/[\r]/, '');
          $len   = :16( $line ) , next if $len == 0 && $line ne '';
          $flag  = 0 if $len eq 0;
          $.data ~= $line;
          $len  -= $line.chars;
        }
      }

    }    
  }
};

#this package is local to ZEF only
class EZRest {
  method req ( :$url = 'zef.pm' , :$endpoint = '/rest/' , :$data ) {
    my @urld     = $url.split(':');
    @urld.push(80) if @urld[@urld.elems-1] !~~ /\d+/;
    my $port     = +( @urld.pop );
    my $host     = @urld.join(':'); 
    my $pinksock = IO::Socket::INET.new( :$host , :$port );
    my $reqbody  = "POST $endpoint HTTP/1.1\n";
                 ~ "Host: $host:$port\n";
                 ~ "Accept: */*\n";
                 ~ "Content-Type: application/json\n";
                 ~ "Content-Length: {$data.chars}\n\n";
                 ~ "$data";
    $pinksock.send( $reqbody );
    my $resp = EZRest::Response.new;
    $resp.make( $pinksock );
    $pinksock.close;
    return $resp;
  }
};

