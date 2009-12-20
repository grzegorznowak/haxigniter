﻿package haxigniter.server.routing;

import haxigniter.server.Controller;
import haxigniter.server.Config;

interface Router
{
	/**
	 * Creates a controller from a uri. The haxigniter.server.libraries.Request library is useful here.
	 * @param	config
	 * @param	uri
	 * @return
	 */
	function createController(config : Config, requestUri : String, queryParams : Hash<String>) : Controller;
}
