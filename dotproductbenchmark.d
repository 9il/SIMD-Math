/**
Copyright: Ilya Yaroshenko 2013-.

License: boost.org/LICENSE_1_0.txt.

Authors: Ilya Yaroshenko
*/

import simd.dotproduct;

import std.numeric;
import std.datetime;
import std.complex;
import core.simd;
import std.stdio;
import std.typecons;
import std.traits;
import std.algorithm;
import std.range;
import std.traits;
import std.math;
import std.conv;
static import std.compiler;

enum q = 4L;

enum L = 1024L*q;

T trivialDotProduct(T)(T[] a, T[] b)
{
	T s = 0;
	foreach(i; 0..a.length)
		s += a[i]*b[i];
	return s;
}

auto dotProductBenchmark(T)(size_t length, size_t count)
{
	static if(is(T _ : Complex!F, F))
		enum k = 8;
	else
		enum k = 2;

	T[] a = new T[length];
	T[] b = new T[length];
	foreach(i, ref e; a) e = i;
	foreach(i, ref e; b) e = i;

	T[] a1 = a.dup;
	T[] a2 = a.dup;
	T[] a3 = a.dup;
	T[] b1 = a.dup;
	T[] b2 = a.dup;
	T[] b3 = a.dup;

	static T dp;
	return benchmark!
		(
			{ dp = trivialDotProduct(a1, b1); },
			{ dp = std.numeric.dotProduct(a2, b2); },
			{ dp = simd.dotproduct.dotProduct(a3, b3); },
		)
		(cast(uint)count)[].map!(a => length * count * k / (cast(real)(a.nsecs)))().array;
}

void main() 
{
	bench!(float, double, Complex!float, Complex!double);
	//bench!(float);
}

void bench(Arg...)()
{
	writefln("Compiler\tType\tlog2(Length)\tVariant\tGFLOPS");
	foreach(T; Arg)
	{
		foreach(i; 0..22)
		{
			const length = 2L^^(i+1);
			const count = 2L^^(26-i);
			auto bm = dotProductBenchmark!T(length, count);
			foreach(e, v; lockstep(bm, ["trivial", "phobos", "simd"]))
			{
				writefln("%s\t%s\t%s\t%s\t%s", std.compiler.name, T.stringof, length.log2.text, v, e);
			}
		}
	}
}