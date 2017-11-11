![babelfx_landingpage](https://user-images.githubusercontent.com/210413/32693897-9bb09318-c6f8-11e7-8ac3-7bdd5dbcb796.jpg)

BabelFx (v2.0)
====================
<br/>
The BabelFx Localization library (version 2.0) has been completely rewritten and is now implemented as an extension(s) to the Swiz v1.x IoC framework. As such this version 2.x of BabelFx requires that the Swiz library be included as the core MVC/IoC framework.

Unlike previous versions, BabelFx v2 no longer uses a proprietary bean-detection engine nor does it require a custom LocaleMap class to be defined and instantiated. In this version of the localization engine/library, developers simply define metadata tags (ala AOP) within any class in which they want l10n injection to occur. Theses metadata tags specify injection directives and can be used to inject localized content into **any** object instance (UIComponent or other non-ui instances). 

The BabelFx localization engine does not care about the type of data to be injected; BabelFx will inject into all target/bean instances whenever (1) the locale changes, (2) view states change, or (3) injection parameter values change. Not only can localized text be *auto-magically* injected, but also stylesheets, styles, fonts, images, xml, byte data, and more.  

BabelFx only focuses on `where to inject` and `when to inject`! 

![image](http://cdn.babelfx.org/images/mini-features/l10nInjection_v2.png)


<br/>
To use BabelFx v2 and add localication (l10n) support to your application, you must:

* Use the Swiz 1.3 (or greater) IoC Framework
* Include Framework_Swiz_BabelFx.swc in your projects library dependencies
* Configure your Swiz setup to use BabelFx
* Configure your application code

&nbsp;&nbsp; Important!!&nbsp;&nbsp; 

    BabelFx v2 will only work as an extension to the Swiz Framework (v1.3 or greater).


## 1.1 Configure your Swiz setup: #

<br/>
To configure Swiz to use BabelFx Localization, simply register the `BabelFxProcess` and the event packages:

```mxml
	<sw:Swiz  xmlns:sw="http://swiz.swizframework.org" >
		
		<sw:config>
			<sw:SwizConfig 		 
				 id="appConfig"
				 strict="true"
				 eventPackages="ext.babelfx.events.*,..." 
				 viewPackages="…"
				 defaultFaultHandler="{genericFault}"/>
		</sw:config>
	
		<sw:customProcessors>
	
			<bfx:BabelFxProcessor xmlns:bfx="http://swiz.babelfx.org/"/>
			
		</sw:customProcessors>
		
	</sw:Swiz>
```

&nbsp;<br/>
Note: that your application project **must** include the following compiler argument:

    -keep-as3-metadata+="BabelFx"

This argument forces the compiler to include the [BabelFx()] metadata tags in the compiled bytecode… tags that are read during runtime by the BabelFxProcessor within the Swiz engine.
&nbsp;<br/>

## 1.2 Configure your Application code:  #

Let's assume that the either (1) resources have been embedded into the application bytecode or (2) an `ExternalLocaleCommand` has been configured to dynamically load the external resource bundles at runtime. 

Then the only remaining task required to completely localize your application is to define [BabelFx()] metadata tags that should be added to any desired view classes or registered controllers and models. 

Developers now implement these tags within class definitions (instead of within a LocalizationMap). Best of all is the fact that **any** class can now use these tags to defined l10n injections; UIComponents, Controllers, Models, Constants, etc. all can define BabelFx injections.

Non-UIComponent instances must be registered, of course, with Swiz; registration can be achieved as tag instances defined within a `BeanProvider` or by dynamically registering an instance via `BeanEvent.SETUP_BEAN` events.

To inject localized content into a view, simply use the `[BabelFx( )]` metadata tag:
<br/>&nbsp;

```mxml
	<?xml version="1.0" encoding="utf-8"?>
	<s:Group xmlns:fx="http://ns.adobe.com/mxml/2009"
			 xmlns:s="library://ns.adobe.com/flex/spark"
			 xmlns:mx="library://ns.adobe.com/flex/mx"
			 currentState="{ model.currentState }">
	
		<fx:Metadata>
			
			[BabelFx ( bundleName="login" )]
			       
			[BabelFx (  property="fiUserName.label", key="login.form.fiUserName" )]
			[BabelFx (  property="fiPassword.label", key="login.form.fiPassword" )]
			[BabelFx (  property="loginBtn.label",   key="login.submit"          )]
			[BabelFx (  property="lblHint.text",     key="login.tip"             )]
			[BabelFx (  property="loginBtn.backgroundColor", key="content.frame.color" )]
			
		</fx:Metadata>
			
		<mx:Form id="loginForm"	width="100%" verticalGap="15">
			<mx:FormItem id="fiUserName" label="Username:" required="true" height="25">
				<s:TextInput id="username" width="200" height="25" 
							 text="{ model.lastUsername }"
							 errorString="{model.usernameError}"
							 enter="login()"/>
			</mx:FormItem>
			<mx:FormItem id="fiPassword"  label="Password:" required="true" height="25">
				<s:TextInput id="password"
							 width="200" height="25"
							 errorString="{ model.passwordError }"
							 displayAsPassword="true"
							 text="{ model.password }"
							 enter="login()"/>
			</mx:FormItem>
			<mx:FormItem>
				<s:Button id="loginBtn" 
						  width="120" height="40"
						  styleName="mainButton"
						  label="Login"
						  enabled="{ !model.loginPending }"
						  click="login();"/>
			</mx:FormItem>
			<mx:FormItem>
				<s:Label id="lblHint" 
						 fontSize="13"
						 text="( Username: Flex   Password: Swiz )"/>
			</mx:FormItem>
		</mx:Form>
	
	</s:Group>
```

<br/>
For non-UIComponents, BabelFx injections are equally as versatile and powerful. Consider the Feedback model class below:

```actionscript	
	package com.companyx.productY.model
	{
	    import flash.events.Event;
	
	    import mx.collections.ArrayList;
	    import mx.events.PropertyChangeEvent;
	
	    // ***************************************************
	    // Metadata for Localization Injection
	    // ***************************************************
	
		    [BabelFx(bundle="header")]
		
		    // Inject directly into arraylist items...
		    
		    [BabelFx(property = "dataProvider[0].label", key = "feedbackItem")]
		    [BabelFx(property = "dataProvider[1].label", key = "problemsItem")]
		    [BabelFx(property = "dataProvider[2].label", key = "accountItem")]
		    [BabelFx(property = "dataProvider[3].label", key = "preferencesItem")]
		    [BabelFx(property = "dataProvider[4].label", key = "internetItem")]
		    [BabelFx(property = "dataProvider[5].label", key = "helpItem")]
		    [BabelFx(property = "dataProvider[6].label", key = "mediaTourItem")]
		    [BabelFx(property = "dataProvider[7].label", key = "logoutItem")]
		
		    [BabelFx(property = "submenu1.label", key = "submenu1Item")]
		    [BabelFx(property = "submenu2.label", key = "submenu2Item")]
	
	
	
	    [Bindable]
	    /**
	     * Special `constants` model with properties that are localized dynamically.
	     * This will trigger databindings and then update dependent UI components.
	     *
	     */
	    public class Feedback
	    {
	        // ***************************************************
	        // Public Constants		
	        // ***************************************************
	
	        public const GIVE_FEEDBACK  :String = "feedback";
	        public const REPORT_PROBLEM :String = "report";
	        public const MY_ACCOUNT     :String = "account";
	        public const PREFERENCES    :String = "preferences";
	        public const ADD_INTERNET   :String = "internetradio";
	        public const HELP           :String = "faqs";
	        public const MEDIA_TOUR     :String = "tour";
	        public const LOGOUT         :String = "logout";
	        public const AUTO_PLAY      :String = "submenu1";
	        public const SMART_TUNE     :String = "submenu2";
	
	
	        // ***************************************************
	        // Public Properties
	        // ***************************************************
	
	        /**
	         * DataProvider for any UI control that needs a list of FeedbackMenuItems 
	         * with localized content always auto-synchronized with the current locale.
	         */
	        public var dataProvider:ArrayList;
	
	        /**
	         * Sub-menu item exposed for l10n injection
	         */
	        public var submenu1:FeedbackMenuItem;
	
	        /**
	         * Sub-menu item exposed for l10n injection
	         */
	        public var submenu2:FeedbackMenuItem;
	
	
	         // ***************************************************
	        // Constructor
	        // ***************************************************
	
	        public function Feedback()
	        {
	            submenu1 = new FeedbackMenuItem("", AUTO_PLAY);
	            submenu2 = new FeedbackMenuItem("", SMART_TUNE);
	
	            dataProvider = new ArrayList();
	
	            dataProvider.addItem(new FeedbackMenuItem("", GIVE_FEEDBACK));
	            dataProvider.addItem(new FeedbackMenuItem("", REPORT_PROBLEM));
	            dataProvider.addItem(new FeedbackMenuItem("", MY_ACCOUNT));
	
	            dataProvider.addItem(new FeedbackMenuItem("", "", [ submenu1, submenu2 ]));
	
	            dataProvider.addItem(new FeedbackMenuItem("", ADD_INTERNET));
	            dataProvider.addItem(new FeedbackMenuItem("", HELP));
	            dataProvider.addItem(new FeedbackMenuItem("", MEDIA_TOUR));
	            dataProvider.addItem(new FeedbackMenuItem("", LOGOUT));
	        }
	
	    }
	}
```

## 1.3 Understanding the [BabelFx(&nbsp;)] Process ##

<br/>
When configured, the BabelFx localization engine is silently activated simply by the additiono of a special BabelFxProcessor that has been added to Swiz's array of metadata scanners (see 1.1 above).

The `BabelFxProcessor` will scan all beans instances for [BabelFx( )] or [l10n( )] metadata tags. 

As needed, the processor will silently construct ResourceInjector and ResourceSetter instances and store those instances in a hidden `LocalizationMap` instance. The `BabelFxProcessor` will also auto-scan and configure l10n injections for any DisplayObjects instances as they are dynamically `addedToStage`.

Using the hidden, registered ResourceInjectors, the BabelFx localization engine will inject into all target/bean instances whenever (1) the locale changes, (2) view states change, or (3) injection parameter values change. 


The `[BabelFx( )]` tag can use the following attributes:

```actionscript
	[BabelFx( property="", key="", parameters="", state="", bundleName="" )]
	[BabelFx( bundleName="" )]  or [BabelFx( "<bundleName>" )]
	[BabelFx( event="", handler="" )]
```

## 1.4 When auto-inject is not enough… ##

<br/>
Often, more complex logic must be also used to determine how some of the localized content should be used within components. In such cases, simply injection does not suffice. 

BabelFx supports this feature using the `[BabelFx( event="" )]` metadata tag. Unlike the other tags (above) which are defined outside the class, this tag is defined adjacent to the public function that should be invoked; used in the same manner as the `[EventHandler( )]` tag.

```actionscript
		[BabelFx(event="BabelFxEvent.*")]
		/**
		 *  Called by BabelFx engine after locale changes and injections into `this` instance have finished.
		 */
		public function onLocaleChanged():void
		{
			btnCancel.label   = resourceManager.getString('header', (model.signupMode ? 'fullSignup' : 'miniSignup'));
			btnCancel.toolTip = model.allowCancel ? '' : resourceManager.getString('header', 'cancelNotAllowedMsg');
			btnNext.label     = resourceManager.getString('header', 'next').toLocaleUpperCase();
		}
```

Developers should note that `[BabelFx( )]` is the same as `[BabelFx(event="BabelFxEvent.*")]`. This notation means that for any event within BabelFx, then the associated function should be called for the following event types:
	
```actionscript
		public static const INITIALIZED     :String = "initialized";
		public static const LOCALE_CHANGING	:String = "localeChanging";
		public static const LOCALE_CHANGED  :String = "localeChanged";
		
		public static const STATE_CHANGED   :String = "stateChanged";
		public static const TARGET_READY    :String = "creationComplete";
		public static const PARAMS_CHANGED  :String = "parametersChanged"
```

If the function handler should only be called during locale changes, then simply define the metadata tag as the following:

```actionscript
	[BabelFx(event="BabelFxEvent.LOCALE_CHANGED")]
```

This extra directive then instructs BabelFx to filter the events and to optimize the function handler invocation for events of only that specific type.

&nbsp;<br/>
Additionally, developers can use the powerful BabelFxUtils to simplify the above code. 

```actionscript
	[BabelFx(event = "BabelFxEvent.LOCALE_CHANGED")]
	public function onLocaleChanged():void 
	{
		var lookup:Function = BabelFxUtils.getLookup('header');
		var filter:Function = function(val:String):String{ return val.toUpperCase(); };
	
		btnCancel.label   = lookup( model.signupMode ? 'fullSignup' : 'miniSignup' );
		btnCancel.toolTip = model.canContinue ? '' : lookup( 'whyLockedMsg' );
		btnNext.label     = lookup ( 'next', filter );
	}
```

Notice how all references to ResourceManager are removed. The 'lookup` function is essentially a short-cut alias to the ResourceManager.get<XXXX>( ) methods.

&nbsp;<br/>

## 1.5 Debugging BabelFx Injections ##

<br/>
Simply add the `<SwizTraceTarget />` instance to your Swiz setup and insure that the filter includes the BabelFx packages. e.g.

```mxml
	<sw:Swiz  xmlns:sw="http://swiz.swizframework.org" >
		
		<sw:loggingTargets>
			<!-- 
			    SwizTraceTarget with filter enables log.debug() output for BabelFx 
			-->
			<sw:SwizTraceTarget id="babelfxConsole" filters="ext.babelfx.*" />
		</sw:loggingTargets>
		
	</sw:Swiz>
```

When your application starts, the BabelFxProcess will parse all metadata tags, prepare injectors, and the fire the injectors. As BabelFx executes, it will log debug output to the console. Shown below is a sample log output:

```ruby
	LocaleCommand::loadDefaultLocale( `en_US` )
	LocalizationMap::fireInjectors( ids=`1,2,3,4,5` )

		ResourceInjector[1] :: execute( com.model.constants::LoginConstants - why=`null` - 8 mappings )
		ResourceInjector[1] ::: inject( ui=`com.model.constants::LoginConstants` property=`FORGOT_PASSWORD` value=`Forgot Password: ` state=`` )
		ResourceInjector[1] ::: inject( ui=`com.model.constants::LoginConstants` property=`GUEST` value=`Guest` state=`` )
		ResourceInjector[1] ::: inject( ui=`com.model.constants::LoginConstants` property=`OR` value=`or ` state=`` )
		ResourceInjector[1] ::: inject( ui=`com.model.constants::LoginConstants` property=`SUBSCRIBER` value=`Subscriber` state=`` )
		ResourceInjector[1] ::: inject( ui=`com.model.constants::LoginConstants` property=`TO_PART_ONE` value=`By clicking "Login and Listen Now", I agree that I have read and agree to the CompanyX ` state=`` )
		ResourceInjector[1] ::: inject( ui=`com.model.constants::LoginConstants` property=`CUSTOMER_AGREEMENT` value=`Customer Agreement` state=`` )
		ResourceInjector[1] ::: inject( ui=`com.model.constants::LoginConstants` property=`PRIVACY_POLICY` value=`Privacy Policy` state=`` )
		ResourceInjector[1] ::: inject( ui=`com.model.constants::LoginConstants` property=`TO_PART_TWO` value=`, and certify that I am at least 18 years of age.` state=`` )

		ResourceInjector[2] :: execute( com.model::LanguagesModel - why=`null` - 4 mappings )
		ResourceInjector[2] ::: inject( ui=`com.model::LanguagesModel` property=`dataProvider[0].label` value=`English` state=`` )
		ResourceInjector[2] ::: inject( ui=`com.model::LanguagesModel` property=`dataProvider[1].label` value=`Spanish` state=`` )
		ResourceInjector[2] ::: inject( ui=`com.model::LanguagesModel` property=`dataProvider[2].label` value=`Canadian English` state=`` )
		ResourceInjector[2] ::: inject( ui=`com.model::LanguagesModel` property=`dataProvider[3].label` value=`Canadian French ` state=`` )
		ResourceInjector[2] :: [BabelFx( event=`localeChanged` )] on com.model::LanguagesModel::onUpdateLocale()


		ResourceInjector[3] :: execute( com.model::FeedbackModel - why=`null` - 10 mappings )
		ResourceInjector[3] ::: inject( ui=`com.model::FeedbackModel` property=`dataProvider[0].label` value=`Tell Us What You Think` state=`` )
		ResourceInjector[3] ::: inject( ui=`com.model::FeedbackModel` property=`dataProvider[1].label` value=`Report A Problem` state=`` )
		ResourceInjector[3] ::: inject( ui=`com.model::FeedbackModel` property=`dataProvider[2].label` value=`My Account` state=`` )
		ResourceInjector[3] ::: inject( ui=`com.model::FeedbackModel` property=`dataProvider[3].label` value=`Player Preferences` state=`` )
		ResourceInjector[3] ::: inject( ui=`com.model::FeedbackModel` property=`dataProvider[4].label` value=`Add Internet Listening` state=`` )
		ResourceInjector[3] ::: inject( ui=`com.model::FeedbackModel` property=`dataProvider[5].label` value=`Help/FAQs` state=`` )
		ResourceInjector[3] ::: inject( ui=`com.model::FeedbackModel` property=`dataProvider[6].label` value=`Web Player Tour` state=`` )
		ResourceInjector[3] ::: inject( ui=`com.model::FeedbackModel` property=`dataProvider[7].label` value=`Log Out` state=`` )

		ResourceInjector[5] :: execute( com.model.presentation::ChannelsPresentationModel - why=`null` - 0 mappings )

	LocalizationMap::fireInjectors( ids=`6` )

		ResourceInjector[6] :: execute( com.view.login::LoginPanel - why=`null` - 3 mappings )
		ResourceInjector[6] ::: inject( ui=`com.view.login::LoginPanel` property=`lblSubscribers.text` value=` Subscribers` state=`` )
		ResourceInjector[6] ::: inject( ui=`com.view.login::LoginPanel` property=`lblTitle.text` value=`Product Z` state=`` )
		ResourceInjector[6] ::: inject( ui=`com.view.login::LoginPanel` property=`lblSuggestLogin.text` value=`Log In & Listen` state=`` )

	LocalizationMap::fireInjectors( ids=`7` )

		ResourceInjector[7] :: execute( com.view.login::LoginPanelLeft - why=`null` - 4 mappings )
		ResourceInjector[7] ::: inject( ui=`com.view.login::LoginPanelLeft` property=`userName.prompt` value=`Username: CompanyX` state=`` )
		ResourceInjector[7] ::: inject( ui=`com.view.login::LoginPanelLeft` property=`password.prompt` value=`Password: CompanyX` state=`` )
		ResourceInjector[7] ::: inject( ui=`com.view.login::LoginPanelLeft` property=`rememberMeCheckbox.label` value=`Remember Me` state=`` )
		ResourceInjector[7] ::: inject( ui=`com.view.login::LoginPanelLeft` property=`loginButton.label` value=`Log In & Listen` state=`` )
		ResourceInjector[7] :: [BabelFx( event=`localeChanged` )] on com.view.login::LoginPanelLeft::onLocaleChanged()
		
		_
```		
		

This log output makes it trivial to identify any [BabelFx()] tags that are incorrect or not working.

## 1.6 Demo Application ##

<br/>
The BabelFx sample application [CafeTownsend with Swiz](https://github.com/BabelFx/AS3-Flex-Samples/commit/82287d144eda045c22d57b730ede5dca6c4e3b33) has been updated to use the new BabelFx-for-Swiz library.

Developers are also directed to 

*  [Getting Started with BabelFx](http://www.gridlinked.info/gettingstarted-with-babelfx/)
*  [Learning BabelFx: Video Tutorial](http://www.gridlinked.info/flex-i18n-with-localizationmaps-video-tutorial-source/)
*  [BabelFx Home](http://www.babelfx.org)
