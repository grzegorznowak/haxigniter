package haxigniter.rtti;

import haxe.rtti.CType;

typedef CArgument = {
	var type : String;
	var opt : Bool;
	var name : String;
}

class RttiUtil
{
	public static function getMethods(classType : Class<Dynamic>) : Hash<List<CArgument>>
	{
		var output = new Hash<List<CArgument>>();		

		// Find class declaration and all functions in it.
		switch(GetTypeTree(classType))
		{
			case TClassdecl(cl):
				for(f in cl.fields)
				{
					switch(f.type)
					{
						// Test if field is a function
						case CFunction(args, ret):
							var argList = new List<CArgument>();
							
							for(arg in args)
							{
								switch(arg.t)
								{
									// Create the CArgument type and test for 
									case CClass(name, params):
										// Set optional to false to avoid Null<T> since it can be deducted from the type itself.
										var typeName = TypeName(arg.t, false);										
										argList.add({type: typeName, opt: arg.opt, name: arg.name});
									
									default:
										// Do nothing if not an argument.
								}
							}
							
							output.set(f.name, argList);
	
						default:
							// Do nothing if not a method.
					}					
				}
			
			default:
				throw 'No RTTI class information found in ' + classType;
		}

		return output;
	}	

	public static function TypeName(type : CType, opt : Bool) : String 
	{
		switch(type)
		{
			case CFunction(_,_):
				return opt ? 'Null<function>' : 'function';
			
			case CUnknown:
				return opt ? 'Null<unknown>' : 'unknown';
			
			case CAnonymous(_), CDynamic(_):
				return opt ? 'Null<Dynamic>' : 'Dynamic';
			
			case CEnum(name, params), CClass(name, params), CTypedef(name, params):
				var t = name;
				
				if(params != null && params.length > 0) 
				{
					var types = new List<String>();
					for(p in params)
						types.add(TypeName(p, false));
					
					t += '<' + types.join(',') + '>';
				}
				
				return name != 'Null' && opt ? 'Null<'+t+'>' : t;
		}
	}
	
	public static function GetTypeTree(classType : Class<Dynamic>) : TypeTree
	{
		var root : Xml = Xml.parse(GetRtti(classType)).firstElement();
		return new haxe.rtti.XmlParser().processElement(root);
	}
	
	public static function GetRtti(classType : Class<Dynamic>) : String
	{
		var rtti : String = untyped classType.__rtti;
		if(rtti == null)
		{
			throw new haxigniter.exceptions.Exception('No RTTI information found in ' + classType + ' (class must implement haxe.rtti.Infos)');
		}
		
		return rtti;
	}
}