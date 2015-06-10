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
        my $req = $!request.go;

        # In the future, $req.<body> should be streamed
        $!response = Zef::Net::HTTP::Response.new( 
            :header-chunk($req.<header>), 
            :body($req.<body>), 
        );
    }
}
