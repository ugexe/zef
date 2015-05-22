use v6;
# Update to Internet Message Format to Allow Group Syntax in the "From:" and "Sender:" Header Fields

use Zef::Grammars::HTTP::RFC4234;

role Zef::Grammars::HTTP::RFC6854::Core does Zef::Grammars::HTTP::RFC4234::Core {
    token from     { "From:" [<mailbox-list> || <address-list>] <.CRLF> }
    token sender   { "Sender:" [<mailbox> || <address>] <.CRLF>         }
    token reply-to { "Reply-To:" <address-list> <.CRLF>                 }

    token resent-from   { "Resent-From:" [<mailbox-list> || <address-list>] <.CRLF> }
    token resent-sender { "Resent-Sender:" [<mailbox> || <address>] <.CRLF>         }
}

grammar Zef::Gramars::HTTP::RFC6854 does Zef::Grammars::HTTP::RFC6854::Core {
    token TOP { <from> <sender> <reply-to> <resent-from>? <resent-sender>? }
}