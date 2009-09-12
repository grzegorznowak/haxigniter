package haxigniter.unittests.given_a_TypeFactory;

import Type;
import haxigniter.types.TypeFactory;
import haxigniter.unit.TestCase2;

/**
* This is fun, unit testing a unit test class.
*/
class When_using_a_TypeFactory extends TestCase2
{
	public function test_Then_CreateType_should_return_valid_types_based_on_string_value()
	{
		var a = TypeFactory.CreateType('Int', '123');
		
		this.assertEqual(123, cast(a, Int));
		this.assertIsA(a, ValueType.TInt);

		var b = TypeFactory.CreateType('Float', '123.456');
		
		this.assertEqual(123.456, cast(b, Float));
		this.assertIsA(b, ValueType.TFloat);

		var c = TypeFactory.CreateType('String', 'Nice');
		
		this.assertEqual('Nice', cast(c, String));
		
		var d : Array<Int> = untyped TypeFactory.CreateType('Array<Int>', '1-2-3-4');
		
		this.assertIsA(d, Array);
		
		this.assertEqual(1, d[0]);
		this.assertEqual(2, d[1]);
		this.assertEqual(3, d[2]);
		this.assertEqual(4, d[3]);
		
		// Test the DbID class, which only accepts integers > 0
		var db : DbID = untyped TypeFactory.CreateType('haxigniter.types.DbID', '123');		
		this.assertIsA(db, haxigniter.types.DbID);
		
		try
		{
			var db2 : DbID = untyped TypeFactory.CreateType('haxigniter.types.DbID', '0');
		}
		catch (e : haxigniter.types.TypeException)
		{
			this.assertPattern(~/Invalid value for haxigniter.types.DbID: "0"/, e.Message);
		}
	}
}