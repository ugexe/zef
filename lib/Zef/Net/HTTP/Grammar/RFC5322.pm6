# Internet Message Format

role Zef::Net::HTTP::Grammar::RFC5322 {

    my token quoted-pair { [\\ [<.VCHAR> || <.WSP>]] || <.obs-qp> }

    my token FWS { [[<.WSP>* <.CRLF>]? <.WSP>+] || <.obs-FWS> }

    my token ctext { <[\c[33]..\c[39]\c[42]..\c[91]\c[93]..\c[126]]> || <.obs-ctext> }

    my token ccontent { <.ctext> || <.quoted-pair> || <.comment> }
    my token comment { '(' [<.FWS>? <.ccontent>]* <.FWS>? ')' }

    my token CFWS { [[<.FWS>? <.comment>]+ <.FWS>?] || <.FWS> }

    my token atext { 
        || <.ALPHA>  
        || <.DIGIT>
        || < ! # $ %  & ' * + - | = ? ^ _ ` { | } ~ >
    }

    my token atom { <.CFWS>? <.atext>+ <.CFWS>? }

    my token dot-atom-text { <.atext>+ ['.' <.atext>+]* }
    my token dot-atom { <.CFWS>? <.dot-atom-text> <.CFWS>? }

    my token qtext { <[\c[33]\c[35]..\c[91]\c[93]..\c[126]]> || <.obs-qtext> }

    my token qcontent { <.qtext> || <.quoted-pair> }

    my token quoted-string { <.CFWS>? '"' [<.FWS>? <.qcontent>]* <.FWS>? '"' <.CFWS>? }

    my token word { <.atom> || <.quoted-string> }

    my token phrase { <.word>+ || <.obs-phrase> }

    my token unstructured { [[<.FWS>? <.VCHAR>]* <.WSP>*] || <.obs-unstruct> }

    my token date-time { [<.day-of-week> ',']? <.date> <.time> <.CFWS>? }

    my token day-of-week { [<.FWS>? <.day-name>] || <.obs-day-of-week> }

    my token day-name { 'Mon' || 'Tue' || 'Wed' || 'Thu' || 'Fri' || 'Sat' || 'Sun' }

    my token date { <day> <month> <year> }

    my token day { [<.FWS>? [<.DIGIT> ** 1..2] <.FWS>] || <.obs-day> }

    my token month { 'Jan' || 'Feb' || 'Mar' || 'Apr' || 'May' || 'Jun' || 'Jul' || 'Aug' || 'Sep' || 'Oct' || 'Nov' || 'Dec'}

    my token year { 
        ||  [   
            <.FWS> 
            <.DIGIT> ** 4  # i.e.
            <.DIGIT>*      # <.DIGIT> ** 4..Inf
            <.FWS>
            ] 
        ||  <.obs-year> 
    }

    my token time { <.time-of-day> <.zone> }

    my token time-of-day { <.hour> ':' <.minute> [':' <.second>]? }

    my token hour { [<.DIGIT> ** 2] || <.obs-hour> }

    my token minute { [<.DIGIT> ** 2] || <.obs-minute> }

    my token second { [<.DIGIT> ** 2] || <.obs-second> }

    my token zone { [<.FWS> ['+' || '-'] [<.DIGIT> ** 4]] || <.obs-zone> }

    my token address { <mailbox> || <group> }

    my token mailbox { <name-addr> || <addr-spec> }

    my token name-addr { <display-name>? <angle-addr> }

    my token angle-addr { [<.CFWS>? '<' <addr-spec> '>' <.CFWS>?] || <.obs-angle-addr> }

    my token group { <display-name> ':' <group-list>? ';' <.CFWS>? }

    my token display-name { <.phrase> }

    my token mailbox-list { [<mailbox> *%% ','] || <obs-mbox-list> }

    my token address-list { [<address> *%% ','] || <obs-addr-list> }

    my token group-list { <mailbox-list> || <.CFWS> || <obs-group-list> }

    my token addr-spec { <.local-part> '@' <.domain> }

    my token local-part { <.dot-atom> || <.quoted-string> || <.obs-local-part> }

    my token domain { <.dot-atom> || <.domain-literal> || <.obs-domain> }

    my token domain-literal { <.CFWS>? '[' [<.FWS>? <.dtext>]* <.FWS>? ']' <.CFWS>? }

    my token dtext { <[\c[33]..\c[90]\c[94]..\c[126]]> || <.obs-dtext> }

    my token message { [<fields> || $<fields>=<.obs-fields>] [<.CRLF> <body>]? }

    my token body { [[[<.text> ** 0..998] <.CRLF>]* [<.text> ** 0..998]] || <.obs-body> }

    my token text { <[\c[1]..\c[9]\c[11,12]\c[14]..\c[127]]> }

    my token fields {
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

    my token orig-date { "Date:" <date-time> <.CRLF> }

    my token from { "From:" <mailbox-list> <.CRLF> }

    my token sender { "Sender:" <mailbox> <.CRLF> }

    my token reply-to { "Reply-To:" <address-list> <.CRLF> }

    my token to { "To:" <address-list> <.CRLF> }

    my token cc { "Cc:" <address-list> <.CRLF> }

    my token bcc { "Bcc:" [<address-list> || <.CFWS>]? <.CRLF> }

    my token message-id { "Message-ID:" <msg-id> <.CRLF> }

    my token in-reply-to { "In-Reply-To:" <msg-id>+ <.CRLF> }

    my token references { "References:" <msg-id>+ <.CRLF> }

    my token msg-id { <.CFWS>? '<' <.id-left> '@' <.id-right> '>' <.CFWS>? }

    my token id-left  { <.dot-atom-text> || <.obs-id-left> }

    my token id-right { <.dot-atom-text> || <.no-fold-literal> || <.obs-id-left> }

    my token no-fold-literal { '[' <.dtext>* ']' }

    my token subject { "Subject:" $<value>=<.unstructured> <.CRLF> }

    my token comments { "Comments:" (<.unstructured>) <.CRLF> }

    my token keywords { "Keywords:" [<phrase> *%% ','] <.CRLF> }

    my token resent-date { "Resent-Date:" <.date-time> <.CRLF> }

    my token resent-from { "Resent-From:" <.mailbox-list> <.CRLF> }

    my token resent-sender { "Resent-Sender:" <.mailbox> <.CRLF> }

    my token resent-to { "Resent-To:" <.address-list> <.CRLF> }

    my token resent-cc { "Resent-Cc:" <.address-list> <.CRLF> }

    my token resent-bcc { "Resent-Bcc:" [<.address-list> || <.CFWS>] <.CRLF> }

    my token resent-msg-id { "Resent-Message-ID:" <.msg-id> <.CRLF> }

    my token trace { <return>? <received>+ }

    my token return { "Return-Path:" <path> <.CRLF> }

    my token path { <.angle-addr> || [<.CFWS>? '<' <.CFWS>? '>' <.CFWS>?] }

    # Errata ID: 3979 
    my token received { "Received:" [<received-token>+ || <.CFWS>] ';' <date-time> <.CRLF> }

    my token received-token { <.word> || <.angle-addr> || <.addr-spec> || <.domain> }

    my token optional-field { $<field>=<.field-name> ':' $<value>=<.unstructured> <.CRLF> }

    my token field-name { <.ftext>+ }

    my token ftext { <[\c[33]..\c[57]\c[59]..\c[126]]> }

    my token obs-NO-WS-CTL { <[\c[1]..\c[8]\c[11,12]\c[14]..\c[31]\c[127]]> }

    my token obs-ctext { <.obs-NO-WS-CTL> }

    my token obs-qtext { <.obs-NO-WS-CTL> }

    my token obs-utext { \c[0] || <.obs-NO-WS-CTL> || <.VCHAR> }

    my token obs-qp { \\ [\c[0] || <.obs-NO-WS-CTL> || <.LF> || <.CR>] }

    my token obs-body { [[<.LF>* <.CR>* [[\c[0] || <.text>] <.LF>* <.CR>*]*] || <.CRLF>]* }

    #Errata ID: 1905
    my token obs-unstruct { [[<.CR>* [<.obs-utext> || <.FWS>]+] || <.LF>+ ]* <.CR>* }

    my token obs-phrase { <.word> [<.word> || '.' || <.CFWS>]* }

    my token obs-phrase-list { [<.phrase> || <.CFWS>]? [',' [<.phrase> || <.CFWS>]?]* }

    # Errata ID: 1908
    my token obs-FWS { [<.CRLF>? <.WSP>]+ }

    my token obs-day-of-week { <.CFWS>? <.day-name> <.CFWS>? }

    my token obs-day { <.CFWS>? <.DIGIT> ** 1..2 <.CFWS>? }

    my token obs-year { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    my token obs-hour { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    my token obs-minute { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    my token obs-second { <.CFWS>? <.DIGIT> ** 2 <.CFWS>? }

    my token obs-zone { 
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

    my token obs-angle-addr { <.CFWS>? '<' <.obs-route> <.addr-spec> '>' <.CFWS>? }

    my token obs-route { <.obs-domain-list> ':'}

    my token obs-domain-list { [<.CFWS>? || ',']* '@' <.domain> [',' <.CFWS>? ['@' <.domain>]]* }

    my token obs-mbox-list { [<.CFWS>? ',']* <.mailbox> [',' [<.mailbox> || <.CFWS>]?]* }

    my token obs-addr-list { [<.CFWS>? ',']* <.address> [',' [<.address> || <.CFWS>]?]* }

    my token obs-group-list { [<.CFWS>? ',']+ <.CFWS>? }

    my token obs-local-part { <.word> ['.' <.word>]* }

    my token obs-domain { <.atom> ['.' <.atom>]* }

    my token obs-dtext { <.obs-NO-WS-CTL> || <.quoted-pair> }

    my token obs-fields {
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

    my token obs-orig-date { "Date" <.WSP>* ':' <.date-time> <.CRLF> }

    my token obs-from { "From" <.WSP>* ':' <.mailbox-list> <.CRLF> }

    my token obs-sender { "Sender" <.WSP>* ':' <.mailbox> <.CRLF> }

    my token obs-reply-to { "Reply-To" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-to { "To" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-cc { "Cc" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-bcc { "Bcc" <.WSP>* ':' [<.address-list> || [[<.CFWS>? ',']* <.CFWS>?]] <.CRLF> }

    my token obs-message-id { "Message-ID" <.WSP>* ':' <.msg-id> <.CRLF> }

    my token obs-in-reply-to { "In-Reply-To" <.WSP>* ':' [<.phrase> || <.msg-id>] <.CRLF> }

    my token obs-references { "References" <.WSP>* ':' [<.phrase> || <.msg-id>] <.CRLF> }

    my token obs-id-left { <.local-part> }

    my token obs-id-right { <.domain> }

    my token obs-subject { "Subject" <.WSP>* ':' <.unstructured> <.CRLF> }

    my token obs-comments { "Comments" <.WSP>* ':' <.unstructured> <.CRLF> }

    my token obs-keywords { "Keywords" <.WSP>* ':' <.obs-phrase-list> <.CRLF> }

    my token obs-resent-from { "Resent-From" <.WSP>* ':' <.mailbox-list> <.CRLF> }

    my token obs-resent-send { "Resent-Sender" <.WSP>* ':' <.mailbox> <.CRLF> }

    my token obs-resent-date { "Resent-Date" <.WSP>* ':' <.date-time> <.CRLF> }

    my token obs-resent-to { "Resent-To" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-resent-cc { "Resent-Cc" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-resent-bcc { "Resent-Bcc" <.WSP>* ':' [<.address-list> || [[<.CFWS>? ',']* <.CRLF>?]] <.CRLF> }

    my token obs-resent-mid { "Resent-Message-ID" <.WSP>* ':' <.msg-id> <.CRLF> }

    my token obs-resent-rply { "Resent-Reply-To" <.WSP>* ':' <.address-list> <.CRLF> }

    my token obs-return { "Return-Path" <.WSP>* ':' <.path> <.CRLF> }

    # Errata ID: 3979
    my token obs-received { "Received" <.WSP>* ':' [<.received-token>+ || <.CFWS>] <.CRLF> }

    my token obs-optional { <.field-name> <.WSP>* ':' <.unstructured> <.CRLF> }
}
