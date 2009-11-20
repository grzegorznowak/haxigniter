class RunUnitTests
{
    static function main()
    {
		neko.Lib.println('Running haXigniter tests...');
		var output = new haxigniter.tests.HaxigniterTests().runTests();
		
		neko.Lib.println(output);

		if(new EReg('\\bFAILED \\d+ tests', '').match(output))
			neko.Sys.exit(1);
		else
			neko.Sys.exit(0);
    }
}