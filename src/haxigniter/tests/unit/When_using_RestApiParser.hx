package haxigniter.tests.unit;

import Type;
import haxigniter.types.TypeFactory;
import haxigniter.tests.TestCase;

import haxigniter.restapi.RestApiRequest;
import haxigniter.restapi.RestApiParser;

class When_using_RestApiParser extends haxigniter.tests.TestCase
{
	var output : Array<RestApiSelector>;
	
	public override function setup()
	{
	}
	
	public override function tearDown()
	{
	}
	
	public function test_Then_ALL_ONE_and_VIEW_selectors_should_be_parsed_properly()
	{
		output = parse('bazaars');
		
		this.assertEqual(1, output.length);
		this.assertApiResource(output[0], 'bazaars', null);

		output = parse('/bazaars');
		
		this.assertEqual(1, output.length);
		this.assertApiResource(output[0], 'bazaars', null);

		output = parse('/bazaars/');
		
		this.assertEqual(1, output.length);
		this.assertApiResource(output[0], 'bazaars', null);

		output = parse('/bazaars/1');
		
		this.assertEqual(1, output.length);
		this.assertApiResource(output[0], 'bazaars', 1);

		output = parse('/bazaars/1/libraries');
		
		this.assertEqual(2, output.length);
		this.assertApiResource(output[0], 'bazaars', 1);
		this.assertApiResource(output[1], 'libraries', null);
		
		output = parse('/bazaars/1/libraries/2');
		
		this.assertEqual(2, output.length);
		this.assertApiResource(output[0], 'bazaars', 1);
		this.assertApiResource(output[1], 'libraries', 2);

		output = parse('/bazaars/testview/');
		
		this.assertEqual(1, output.length);
		this.assertApiResource(output[0], 'bazaars', 'testview');

		output = parse('/bazaars/testview');
		
		this.assertEqual(1, output.length);
		this.assertApiResource(output[0], 'bazaars', 'testview');

		output = parse('/bazaars/testview/libraries/2');
		
		this.assertEqual(2, output.length);
		this.assertApiResource(output[0], 'bazaars', 'testview');
		this.assertApiResource(output[1], 'libraries', 2);

		output = parse('/bazaars/1/libraries/testview');
		
		this.assertEqual(2, output.length);
		this.assertApiResource(output[0], 'bazaars', 1);
		this.assertApiResource(output[1], 'libraries', 'testview');
		
		// All ok, lets test errors.
		badParse('/B�d request/', ~/Invalid resource: B�d request/);
	}
	
	public function test_Then_SOME_selectors_should_be_parsed_properly()
	{
		output = parse('/bazaars/[id=3][name^=Boris]/');

		this.assertEqual(1, output.length);
		
		this.assertSelectorAttrib(output[0], 0, 'id', RestResourceOperator.equals, '3');
		this.assertSelectorAttrib(output[0], 1, 'name', RestResourceOperator.startsWith, 'Boris');

		output = parse('/bazaars/:test[name*=Doris]:range(0,10):urlencode/');

		this.assertEqual(1, output.length);
		
		this.assertSelectorFunc(output[0], 0, 'test', new Array<String>());
		this.assertSelectorAttrib(output[0], 1, 'name', RestResourceOperator.contains, 'Doris');
		this.assertSelectorFunc(output[0], 2, 'range', ['0', '10']);
		this.assertSelectorFunc(output[0], 3, 'urlencode', new Array<String>());

		output = parse('/bazaars/1/libraries/:test[name*=Doris]:range(0,10):urlencode/');

		this.assertEqual(2, output.length);
		
		this.assertSelectorFunc(output[1], 0, 'test', new Array<String>());
		this.assertSelectorAttrib(output[1], 1, 'name', RestResourceOperator.contains, 'Doris');
		this.assertSelectorFunc(output[1], 2, 'range', ['0', '10']);
		this.assertSelectorFunc(output[1], 3, 'urlencode', new Array<String>());

		// And an error check.
		badParse('/bazaars/[this]]is not good', ~/Unrecognized selector segment: \]is/);
	}

	/////////////////////////////////////////////////////////////////
	
	private function assertSelectorAttrib(selector : RestApiSelector, selectorIndex : Int, name : String, operator : RestResourceOperator, value : String)
	{
		switch(selector)
		{
			case some(resource, selectors):
				switch(selectors[selectorIndex])
				{
					case attribute(aName, aOp, aValue):
						this.assertEqual(name, aName);
						this.assertEqual(operator, aOp);
						this.assertEqual(value, aValue);
					default:
						this.assertTrue(false); // The lazy way out
				}
			default:
				this.assertTrue(false);
		}		
	}

	private function assertSelectorFunc(selector : RestApiSelector, selectorIndex : Int, name : String, args : Array<String>)
	{
		switch(selector)
		{
			case some(resource, selectors):
				switch(selectors[selectorIndex])
				{
					case func(aName, aArgs):
						this.assertEqual(name, aName);
						this.assertEqual(Std.string(args), Std.string(aArgs));
					default:
						this.assertTrue(false); // The lazy way out
				}
			default:
				this.assertTrue(false);
		}		
	}
	
	private function assertApiResource(selector : RestApiSelector, resourceName : String, data : Dynamic)
	{
		switch(selector)
		{
			case one(resource, id):
				this.assertEqual(resource, resourceName);
				this.assertEqual(id, data);
			
			case some(resource, selectors):
				this.assertEqual(resource, resourceName);
				this.assertEqual(selectors, data);

			case all(resource):
				this.assertEqual(resource, resourceName);
			
			case view(resource, name):
				this.assertEqual(resource, resourceName);
				this.assertEqual(name, data);
		}		
	}

	private function badParse(input : String, expectedError : EReg) : Void
	{
		try 
		{
			parse(input);
			this.assertEqual('', 'Parse data "' + input + '" should\'ve failed.');
		}
		catch(e : haxigniter.exceptions.RestApiException)
		{
			this.assertPattern(expectedError, e.toString());
		}
	}
	
	private function parse(input : String) : Array<RestApiSelector>
	{
		return RestApiParser.parse(input);
	}
}