#!/bin/bash
cd `dirname $0`

# Run unit tests
haxe -cp tools/runsrc -main RunUnitTests -x rununittests

if [ $? != 0 ]
then
	rm -f rununittests.n
	echo Unit tests failed.
	exit
fi

rm -f rununittests.n

if [ $1 == "test" ]
then
	exit
fi

exit

# Build run.n
cd tools/runsrc
haxe run.hxml

if [ $? != 0 ]
then
	cd ../..
	exit
fi

cd ../..

# Zip haxigniter and test it with haxelib
OUTPUT=${1:-haxigniter.zip}
rm -f $OUTPUT
zip -x .git -r $OUTPUT *
haxelib test $OUTPUT
