This is the source code for the l10nInjection.swc library.

If you use the l10nInjection.swc included in the libs directory, you will not need to rebuild the source.
Or you can include a source path in your FlexBuilder/FlashBuilder that points to the l10n-src directory.

If you wish to rebuild, the swc itself, then

1) Copy the contents of l10n-src directory to a new directory <you custom path>/l10nInjection/src [hereafter referred to as the l10nPath]
2) Create a new Flex library project pointing to l10nPath.
3) Update your FlashBuilder      Project Properties > Flex Library Compiler > Complier options
  
    Namespace URL:   http://com.asfusion.mate.l10n/
    Manifest file:  manifest.xml

    Addt'l args:  -locale en_US

4) Set the Flex Library Build Path > Output folder   to the libs directory for the RegsistrationDemo (to update the l10nInjection.swc)
