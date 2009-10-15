package haxigniter.controllers;

#if php
import php.Lib;
import php.Web;
#elseif neko
import neko.Lib;
import neko.Web;
#end

import haxigniter.restapi.RestApiParser;
import haxigniter.restapi.RestApiRequest;
import haxigniter.restapi.RestApiResponse;
import haxigniter.restapi.RestApiAuthorization;

import haxigniter.exceptions.RestApiException;

class RestApiController extends Controller
{
	public static var commonMimeTypes = {
		haxigniter: 'application/vnd.haxe.serialized', 
		xml: 'application/xml',
		xhtml: 'application/xhtml+xml',
		html: 'text/html',
		json: 'application/json'
	};
	
	public var apiRequestHandler : RestApiRequestHandler;
	public var apiAuthorization : RestApiAuthorization;

	public var debugMode : haxigniter.libraries.DebugLevel;

	public function new(?apiRequestHandler : RestApiRequestHandler, ?apiAuthorization : RestApiAuthorization)
	{
		// Default behavior: If no handler specified, use a RestApiSqlRequestHandler.
		if(apiRequestHandler == null)
			this.apiRequestHandler = new haxigniter.restapi.RestApiSqlRequestHandler(this.db);
		else
			this.apiRequestHandler = apiRequestHandler;
		
		this.apiAuthorization = apiAuthorization;
	}
	
	/**
	 * Handle a page request.
	 * @param	uriSegments Array of request segments (URL splitted with "/")
	 * @param	method Request method, "GET" or "POST" most likely.
	 * @param	params Query parameters
	 * @return  Any value that the controller returns.
	 */
	public override function handleRequest(uriSegments : Array<String>, method : String, query : Hash<String>, rawQuery : String) : Dynamic
	{
		var response : RestApiResponse;
		var outputFormat : RestApiFormat = null;

		// Prepare for eventual debugging
		var oldTraceQueries = this.db.traceQueries;
		
		// Strip the api query from the query hash before urldecoding the raw query.
		for(getParam in query.keys())
		{
			if(rawQuery.indexOf(getParam) == 0)
				query.remove(getParam);
		}
		
		// Then strip everything after (and including) the first &.
		if(rawQuery.indexOf('&') >= 0)
			rawQuery = rawQuery.substr(0, rawQuery.indexOf('&'));

		// Finally, urldecode the query so it can be parsed.
		rawQuery = StringTools.urlDecode(rawQuery);

		try
		{
			// Parse the query string to get the output format early, so it can be used in error handling.
			var output = { format: null };			
			var selectors = RestApiParser.parse(rawQuery, output);
			
			if(output.format != null)
			{
				// Test if format is supported by the request handler.
				if(!Lambda.has(apiRequestHandler.supportedOutputFormats, outputFormat))
					throw new RestApiException('Invalid output format: ' + outputFormat, RestErrorType.invalidOutputFormat);
				
				outputFormat = output.format;
			}
			else
				outputFormat = apiRequestHandler.supportedOutputFormats[0];

			// Extract api version from second segment
			var versionTest = ~/^[vV](\d+)$/;
			if(uriSegments[1] == null || !versionTest.match(uriSegments[1]))
				throw new RestApiException('Invalid API version: ' + uriSegments[1], RestErrorType.invalidApiVersion);

			var apiVersion : Int = Std.parseInt(versionTest.matched(1));
			
			// Create the request type depending on method
			var type : RestApiRequestType = switch(method)
			{
				case 'POST': RestApiRequestType.create;
				case 'DELETE': RestApiRequestType.delete;
				case 'GET': RestApiRequestType.read;
				case 'PUT': RestApiRequestType.update;
				default: throw new RestApiException('Invalid request type: ' + method, RestErrorType.invalidRequestType);
			}
			
			// Get the raw posted data.
			var data : String = Web.getPostData();
			
			// TODO: User authorization, with the help of query.
			
			// Create the RestApiRequest object and pass it along to the handler.
			var request = new RestApiRequest(type, selectors, outputFormat, apiVersion, query, data);
			
			// Debugging
			if(this.debugMode != null)
			{
				this.db.traceQueries = this.debugMode;		
				this.trace(request);
			}
			
			// If authorization exists, it must go through.
			if(apiAuthorization != null && !apiAuthorization.authorizeRequest(request))
				throw new RestApiException('Unauthorized request.', RestErrorType.unauthorizedRequest);
			
			response = apiRequestHandler.handleApiRequest(request);
		}
		catch(e : RestApiException)
		{
			response = RestApiResponse.failure(e.message, e.error);
		}
		catch(e : Dynamic)
		{
			response = RestApiResponse.failure(Std.string(e), RestErrorType.unknown);
		}
		
		var finalOutput : RestResponseOutput = apiRequestHandler.outputApiResponse(response, outputFormat);

		// Debugging
		if(this.debugMode != null)
		{
			this.trace(RestApiDebug.responseToString(response));
			this.trace(finalOutput);
			this.db.traceQueries = oldTraceQueries;
		}
		
		// Format the final output according to response and send it to the client.
		var header = [];
		
		if(finalOutput.contentType != null)
			header.push(finalOutput.contentType);
		if(finalOutput.charSet != null)
			header.push('charset=' + finalOutput.charSet);
		
		if(header.length > 0 && this.debugMode == null)
			Web.setHeader('Content-Type', header.join('; '));

		if(this.debugMode == null)
			Lib.print(finalOutput.output);
	}
}
