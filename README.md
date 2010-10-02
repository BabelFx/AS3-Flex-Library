## BabelFx 

Formerly known as *l10nInjection*, the **BabelFx** Framework provides multi-language (l10n) Injection for Flex and Flash applications. 

### Introduction

Combining IoC concepts with the power of MXML, this library provides a powerful, easy framework for run-time 
injection of localized resources (strings, bitmaps, skins, etc.) into Flex GUI views and non-DisplayObject models 
and business classes. This solution can be used with ANY framework within Flex 3 or Flex 4 and has been tested 
with sample applications using Swiz, Cairngorm, Mate, or no application framework at all. 

Simple rebuild or include the BabelFx.swc in your custom project, create a custom LocalizationMap, add an 
instance of that LocalizationMap to your application and your immediately have multi-language support. Using a 
single LocalizationMap instance, developers can centralize all mappings of localized resources to specific 
destinations and usages. Whenever the locale changes, resources are re-injected into specified destinations. In fact 
the l10n injection can occur upon locale changes, model changes, view state changes, or GUI instantiations... 
full power for all your needs. 

The BabelFx solution can be used:

- Within custom Flex 3 or Flex 4 solutions 
- Within AIR deployments or Web-only solutions. 
- Within modules or applications.

This GIT repository contains the both: 

1. the source code for the BabelFX.swc flex library, and 
2. the FlashBuilder 4 Flex library project settings  

Please review the [tutorials and blogs](http://www.gridlinked.info) and [code samples](http://github.com/ThomasBurleson/l10nInjection_Samples/wiki). 


### Library Build Tips

    Namespace URL:   library://ns.mindspace.com/l10n/flex/
    Manifest file:  manifest.xml

### Open-Source License

Code is released under a BSD License:
http://www.opensource.org/licenses/bsd-license.php

Copyright (c) 2008, Adobe Systems Incorporated
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

* Neither the name of Adobe Systems Incorporated nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.