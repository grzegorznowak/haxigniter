package haxigniter.server.request;

import haxigniter.server.Controller;
import haxigniter.server.libraries.Url;

import haxigniter.server.Config;
import haxigniter.server.libraries.Request;
import haxigniter.common.libraries.ParsedUrl;
import haxigniter.common.rtti.RttiUtil;
import haxigniter.server.request.RequestHandler;
import haxigniter.common.types.TypeFactory;

/**
 * Use this class instead of Controller to get a Ruby on Rails-inspired RESTful approach.
 * "classname" is your controller class, "ID" is any identifier that will be casted to the type T of your choice.
 * Some methods have "?arg, ...", which means that any appending arguments will be used in the method.
 * 
 * GET-requests:
 * 
 *  /classname           -> index()
 *  /classname/new       -> make(?arg, ...)
 *  /classname/ID        -> show(id : T, ?arg, ...)
 *  /classname/ID/edit   -> edit(id : T, ?arg, ...)
 * 
 * POST-requests:
 * 
 *  /classname           -> create(formData : Hash<String>)
 *  /classname/ID        -> update(id : T, formData : Hash<String>)
 *  /classname/ID/delete -> destroy(id : T)
 * 
 * 
 * Thanks to Thomas on the haXe list for the inspiration.
 * 
 * For more info about the RESTful approach, here's a tutorial:
 * http://www.softiesonrails.com/search?q=Rest+101%3A+Part
 * 
 */
class RestHandler implements RequestHandler
{
	private var config : Config;
	
	public function new(config : Config)
	{
		this.config = config;
	}
	
	public function handleRequest(controller : Controller, url : ParsedUrl, method : String, getPostData : Hash<String>, rawRequestData : String) : Dynamic
	{
		var action : String = null;
		var args : Array<Dynamic> = [];
		var typecastId = false;

		var controllerType = Type.getClass(controller);
		var callMethod : Dynamic;

		var uriSegments = new Url(config).split(url.path);
		
		// TODO: Multiple languages for reserved keywords
		if(method == 'GET')
		{
			// Start of extra arguments in the request
			var extraArgsPos : Int = null;
			
			// Start of extra arguments in the method
			var argOffset : Int = null;

			if(uriSegments.length <= 1)
			{
				action = 'index';
			}
			else if(uriSegments[1] == 'new')
			{
				action = 'make'; // Sorry, cannot use new.
				extraArgsPos = 2;
				argOffset = 0;
			}
			else
			{
				if(uriSegments[2] == 'edit')
				{
					action = 'edit';
					extraArgsPos = 3;
				}
				else
				{
					action = 'show';
					extraArgsPos = 2;
				}
				
				// Id is the only argument.
				args.push(uriSegments[1]);
				argOffset = 1;
				typecastId = true;
			}

			callMethod = Reflect.field(controller, action);
			if(callMethod == null)
				throw new haxigniter.server.exceptions.NotFoundException(controllerType + ' REST-action "' + action + '" not found.');

			// Add extra arguments if the action allows.
			if(extraArgsPos != null)
			{
				//haxigniter.server.Application.trace('--- Request: ' + uriSegments);
				//haxigniter.server.Application.trace('Extra args: ' + uriSegments.slice(extraArgsPos));
				
				// Typecast the extra arguments and add them to the action.
				var extraArguments : Array<Dynamic> = TypeFactory.typecastArguments(Type.getClass(controller), action, uriSegments.slice(extraArgsPos), argOffset);

				args = args.concat(extraArguments);
				
				//haxigniter.server.Application.trace('Typed: ' + extraArguments);
				//haxigniter.server.Application.trace('Output: ' + args);
			}
		}
		else if(method == 'POST')
		{
			var query : Hash<String>;
			
			if(getPostData != null)
				query = getPostData;
			else
				query = new Hash<String>();
			
			if(uriSegments.length <= 1)
			{
				action = 'create';
				args.push(query);
			}
			else if(uriSegments[2] == 'delete')
			{
				action = 'destroy';

				args.push(uriSegments[1]);
				typecastId = true;
			}
			else
			{
				action = 'update';

				args.push(uriSegments[1]);
				args.push(query);
				typecastId = true;
			}

			callMethod = Reflect.field(controller, action);
			if(callMethod == null)
				throw new haxigniter.server.exceptions.NotFoundException(controllerType + ' REST-action "' + action + '" not found.');
		}
		else
		{
			throw new haxigniter.common.exceptions.Exception('Unsupported HTTP method: ' + method);
		}
		
		if(typecastId)
		{
			// Typecast the first argument.
			var methodArgs = RttiUtil.getMethod(action, controllerType);
			args[0] = TypeFactory.createType(methodArgs.first().type, args[0]);
		}
		
		return Reflect.callMethod(controller, callMethod, args);
	}
}
