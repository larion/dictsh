# Dictsh

An extensible dictionary/encyclopedia shell

## Usage

    > dictsh
    dictsh (v0.01)
    For help type /h
    Loading plugin Wikipedia: OK
    Loading plugin Altervista: OK
    Loading plugin Woorden: OK
    Loading plugin Duden: OK
    Loading plugin TheFreeDictionary: OK
    Loading plugin GoogleTranslate: OK
    Loading plugin Synoniemen: OK
    de - de > /h
    COMMANDS

    /c(hange-language) lang1 [lang2]              change languages
    /s(witch)                                     switch primary and secondary languages
    /m(ode) mode                                  change mode (mode has to be one of: dictionary, thesaurus, definition, encyclopedia)
    /a(dd-plugin) plugin-name [plugin-arguments]  add a plugin
    /r(emove-plugin) plugin-name                  remove a plugin
    /d(ebug)                                      turn on debug mode
    /h(elp)                                       display this text

    EXAMPLES:

    /c en de       sets primary language to English and secondary language to German
    /c it          sets primary language to Italian
    /m e           switches to encyclopedia mode
    /m t           switches to thesaurus mode
    /a GoogleTranslate api_key XXXX    adds 'GoogleTranslate' plugin with api key XXXX
    /r Woorden        removes 'Woorden' plugin

    de - de > /c de en
    OK
    de - en > boshaft
    spitefully
    de - en > überwiegend
    mostly
    de - en > /c nl nl
    OK
    nl - nl > maatschappij
    de maatschappij
    Uitspraak:  [matsxɑ'pɛi]Verbuigingen:  maatschappij|en (meerv.)
    1)
    alle mensen samen, vooral de manier waarop ze met elkaar omgaan
    Voorbeelden:  `welvaartsmaatschappij`,`maatschappijkritiek`Synoniem:  samenleving
    2)
    groot bedrijf
    Voorbeeld:  `verzekeringsmaatschappij`Synoniem:  onderneming
    nl - nl > /m encyclopedia
    OK
    Encyclopedia (nl) > /c en
    OK
    Encyclopedia (en) > Alexandria
    [ The wikipedia page for Alexandria in a pager ]

## Extending the shell (for developers)

See perldoc App::Dict::Roles::Plugin for the interface. Also there are some examples under App::Dict::Plugin::*
which you can use as a template for your extension.
