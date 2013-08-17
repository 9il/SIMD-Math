/**
Copyright: Ilya Yaroshenko 2013-.

License: boost.org/LICENSE_1_0.txt.

Authors: Ilya Yaroshenko
*/

module simd.traits;

import core.simd;
import std.traits;
import std.range;
import std.typecons;
import std.conv;

template IntegralAnalog(U, T = Unqual!U)
{
	static if(isFloatingPoint!T && (T.sizeof <= double.sizeof))
		alias IntegralAnalog = Select!(is(U == float), int, long);
	else static if(isIntegral!T)
		alias IntegralAnalog = T;
	else static assert(0);
}

template FloatingPointAnalog(U, T = Unqual!U)
{
	static if(isFloatingPoint!T && T.sizeof <= double.sizeof)
		alias FloatingPointAnalog = T;
	else static if(isIntegral!T)
		alias FloatingPointAnalog = Select!(is(T == int), float, double);
	else static assert(0);
}


template isVector(V : Vector!(T[N]), T, size_t N) 
{ 
	enum bool isVector = true; 
}


template isVector(V) 
{	
	enum bool isVector = false; 
}