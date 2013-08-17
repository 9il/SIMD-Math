/**
Copyright: Ilya Yaroshenko 2013-.

License: boost.org/LICENSE_1_0.txt.

Authors: Ilya Yaroshenko
*/

module simd.simd;

import simd.traits;

public import core.simd;

version(LDC)
{
	static import ldc.simd;
}

import std.traits;
import std.range;
import std.typecons;
import std.conv;
import std.string;

version(unittest)
{
	import std.stdio;
}

enum MaxVectorSizeof = 32;

private template shuffleMask(size_t a0, size_t a1, size_t a2, size_t a3)
{ 
    enum shuffleMask = a0 | (a1<<2) | (a2<<4) | (a3<<6); 
}


ref B bitcast(B, A)(ref A a) @property
if(B.sizeof == A.sizeof)
{
	return *cast(B*)&a;
}

version(GNU)
{
	import gcc.builtins;

	alias imm8 = const int;

	auto shuffle(param...)(float8 a, float8 b) pure
	{
	    return __builtin_ia32_shufps256(a, b, shuffleMask!param);
	}
	 
	auto shuffle(param...)(double4 a, double4 b) pure
	{
	    return __builtin_ia32_shufpd256(a, b, shuffleMask!param);
	}

	float8 floor(float8 v) pure
	{
		return __builtin_ia32_roundps256(v, 0b01);
	}

	double4 floor(double4 v) pure
	{
		return __builtin_ia32_roundpd256(v, 0b01);
	}

	int8 iround(float8 v) pure
	{
		return __builtin_ia32_cvtps2dq256(v);
	}

	//long4 iround(double4 v) pure
	//{
	//	//return __builtin_ia32_pmovsxdq256(__builtin_ia32_cvtpd2dq256(v));
	//	assert(0, "Not implemented");
	//	return 0;
	//}

	float8 toFloatingPoint(int8 v) pure
	{
		return __builtin_ia32_cvtdq2ps256(v);
	}

	//double4 toFloatingPoint(long4 v) pure
	//{
	//	assert(0, "Not implemented");
	//	return 0;;
	//}	

	float8 swapReIm(float8 v) pure @trusted
	{
		return __builtin_ia32_vpermilps256(v, 0b_10_11_00_01);
	}


	double4 swapReIm(double4 v) pure @trusted
	{
		return __builtin_ia32_vpermilpd256(v, 0b0101);
	}

	unittest
	{
		double4 a = [1,2,3,4];
		assert(a.swapReIm().array[] == [2,1,4,3][]);
	}
	

	float8 load(const(float8)* v) @trusted
	{
		return __builtin_ia32_loadups256(cast(const float *)v);
	}


	double4 load(const(double4)* v) @trusted
	{
		return __builtin_ia32_loadupd256(cast(const double *)v);
	}


	//float8 load(ref const(float8) v) @trusted
	//{
	//	return __builtin_ia32_loadups256(cast(const float *) &v);
	//}


	//double4 load(ref const(double4) v) @trusted
	//{
	//	return __builtin_ia32_loadupd256(cast(const double *) &v);
	//}

	float8 load(float8* v) @trusted
	{
		return __builtin_ia32_loadups256(cast(const float *)v);
	}


	double4 load(double4* v) @trusted
	{
		return __builtin_ia32_loadupd256(cast(const double *)v);
	}


	//float8 load(ref float8 v) @trusted
	//{
	//	return __builtin_ia32_loadups256(cast(const float *) &v);
	//}


	//double4 load(ref double4 v) @trusted
	//{
	//	return __builtin_ia32_loadupd256(cast(const double *) &v);
	//}

	//float8 load(float v) @trusted
	//{
	//	return v;
	//}

	//double4 load(double v) @trusted
	//{
	//	return v;
	//}

	float toScalarSum(float8 v) pure @trusted
	{
		v = __builtin_ia32_haddps256(v,v);
		v = __builtin_ia32_haddps256(v,v);
		float8 w = __builtin_ia32_vperm2f128_ps256(v, v, 0x11);
		w += v;
		return w.array[0];
	}


	double toScalarSum(double4 v) pure @trusted
	{
		v = __builtin_ia32_haddpd256(v,v);
		double4 w = __builtin_ia32_vperm2f128_pd256(v, v, 0x11);
		w += v;
		return w.array[0];
	}


	float toScalarSubSum(float8 v) pure @trusted
	{
		v = __builtin_ia32_hsubps256(v,v);
		v = __builtin_ia32_haddps256(v,v);
		float8 w = __builtin_ia32_vperm2f128_ps256(v, v, 0x11);
		w += v;
		return w.array[0];
	}


	double toScalarSubSum(double4 v) pure @trusted
	{
		v = __builtin_ia32_hsubpd256(v,v);
		double4 w = __builtin_ia32_vperm2f128_pd256(v, v, 0x11);
		w += v;
		return w.array[0];
	}



	int8 cmp(string cond, V : int8)(V a, V b)
	{
		static if(cond == "==")
			return __builtin_ia32_pcmpeqd256(a, b);
		else static if(cond == ">")
			return __builtin_ia32_pcmpgtd256(a, b);
		else static if(cond == "<")
			return __builtin_ia32_pcmpgtd256(b, a);
		else static if(cond == ">=")
			return ~__builtin_ia32_pcmpgtd256(b, a);
		else static if(cond == "<=")
			return ~__builtin_ia32_pcmpgtd256(a, b);
		else static assert(0);
	}


	long4 cmp(string cond, V : long4)(V a, V b)
	{
		static if(cond == "==")
			return __builtin_ia32_pcmpeqq256(a, b);
		else static if(cond == ">")
			return __builtin_ia32_pcmpgtq256(a, b);
		else static if(cond == "<")
			return __builtin_ia32_pcmpgtq256(b, a);
		else static if(cond == ">=")
			return ~__builtin_ia32_pcmpgtq256(b, a);
		else static if(cond == "<=")
			return ~__builtin_ia32_pcmpgtq256(a, b);
		else static assert(0);
	}


	float8 cmp(string cond, V : float8)(V a, V b)
	{
		enum p = imm8_cmp(cond);
		return __builtin_ia32_cmpps256(a, b, p);
	}


	double4 cmp(string cond, V : double4)(V a, V b)
	{
		enum p = imm8_cmp(cond);
		return __builtin_ia32_cmppd256(a, b, p);
	}


	imm8 imm8_cmp(string s)
	{
		switch(s)
		{
			case  "==": return 0x00;
			case   "<": return 0x01;
			case  "<=": return 0x02;
			case   ">": return 0x0d;
			case  ">=": return 0x0e;
			default:  assert(0);
		}
	}

	auto blendv(double4 a, double4 b, double4 c)
	{
		return __builtin_ia32_blendvpd256(a, b, c);
	}

	auto blendv(float8 a, float8 b, float8 c)
	{
		return __builtin_ia32_blendvps256(a, b, c);
	}

} 
else version (LDC)
{
	pragma(LDC_inline_ir)
	    R inlineIR(string s, R, P...)(P);

	auto simdOp
		(string cond, F : __vector(T[N]), T, size_t N)
		(F a, F b) 
		if(isIntegral!T)
	{
		enum t = llvmType!F; 
		alias f = inlineIR!(
			`
			%r = `~shiftSwitch!(cond)~` `~t~` %0, %1
			ret `~t~` %r
			`
			, F, F, F);
		return f(a, b);
	}


	IntegralAnalog!F cmp(string cond, F)(F a, F b) if(std.traits.isFloatingPoint!F)
	{
		mixin("return a"~cond~"b ? -1 : 0;");
	}

	auto cmp(string cond, V : __vector(T[N]), T, size_t N)(V a, V b)
	{

		alias I = IntegralAnalog!T;
		enum iv = llvmType!(I[N]);
		enum cv = llvmType!(T[N]);
		enum bv = llvmType!(bool[N]);
		enum op = cmpSelect!(T, cond);
		enum rec = `
			%c = `~op~` `~cv~` %0, %1
			%r = sext `~bv~` %c to `~iv~`
			ret `~iv~` %r
			`;
		return inlineIR!(rec, __vector(I[N]))(a, b);
	}

	V load(V : __vector(E[N]), E, size_t N)(V * v)
	{
		return inlineIR!(format(
			`%%r = load %s* %%0, align %s
			ret %s %%r`, llvmType!V, E.sizeof, llvmType!V
			), V)(v);
	}


	template cmpSelect(T, string cond)
	{
		static if(isFloatingPoint!T)
			enum cmpSelect = "fcmp o"~maskSwitch!(cond);
		else static if(cond == "==" || cond == "!=")
			enum cmpSelect = "icmp "~maskSwitch!(cond);
		else static if(isSigned!T)
			enum cmpSelect = "icmp s"~maskSwitch!(cond);
		else
			enum cmpSelect = "icmp u"~maskSwitch!(cond);
	}

	auto toScalarSum(V : __vector(T[N]), T, size_t N) (V a)
	{
		enum type = llvmType!T;
		static if(std.traits.isFloatingPoint!T)
			version(fast_math)
				enum add = "fadd fast";
			else
				enum add = "fadd";
		else
			enum add = "add";
		static if(N == 8)
			return inlineIR!(q{
				%v1 = shufflevector <8 x }~type~q{> %0, <8 x }~type~q{> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
				%v2 = shufflevector <8 x }~type~q{> %0, <8 x }~type~q{> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
				%sum1 = }~add~q{ <4 x }~type~q{> %v1, %v2
				%v3 = shufflevector <4 x }~type~q{> %sum1, <4 x }~type~q{> undef, <2 x i32> <i32 0, i32 1>
				%v4 = shufflevector <4 x }~type~q{> %sum1, <4 x }~type~q{> undef, <2 x i32> <i32 2, i32 3>
				%sum2 = }~add~q{ <2 x }~type~q{> %v3, %v4
				%v5 = extractelement <2 x }~type~q{> %sum2, i32 0
				%v6 = extractelement <2 x }~type~q{> %sum2, i32 1
				%sum3 = }~add~q{ }~type~q{ %v5, %v6
				ret }~type~q{ %sum3
			}, T)(a);
		else static if(N == 4)
			return inlineIR!(q{
				%v3 = shufflevector <4 x }~type~q{> %0, <4 x }~type~q{> undef, <2 x i32> <i32 0, i32 1>
				%v4 = shufflevector <4 x }~type~q{> %0, <4 x }~type~q{> undef, <2 x i32> <i32 2, i32 3>
				%sum2 = }~add~q{ <2 x }~type~q{> %v3, %v4
				%v5 = extractelement <2 x }~type~q{> %sum2, i32 0
				%v6 = extractelement <2 x }~type~q{> %sum2, i32 1
				%sum3 = }~add~q{ }~type~q{ %v5, %v6
				ret }~type~q{ %sum3
			}, T)(a);
		else static if(N == 2)
			return inlineIR!(q{
				%v5 = extractelement <2 x }~type~q{> %0, i32 0
				%v6 = extractelement <2 x }~type~q{> %0, i32 1
				%sum3 = }~add~q{ }~type~q{ %v5, %v6
				ret }~type~q{ %sum3
			}, T)(a);
		else static assert(0);
	}



	auto toScalarSubSum(V : __vector(T[N]), T, size_t N) (V a)
	{
		enum type = llvmType!T;
		static if(std.traits.isFloatingPoint!T)
			version(fast_math)
				enum add = "fadd fast";
			else
				enum add = "fadd";
		else
			enum add = "add";
		static if(N == 8)
			return inlineIR!(q{
				%v1 = shufflevector <8 x }~type~q{> %0, <8 x }~type~q{> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
				%v2 = shufflevector <8 x }~type~q{> %0, <8 x }~type~q{> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
				%sum1 = }~sub~q{ <4 x }~type~q{> %v1, %v2
				%v3 = shufflevector <4 x }~type~q{> %sum1, <4 x }~type~q{> undef, <2 x i32> <i32 0, i32 1>
				%v4 = shufflevector <4 x }~type~q{> %sum1, <4 x }~type~q{> undef, <2 x i32> <i32 2, i32 3>
				%sum2 = }~add~q{ <2 x }~type~q{> %v3, %v4
				%v5 = extractelement <2 x }~type~q{> %sum2, i32 0
				%v6 = extractelement <2 x }~type~q{> %sum2, i32 1
				%sum3 = }~add~q{ }~type~q{ %v5, %v6
				ret }~type~q{ %sum3
			}, T)(a);
		else static if(N == 4)
			return inlineIR!(q{
				%v3 = shufflevector <4 x }~type~q{> %0, <4 x }~type~q{> undef, <2 x i32> <i32 0, i32 1>
				%v4 = shufflevector <4 x }~type~q{> %0, <4 x }~type~q{> undef, <2 x i32> <i32 2, i32 3>
				%sum2 = }~sub~q{ <2 x }~type~q{> %v3, %v4
				%v5 = extractelement <2 x }~type~q{> %sum2, i32 0
				%v6 = extractelement <2 x }~type~q{> %sum2, i32 1
				%sum3 = }~add~q{ }~type~q{ %v5, %v6
				ret }~type~q{ %sum3
			}, T)(a);
		else static if(N == 2)
			return inlineIR!(q{
				%v5 = extractelement <2 x }~type~q{> %0, i32 0
				%v6 = extractelement <2 x }~type~q{> %0, i32 1
				%sum3 = }~sub~q{ }~type~q{ %v5, %v6
				ret }~type~q{ %sum3
			}, T)(a);
		else static assert(0);
	}


	//auto shufflevector(uint[] mask, V : __vector(T[N]),  T, size_t N, size_t K) (V a, V b)
	//{
	//	template blendImpl(size_t I)
	//	{
	//		static if(I = N-1)
	//			enum blendImpl = format("i32 %s", mask[I]);
	//		else
	//			enum blendImpl = format("i32 %s, %s", mask[I], blendImpl!(mask, I+1));
	//	}
	//	enum type = llvmType!V;
	//	return inlineIR!(q{
	//		%r = shufflevector }~type~q{ %0, }~type~q{ %1, <}~N.text~q{ x i32> <}~blendImpl!(reverse(mask), N)~q{>
	//		ret }~type~q{ %r
	//	}, __vector(T[N]))(a, b);
	//}

	auto toScalarSum(T)(T a) 
	if(std.traits.isNumeric!T) 
	{ 
		return a; 
	}


	private:


	package template llvmType(T : __vector(E[N]), E, size_t N)
	{
		enum llvmType = llvmType!(E[N]);
	}

	package template llvmType(T)
	{
	    static if(is(T == float))
	        enum llvmType = "float";
	    else static if(is(T == double))
	        enum llvmType = "double";
	    else static if(is(T == byte) || is(T == ubyte) || is(T == void))
	        enum llvmType = "i8";
	    else static if(is(T == short) || is(T == ushort))
	        enum llvmType = "i16";
	    else static if(is(T == int) || is(T == uint))
	        enum llvmType = "i32";
	    else static if(is(T == long) || is(T == ulong))
	        enum llvmType = "i64";
	    else static if(is(T == bool))
			enum llvmType = "i1";
	    else static if(isStaticArray!T)
			enum llvmType = format("<%s x %s>", T.init.length, llvmType!(ElementType!T));
	    else static assert(0, "Can't determine llvm type for D type " ~ T.stringof);
	}



	template shiftSwitch(string s)
	{
		static if (s == ">>")
			enum shiftSwitch = "ashr";
		else static if (s == ">>>")
			enum shiftSwitch = "lshr";
		else static if (s == "<<")
			enum shiftSwitch = "shl";
		else static assert(0,  s ~ " operator does not supported");
	} 


	pragma(LDC_intrinsic, "llvm.x86.avx.blendv.ps.256") float8 blendvf(float8, float8, float8);
	pragma(LDC_intrinsic, "llvm.x86.avx.blendv.pd.256") double4 blendvf(double4, double4, double4);
	pragma(LDC_intrinsic, "llvm.x86.sse41.blendvps") float4 blendvf(float4, float4, float4);
	pragma(LDC_intrinsic, "llvm.x86.sse41.blendvpd") double2 blendvf(double2, double2, double2);

	auto blendv(V : __vector(T[N]), T, size_t N)(V a, V b, V c)
	{
		alias W = __vector(FloatingPointAnalog!T[N]);
		return cast(V)blendvf(cast(W)a, cast(W)b, cast(W)c);
	}

}
else
{
	static assert(0, "ither compilers not implemented");
}




//unittest
//{
//	float8 e;
//	e.array = [1.0f, 10.0f, 100.0f, 1_000.0f, 10_000.0f, 100_000.0f, 1_000_000.0f, 10_000_000.0f ];
//	float f = e.toScalarSum;
//	assert(f == 11_111_111.0f, f.text);
//}

//unittest
//{
//	double4 e;
//	e.array = [1.0, 10.0, 100.0, 1_000.0];
//	double f = e.toScalarSum;
//	assert(f == 1_111.0f, f.text);
//}
 
 
auto select(M, V)(M mask, V a, V b)
if(isIntegral!(M) && V.sizeof == M.sizeof)
{
	return mask ? a : b;
}

auto select(M : __vector(I[N]), V : __vector(T[N]), I, T, size_t N)(M mask, V a, V b)
if(T.sizeof == I.sizeof)
{
	alias U = __vector(FloatingPointAnalog!T[N]);
	return cast(V)blendv(cast(U)b, cast(U)a, cast(U)mask);
}



template maskSwitch(string s)
{
	static if (s == "==")
		enum maskSwitch = "eq";
	else static if (s == "!=")
		enum maskSwitch = "ne";
	else static if (s == ">")
		enum maskSwitch = "gt";
	else static if (s == "<")
		enum maskSwitch = "lt";
	else static if (s == ">=")
		enum maskSwitch = "ge";
	else static if (s == "<=")
		enum maskSwitch = "le";
	else static assert(0,  s ~ " operator does not supported");
}


unittest
{
	int8 mask = [0,0,-1,-1,0,-1,-1,-1];
	float8 e = [0,1,2,3,4,5,6,7];
	float8 r = [9,8,7,6,5,4,3,2];
	float8 a = 100, b = 200;
	uint8 mask2 = e.cmp!"<"(r);
	assert(mask2.array[] == [-1,-1,-1,-1,-1,0,0,0][]);
	assert(e.cmp!"<"(r).select(a,b).array == [100, 100, 100, 100, 100, 200, 200, 200]);
	int masks = -1;
	float as = 100, bs = 200;
	assert(masks.select(as,bs) == 100);
}
