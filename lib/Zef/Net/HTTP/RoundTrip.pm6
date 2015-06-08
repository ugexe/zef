use Zef::Net::HTTP::Transport;
use Zef::Net::HTTP::Request;
use Zef::Net::HTTP::Response;

class Zef::Net::HTTP::RoundTrip {
    has Zef::Net::HTTP::Request  $.request;
    has Zef::Net::HTTP::Response $.response;

    submethod BUILD(:$!request) {
        $!request does Zef::Net::HTTP::Transport;
    }

    method init(Zef::Net::HTTP::RoundTrip:D:) {
        my $stream   = $!request.get;
        $!response = Zef::Net::HTTP::Response.new( :message($stream.list) );
    }
}
