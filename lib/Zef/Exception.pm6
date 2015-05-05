module Zef::Exception;

class X::Zef is Exception {
    has $.stage;
    has $.reason;
    has $.error;

    method new($stage, $reason is copy) {
        if $reason ~~ Failure {
            $.reason = $reason.exception.message;
        }
        self.bless(:$stage, :$reason)
    }

    method message {
        say "$.stage stage failed: $.reason";
    }
}

class X::Zef::Installation is Exception {
    has $.module;
    has $.path;

    submethod BUILD(:$!module!, :$!path) { }

    method message {
        say "{$!module} failed to install";
    }
}