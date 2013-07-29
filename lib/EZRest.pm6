#!/usr/bin/env perl6

use JSON::Tiny;


class EZRest::Response {
  has %.headers is rw;
  has $.data    is rw;

  method make ( $pinksock ) {
    my ( $content, $flag, @chunker, $line , $data , $len);
    $data    = '';
    $content = '';
    $line    = '';
    $len     = 0;
    $flag    = 1;
    while ( $flag > 0 && ( @chunker = $pinksock.recv.split("\n") ) ) {
      if $flag == 1 { 
        $len = 1;
        for @chunker -> $lines {
          $line    = $lines.subst(/[\r]/, '');
          $flag = 2 , last if $line eq '';
          %.headers{ $line.split(':')[0] } = $line.split(':', 2)[1] if $line ne '';
          $len++;
        }
        @chunker.splice( 0 , $len ) if $flag == 2;
        $len = 0;
      }

      if $flag == 2 { #parse chunks
        for @chunker -> $lines {
          $line    = $lines.subst(/[\r]/, '');
          $len = :16( $line ) , next if $len == 0 && $line ne '';
          $flag = 0 if $len eq 0;
          $data ~= $line;
          $len  -= $line.chars;
        }
      }

    }    
    $.data = $data;
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
    $reqbody    ~= "Host: $host:$port\n";
    $reqbody    ~= "Accept: */*\n";
    $reqbody    ~= "Content-Type: application/json\n";
    $reqbody    ~= "Content-Length: {$data.chars}\n\n";
    $reqbody    ~= "$data";
    $pinksock.send( $reqbody );
    my $resp = EZRest::Response.new;
    $resp.make( $pinksock );
    $pinksock.close;
    return $resp;
  }
};

