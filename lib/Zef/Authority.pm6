role Zef::Authority::Net { ... }



# Authorities can provide meta info on project and a target to send test reports
role Zef::Authority {
    has @.projects;

    method update-projects { ... }
}
