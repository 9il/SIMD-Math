/**
Copyright: Ilya Yaroshenko 2013-.

License: boost.org/LICENSE_1_0.txt.

Authors: Ilya Yaroshenko
*/

module simd.dotproduct;

import simd.simd;
import std.math;
import std.complex;

F dotProduct(F)(in F[] a, in F[] b) @trusted
if(is(F == double) || is(F == float))
in
{
	assert(a.length == b.length);
}
out(result)
{
	assert(!result.isNaN);
} 
body
{
	enum N = MaxVectorSizeof / F.sizeof;
	alias VP = const(Vector!(F[N]))*;

	auto ap = a.ptr, bp = b.ptr; 
	const n = a.length;
	const end = ap + n;
	const ste = ap + (n & -N);
	const sbe = ap + (n & -N*4);
	
	Vector!(F[N]) s0 = 0, s1 = 0, s2 = 0, s3 = 0;	

	for(; ap < sbe; ap+=4*N, bp+=4*N)
	{
		s0 += load(cast(VP)ap+0) * load(cast(VP)bp+0);
		s1 += load(cast(VP)ap+1) * load(cast(VP)bp+1);
		s2 += load(cast(VP)ap+2) * load(cast(VP)bp+2);
		s3 += load(cast(VP)ap+3) * load(cast(VP)bp+3);
	}

	s0 = (s0+s1)+(s2+s3);
		
	for(; ap < ste; ap+=N, bp+=N)
		s0 += load(cast(VP)ap+0) * load(cast(VP)bp+0);

	//horizontal reduce vector to scalar
	F s = toScalarSum(s0);

	for(; ap < end; ap++, bp++)
		s += ap[0] * bp[0];
	
	return s;
}

/// dot product for complex numbers: sum(a_i * conj(b_i]))
C dotProduct(C : Complex!F, F)(in C[] a, in C[] b) @trusted
if(is(F == double) || is(F == float))
in
{
	assert(a.length == b.length);
}
out(result)
{
	assert(!result.re.isNaN);
	assert(!result.im.isNaN);
}
body
{
	
	enum N = MaxVectorSizeof / F.sizeof;
	enum M = MaxVectorSizeof / C.sizeof;
	alias VP = const(Vector!(F[N]))*;

	auto ap = a.ptr, bp = b.ptr; 
	const n = a.length;
	const end = ap + n;
	const ste = ap + (n & -M);
	const sbe = ap + (n & -M*4);
	
	Vector!(F[N]) s0 = 0, s1 = 0, s2 = 0, s3 = 0;
	Vector!(F[N]) r0 = 0, r1 = 0, r2 = 0, r3 = 0;

	for(; ap < sbe; ap+=4*M, bp+=4*M)
	{
		auto a0 = load(cast(VP)ap+0);
		auto a1 = load(cast(VP)ap+1);
		auto a2 = load(cast(VP)ap+2);
		auto a3 = load(cast(VP)ap+3);

		auto b0 = load(cast(VP)bp+0);
		auto b1 = load(cast(VP)bp+1);
		auto b2 = load(cast(VP)bp+2);
		auto b3 = load(cast(VP)bp+3);

		s0 += a0 * b0;
		s1 += a1 * b1;
		s2 += a2 * b2;
		s3 += a3 * b3;

		//swaps real and imaginary parts
		a0 = swapReIm(a0);
		a1 = swapReIm(a1);
		a2 = swapReIm(a2);
		a3 = swapReIm(a3);

		r0 += a0 * b0;
		r1 += a1 * b1;
		r2 += a2 * b2;
		r3 += a3 * b3;		
	}

	for(; ap < ste; ap+=M, bp+=M)
	{
		auto a0 = load(cast(VP)ap+0);
		auto b0 = load(cast(VP)bp+0);
		s0 += a0 * b0;
		a0 = swapReIm(a0);	
		r0 += a0 * b0;
	}

	s0 = (s0+s1)+(s2+s3);
	r0 = (r0+r1)+(r2+r3);

	//horizontal reduce vector to scalar
	F re0 = toScalarSum(s0);
	F re1 = 0;
	//horizontal reduce vector to scalar, first step is substraction
	F im0 = toScalarSubSum(r0);
	F im1 = 0;

	for(; ap < end; ap++, bp++)
	{
		re0 += ap[0].re * bp[0].re;
		im0 += ap[0].im * bp[0].re;
		re1 += ap[0].im * bp[0].im;
		im1 -= ap[0].re * bp[0].im;
	}

	return C(re0+re1, im0+im1);
}


unittest
{
	import std.random;
	import std.conv;
	
	import std.stdio;
	writeln("dotproduct.d unittest");

	static C nativeDotProduct(C)(C[] a, C[] b)
	{
		C s = 0;
		foreach(i; 0..a.length)
		{
			static  if(is(C _ == Complex!T, T))
				s += a[i]*conj(b[i]);
			else
				s += a[i]*b[i];
		}
		return s;
	}

	foreach(i; 0..200)
	{
		auto ad = new double[i];
		auto bd = new double[i];
		auto af = new float[i];
		auto bf = new float[i];

		foreach(j; 0..i)
		{
			ad[j] = uniform(-200, 200);
			bd[j] = uniform(-200, 200);
			af[j] = uniform(-200, 200);
			bf[j] = uniform(-200, 200);
		}
		assert(nativeDotProduct(af, bf) == dotProduct(af, bf), text("length = ", i, '\n', af, '\n' ,bf));
		assert(nativeDotProduct(ad, bd) == dotProduct(ad, bd), text("length = ", i, '\n', ad, '\n' ,bd));
	}

	foreach(i; 0..200)
	{
		auto ad = new Complex!double[i];
		auto bd = new Complex!double[i];
		auto af = new Complex!float[i];
		auto bf = new Complex!float[i];

		foreach(j; 0..i)
		{
			ad[j].re = uniform(-200, 200);
			bd[j].re = uniform(-200, 200);
			af[j].re = uniform(-200, 200);
			bf[j].re = uniform(-200, 200);
			ad[j].im = uniform(-200, 200);
			bd[j].im = uniform(-200, 200);
			af[j].im = uniform(-200, 200);
			bf[j].im = uniform(-200, 200);
		}
		auto  npd =nativeDotProduct(ad, bd);
		auto  dpd =simd.dotproduct.dotProduct(ad, bd);
		assert(nativeDotProduct(ad, bd) == dotProduct(ad, bd), text("length = ", i, '\n', ad, '\n' ,bd, '\n',npd,'\n',dpd));
		auto dp = simd.dotproduct.dotProduct(af, bf);
		auto nt = nativeDotProduct(af, bf);
		assert(nt == dp, text("length = ", i, '\n', af, '\n' ,bf));
	}
}