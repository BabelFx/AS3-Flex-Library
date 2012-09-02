package utils.string
{
	/**
	 *    Replaces all tokenized fields in target with field values from 
	 *    the fields datasource. With this routine, the mx StringUtils.substitute
	 *    is no longer needed to achieve printf() functionality.
	 *
	 *    Supplant is more powerful since it can resolve (on-demand) property chains
	 *    when used as fields; e.g. user.name (as shown below).
	 * 
	 *    @example
	 * 			
	 *    var source = 
	 *        '<table border="{border}">' 				+
	 *          '<tr><th>Last</th><td>{user.last}</td></tr>' 	+
	 *          '<tr><th>First</th><td>{user.first}</td></tr>' 	+
	 *        '</table>';
	 *
	 *        var fields : Object = 
	 *          {
	 *            user  : { 
	 *                       first : "Thomas",
	 *                       last  : "Burleson"
	 *                    },
	 *             border: 2
	 *          };
	 * 
	 *        Usage of supplant method:
	 *
	 *            trace(  supplant(source, fields) )
	 * 			
	 *        renders output:
	 *
	 *        <table border="2">
	 *            <tr><th>Last</th><td>Burleson</td></tr>
	 *            <tr><th>First</th><td>Thomas</td></tr>
	 *        </table>
	 *
	 *
	 *       @langversion ActionScript 3.0
	 *       @playerversion Flash 9.0
	 */
	public function supplant(target:String, fields:Object, matcher:RegExp = null):String {
		
		matcher ||= /\{([^\{\}]*)\}/g;
		
		// Support for property chains
		
		function getPropertyChainValue(a:*,b:*):* {
			var p : * = b.split(".");
			var r : * = fields;
			
			try {
				for (var s:* in p) r = r[p[s]];
			} catch(e:*) { r = a };
			
			return (!(r as String) || !(r as Number)) ? r : a;    			
		}
		
		return String(target.replace(matcher,getPropertyChainValue));
	}
	
	
	/**
	 * 
	 * Javascript equivalent (with support for property chains)
	 * 
	  function supplant ( template, values, pattern ) {
	    pattern = pattern || /\{([^\{\}]*)\}/g;
		 
	    return template.replace(pattern, function(a, b) {
	        var p = b.split('.'),
	            r = values;
	        
	        try {
	           for (var s in p) { r = r[p[s]];  };
	        } catch(e){
	          r = a;
	        }
	        
	        return (typeof r === 'string' || typeof r === 'number') ? r : a;
	      });
	    };
		 
	 */
	
}