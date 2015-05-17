use v6;
# Internet Message Format

use Zef::Grammars::HTTP::RFC6854;


role Zef::Grammars::HTTP::RFC5322::Core does Zef::Grammars::HTTP::RFC6854::Core {

    token quoted-pair { [\\ [<.VCHAR> || <.WSP>]] || <.obs-qp> }

    token FWS { [[<.WSP>* <.CRLF>]? <.WSP>+] || <.obs-FWS> }

    token ctext { <[\c[33]..\c[39]\c[42]..\c[91]\c[93]..\c[126]]> || <.obs-ctext> }

    token ccontent { <.ctext> || <.quoted-pair> || <.comment> }
    token comment { '(' [<.FWS>? <.ccontent>]* <.FWS>? ')' }

    token CFWS { [[<.FWS>? <.comment>]+ <.FWS>?] || <.FWS> }

    token atext { 
        || <.ALPHA>  
        || <.DIGIT>
        || < ! # $ %  & ' * + - | = ? ^ _ ` { | } ~ >
    }

    token atom { <.CFWS>? <.atext>+ <.CFWS>? }

    token dot-atom-text { <.atext>+ ['.' <.atext>+]* }
    token dot-atom { <.CFWS>? <.dot-atom-text> <.CFWS>? }

    token qtext { <[\c[33]\c[35]..\c[91]\c[93]..\c[126]]> || <.obs-qtext> }

    token qcontent { <.qtext> || <.quoted-pair> }

    token quoted-string { <.CFWS>? '"' [<.FWS>? <.qcontent>]* <.FWS>? '"' <.CFWS>? }

    token word { <.atom> || <.quoted-string> }

    token phrase { <.word>+ || <.obs-phrase> }

    token unstructured { [[<.FWS>? <.VCHAR>]* <.WSP>*] || <.obs-unstruct> }

    token date-time { [<.day-of-week> ',']? <.date> <.time> <.CFWS>? }

    token day-of-week { [<.FWS>? <.day-name>] || <.obs-day-of-week> }

    token day-name { 'Mon' || 'Tue' || 'Wed' || 'Thu' || 'Fri' || 'Sat' || 'Sun' }

    token date { <day> <month> <year> }

    token day { [<.FWS>? [<.DIGIT> ** 1..2] <.FWS>] || <.obs-day> }

    token month { 'Jan' || 'Feb' || 'Mar' || 'Apr' || 'May' || 'Jun' || 'Jul' || 'Aug' || 'Sep' || 'Oct' || 'Nov' || 'Dec'}

    token year { 
        ||  [   
            <.FWS> 
            <.DIGIT> ** 4  # i.e.
            <.DIGIT>*      # <.DIGIT> ** 4..Inf
            <.FWS>
            ] 
        ||  <.obs-year> 
    }

    token time { <.time-of-day> <.zone> }

    token time-of-day { <.hour> ':' <.minute> [':' <.second>]? }

    token hour { [<.DIGIT> ** 2] || <.obs-hour> }

    token minute { [<.DIGIT> ** 2] || <.obs-minute> }

    token second { [<.DIGIT> ** 2] || <.obs-second> }

    token zone { [<.FWS> ['+' || '-'] [<.DIGIT> ** 4]] || <.obs-zone> }

    token address { <mailbox> || <group> }

    token mailbox { <name-addr> || <addr-spec> }

    token name-addr { <display-name>? <angle-addr> }

    token angle-addr { [<.CFWS>? '<' <addr-spec> '>' <.CFWS>?] || <.obs-angle-addr> }

    token group { <display-name> ':' <group-list>? ';' <.CFWS>? }

    token display-name { <.phrase> }

    token mailbox-list { [<mailbox> *%% ','] || <obs-mbox-list> }

    token address-list { [<address> *%% ','] || <obs-addr-list> }

    token group-list { <mailbox-list> || <.CFWS> || <obs-group-list> }

    token addr-spec { <.local-part> '@' <.domain> }

    token local-part { <.dot-atom> || <.quoted-string> || <.obs-local-part> }

    token domain { <.dot-atom> || <.domain-literal> || <.obs-domain> }

    token domain-literal { <.CFWS>? '[' [<.FWS>? <.dtext>]* <.FWS>? ']' <.CFWS>? }

    token dtext { <[\c[33]..\c[90]\c[94]..\c[126]]> || <.obs-dtext> }

    token message { [<fields> || $<fields>=<.obs-fields>] [<.CRLF> <body>]? }

    token body { [[[<.text> ** 0..998] <.CRLF>]* [<.text> ** 0..998]] || <.obs-body> }

    token text { <[\c[1]..\c[9]\c[11,12]\c[14]..\c[127]]> }

    token fields {
        [
        <trace>
            [   
            || <resent-date>
            || <resent-from>
            || <resent-sender>
            || <resent-to>
            || <resent-cc>
            || <resent-bcc>
            || <resent-msg-id>
            ]*
        ]*
        [
        || <orig-date>
        || <from>
        || <sender>
        || <reply-to>
        || <to>
        || <cc>
        || <bcc>
        || <message-id>
        || <in-reply-to>
        || <references>
        || <subject>
        || <comments>
        || <keywords>
        || <optional-field>
        ]*
    }

    token orig-date { "Date:" <date-time> <.CRLF> }

    token from { "From:" <mailbox-list> <.CRLF> }

    token sender { "Sender:" <mailbox> <.CRLF> }

    token reply-to { "Reply-To:" <address-list> <.CRLF> }

    token to { "To:" <address-list> <.CRLF> }

    token cc { "Cc:" <address-list> <.CRLF> }

    token bcc { "Bcc:" [<address-list> || <.CFWS>]? <.CRLF> }

    token message-id { "Message-ID:" <msg-id> <.CRLF> }

    token in-reply-to { "In-Reply-To:" <msg-id>+ <.CRLF> }

    token references { "References:" <msg-id>+ <.CRLF> }

    token msg-id { <.CFWS>? '<' <.id-left> '@' <.id-right> '>' <.CFWS>? }

    token id-left  { <.dot-atom-text> || <.obs-id-left> }

    token id-right { <.dot-atom-text> || <.no-fold-literal> || <.obs-id-left> }

    token no-fold-literal { '[' <.dtext>* ']' }

    token subject { "Subject:" $<value>=<.unstructured> <.CRLF> }

    token comments { "Comments:" (<.unstructured>) <.CRLF> }

    token keywords { "Keywords:" [<phrase> *%% ','] <.CRLF> }

    token resent-date { "Resent-Date:" <.date-time> <.CRLF> }

    token resent-from { "Resent-From:" <.mailbox-list> <.CRLF> }

    token resent-sender { "Resent-Sender:" <.mailbox> <.CRLF> }

    token resent-to { "Resent-To:" <.address-list> <.CRLF> }

    token resent-cc { "Resent-Cc:" <.address-list> <.CRLF> }

    token resent-bcc { "Resent-Bcc:" [<.address-list> || <.CFWS>] <.CRLF> }

    token resent-msg-id { "Resent-Message-ID:" <.msg-id> <.CRLF> }

    token trace { <return>? <received>+ }

    token return { "Return-Path:" <path> <.CRLF> }

    token path { <.angle-addr> || [<.CFWS>? '<' <.CFWS>? '>' <.CFWS>?] }

    # Errata ID: 3979 
    token received { "Received:" [<received-token>+ || <.CFWS>] ';' <date-time> <.CRLF> }

    token received-token { <.word> || <.angle-addr> || <.addr-spec> || <.domain> }

    token optional-field { $<field>=<.field-name> ':' $<value>=<.unstructured> <.CRLF> }

    token field-name { <.ftext>+ }

    token ftext { <[\c[33]..\c[57]\c[59]..\c[126]]> }

    token obs-NO-WS-CTL { <[\c[1]..\c[8]\c[11,12]\c[14]..\c[31]\c[127]]> }

    token obs-ctext { <.obs-NO-WS-CTL> }

    token obs-qtext { <.obs-NO-WS-CTL> }

    token obs-utext { \c[0] || <.obs-NO-WS-CTL> || <.VCHAR> }

    token obs-qp { \\ [\c[0] || <.obs-NO-WS-CTL> || <.LF> || <.CR>] }

    token obs-body { [[<.LF>* <.CR>* [[\c[0] || <.text>] <.LF>* <.CR>*]*] || <.CRLF>]* }

    #Errata ID: 1905
    token obs-unstruct { [[<.CR>* [<.obs-utext> || <.FWS>]+] || <.LF>+ ]* <.CR>* }

    token obs-phrase { <.word> [<.word> || '.' || <.CFWS>]* }

    token obs-phrase-list { [<.phrase> || <.CFWS>]? [',' [<.phrase> || <.CFWS>]?]* }

    # Errata ID: 1908
    token obs-FWS { [<.CRLF>? <.WSP>]+ }

    token obs-day-of-week { <.CFWS>? <.day-name> <.CFWS>? }

    token obs-day { <.CFWS>? <.DIGIT> ** 1..2 <.CFWS>? }

    token obs-year { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    token obs-hour { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    token obs-minute { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    token obs-second { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    token obs-zone { 
        || 'UT'  || 'GMT'
        || 'EST' || 'EDT'
        || 'CST' || 'CDT'
        || 'MST' || 'MDT'
        || 'PST' || 'PDT'
        || <[\c[65]..\c[73]]>
        || <[\c[75]..\c[90]]>
        || <[\c[97]..\c[105]]>
        || <[\c[107]..\c[122]]>
    }

    token obs-angle-addr { <.CFWS>? '<' <.obs-route> <.addr-spec> '>' <.CFWS>? }

    token obs-route { <.obs-domain-list> ':'}

    token obs-domain-list { [<.CFWS>? || ',']* '@' <.domain> [',' <.CFWS>? ['@' <.domain>]]* }

    token obs-mbox-list { [<.CFWS>? ',']* <.mailbox> [',' [<.mailbox> || <.CFWS>]?]* }

    token obs-addr-list { [<.CFWS>? ',']* <.address> [',' [<.address> || <.CFWS>]?]* }

    token obs-group-list { [<.CFWS>? ',']+ <.CFWS>? }

    token obs-local-part { <.word> ['.' <.word>]* }

    token obs-domain { <.atom> ['.' <.atom>]* }

    token obs-dtext { <.obs-NO-WS-CTL> || <.quoted-pair> }

    token obs-fields {
        [
        || <obs-return>
        || <obs-received>
        || <obs-orig-date>
        || <obs-from>
        || <obs-sender>
        || <obs-reply-to>
        || <obs-to>
        || <obs-cc>
        || <obs-bcc>
        || <obs-message-id>
        || <obs-in-reply-to>
        || <obs-references>
        || <obs-subject>
        || <obs-comments>
        || <obs-keywords>
        || <obs-resent-date>
        || <obs-resent-from>
        || <obs-resent-send>
        || <obs-resent-rply>
        || <obs-resent-to>
        || <obs-resent-cc>
        || <obs-resent-bcc>
        || <obs-resent-mid>
        || <obs-optional>
        ]*
    }

    token obs-orig-date { "Date" <.WSP>* ':' <.date-time> <.CRLF> }

    token obs-from { "From" <.WSP>* ':' <.mailbox-list> <.CRLF> }

    token obs-sender { "Sender" <.WSP>* ':' <.mailbox> <.CRLF> }

    token obs-reply-to { "Reply-To" <.WSP>* ':' <.address-list> <.CRLF> }

    token obs-to { "To" <.WSP>* ':' <.address-list> <.CRLF> }

    token obs-cc { "Cc" <.WSP>* ':' <.address-list> <.CRLF> }

    token obs-bcc { "Bcc" <.WSP>* ':' [<.address-list> || [[<.CFWS>? ',']* <.CFWS>?]] <.CRLF> }

    token obs-message-id { "Message-ID" <.WSP>* ':' <.msg-id> <.CRLF> }

    token obs-in-reply-to { "In-Reply-To" <.WSP>* ':' [<.phrase> || <.msg-id>] <.CRLF> }

    token obs-references { "References" <.WSP>* ':' [<.phrase> || <.msg-id>] <.CRLF> }

    token obs-id-left { <.local-part> }

    token obs-id-right { <.domain> }

    token obs-subject { "Subject" <.WSP>* ':' <.unstructured> <.CRLF> }

    token obs-comments { "Comments" <.WSP>* ':' <.unstructured> <.CRLF> }

    token obs-keywords { "Keywords" <.WSP>* ':' <.obs-phrase-list> <.CRLF> }

    token obs-resent-from { "Resent-From" <.WSP>* ':' <.mailbox-list> <.CRLF> }

    token obs-resent-send { "Resent-Sender" <.WSP>* ':' <.mailbox> <.CRLF> }

    token obs-resent-date { "Resent-Date" <.WSP>* ':' <.date-time> <.CRLF> }

    token obs-resent-to { "Resent-To" <.WSP>* ':' <.address-list> <.CRLF> }

    token obs-resent-cc { "Resent-Cc" <.WSP>* ':' <.address-list> <.CRLF> }

    token obs-resent-bcc { "Resent-Bcc" <.WSP>* ':' [<.address-list> || [[<.CFWS>? ',']* <.CRLF>?]] <.CRLF> }

    token obs-resent-mid { "Resent-Message-ID" <.WSP>* ':' <.msg-id> <.CRLF> }

    token obs-resent-rply { "Resent-Reply-To" <.WSP>* ':' <.address-list> <.CRLF> }

    token obs-return { "Return-Path" <.WSP>* ':' <.path> <.CRLF> }

    # Errata ID: 3979
    token obs-received { "Received" <.WSP>* ':' [<.received-token>+ || <.CFWS>] <.CRLF> }

    token obs-optional { <.field-name> <.WSP>* ':' <.unstructured> <.CRLF> }
}


grammar Zef::Grammars::HTTP::RFC5322 does Zef::Grammars::HTTP::RFC5322::Core {
    # todo
    token TOP {
        <message>
    }
}