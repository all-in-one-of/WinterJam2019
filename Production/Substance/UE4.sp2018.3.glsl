//- Unreal Engine 4 shader for Substance Painter
//- ================================================
//-
//- Import from libraries.
import lib-sampler.glsl
import lib-pbr.glsl
import lib-alpha.glsl
import lib-sparse.glsl
//- Show back faces as there may be holes in front faces.
//: state cull_face off

//- Enable alpha blending
//: state blend over

//- Channels needed for metal/rough workflow are bound here.
//: param auto channel_basecolor
uniform SamplerSparse basecolor_tex;
//: param auto channel_roughness
uniform SamplerSparse roughness_tex;
//: param auto channel_metallic
uniform SamplerSparse metallic_tex;

//: param custom { "default": 14000, "label": "noise density(dots per uv)", "min": 1.0, "max": 100000.0 }
uniform float noiseDensity;

const float  g_PI = 3.1415926;
const float  g_INV_PI = 1.0/3.1415926;

struct surface
{
	vec3	baseColor;
	vec3	normal;
	float	metallic;
	vec3	F0;
	float	specular;
	float	T;
	float	roughness;
	float	gloss;
	float	ao;
};

struct shadingOut
{
	float	alphaOutput;
	vec3	diffuse;
	vec3	specular;
	vec3	emissive;
	vec3	albedo;
	vec4	sss;
};

//--------------------------------------------------------------------------------------------------
vec3 pow3(vec3 a, float b)
{
return vec3(pow(a.x,b),pow(a.y,b),pow(a.z,b));
}

//--------------------------------------------------------------------------------------------------
vec3 mix3(vec3 a, vec3 b, float c)
{
return a * (1 - c) + c * b;
}

//--------------------------------------------------------------------------------------------------
 float radicalInverse_VdC(uint bits) 
 {
     bits = (bits << 16u) | (bits >> 16u);
     bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
     bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
     bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
     bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
     return float(bits); // / 0x100000000
 }
 
//--------------------------------------------------------------------------------------------------
 vec2 hammersley2d(uint i, uint N, uvec2 Random)
 {
	float X =  fract(float(i)/float(N) + float( Random.x & uint( 0xffff) ) / (1<<16) );
	float Y = float(uint(radicalInverse_VdC(i)) ^ Random.y) *  2.3283064365386963e-10;
    return vec2(X,Y);
 }
 
//--------------------------------------------------------------------------------------------------
uvec2 ScrambleTEA(uvec2 v)
{
	uint y 			= v[0];
	uint z 			= v[1];
	uint sum 		= uint(0);
	uint iCount 	= uint(4);
	 for(uint i = uint(0); i < iCount; ++i)
	{
		sum += uint(0x9e3779b9);
		y += (z << 4u) + 0xA341316Cu  ^ z + sum ^ (z >> 5u) + 0xC8013EA4u;
		z += (y << 4u) + 0xAD90777Du ^ y + sum ^ (y >> 5u) +  0x7E95761Eu;
	}
	return uvec2(y, z);
}

//--------------------------------------------------------------------------------------------------
float getMipFB3(float roughness,float vdh,float ndh,float SamplesNum)
{
//ToDo correct area for polar mapping 
	float width = exp2(maxLod) / 4 ;//quarter angle area, should be cubemap side 
	float omegaS = 1 /  (SamplesNum * probabilityGGX(ndh, vdh, max(roughness,0.01)));//Sample solid angle
	float omegaP = 4.0 * 3.141592 / (6.0 * width * width );//Texel solid angle
	return clamp (0.5 * log2 ( omegaS / omegaP ) , 3, maxLod );
}

//--------------------------------------------------------------------------------------------------
// Appoximation of joint Smith term for GGX
// [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
float Vis_SmithJointApprox( float Roughness, float NoV, float NoL )
{
	float a = Roughness * Roughness;
	float Vis_SmithV = NoL * ( NoV * ( 1 - a ) + a );
	float Vis_SmithL = NoV * ( NoL * ( 1 - a ) + a );
	return 0.5 / ( Vis_SmithV + Vis_SmithL );
}

//--------------------------------------------------------------------------------------------------
vec3 EnvBRDF( vec3 SpecularColor, vec2 AB, float Roughness, float NoV )
{
	// AB - Importance sampled preintegrated G * F
	// Anything less than 2% is physically impossible and is instead considered to be shadowing 
	vec3 GF = SpecularColor * AB.x + min( 50.0 * SpecularColor.g, 1.0) * AB.y;
	return GF;
}

//----------------------------------------------------------------------------------
vec3 spectralF(float VdH,vec3 F0)
{
 return F0 + ( 1 - F0 ) * exp2( ( -5.55473f * VdH - 6.98316f ) * VdH );
}

//----------------------------------------------------------------------------------
vec3 TangentToWorld( vec3 Vec, vec3 TangentZ )
{
	vec3 UpVector = abs(TangentZ.z) < 0.999 ? vec3(0,0,1) : vec3(1,0,0);
	vec3 TangentX = normalize( cross( UpVector, TangentZ ) );
	vec3 TangentY = cross( TangentZ, TangentX );
	return TangentX * Vec.x + TangentY * Vec.y + TangentZ * Vec.z;
}

//----------------------------------------------------------------------------------
vec4 ImportanceSampleGGX2( vec2 E, float Roughness )
{
	float m = Roughness * Roughness;
	float m2 = m * m;

	float Phi = 2 * g_PI * E.x;
	float CosTheta = sqrt( (1 - E.y) / ( 1 + (m2 - 1) * E.y ) );
	float SinTheta = sqrt( 1 - CosTheta * CosTheta );

	vec3 H;
	H.x = SinTheta * cos( Phi );
	H.y = SinTheta * sin( Phi );
	H.z = CosTheta;
	
	float d = ( CosTheta * m2 - CosTheta ) * CosTheta + 1;
	float D = m2 / ( g_PI*d*d );
	float PDF = D * CosTheta;
	
	return vec4( H, PDF );
}

//----------------------------------------------------------------------------------
	void IBLspec(V2F inputs, surface s, int SamplesNum, vec3 V, float NdV, out vec3 specIrr, out vec2 AB)
{
	//- Importance sampling
	uvec2 Random = ScrambleTEA(uvec2(inputs.multi_tex_coord[0].xy * noiseDensity));
	// Random = ScrambleTEA(uvec2(gl_FragCoord.xy ));
	
	vec3 integratedSpec	= vec3(0.0);
	vec3 integratedBRDF	= vec3(0.0);
	vec3 integratedIrrS	= vec3(0.0);
	float integratedCos	= 0;
	
	for(int i = 0; i < SamplesNum; ++i)
	{
		vec2 Xi 	 	= hammersley2d(uint(i), uint(SamplesNum),Random);
		vec4 GGX_PDF	= ImportanceSampleGGX2( Xi, s.roughness );
		vec3 H		 	= TangentToWorld( GGX_PDF.xyz, s.normal );
		vec3 L 	 	 	= -reflect(V, H);
		
		float NdL 	= max(1e-8, dot(s.normal, L));
		float VdH 	= max(1e-8, dot(V, H));
		float NdH 	= max(1e-8, dot(s.normal, H));
		float LdH 	= max(1e-8, dot(L, H));
		
		vec3 F		= spectralF(VdH, s.F0);
		float Vis	= Vis_SmithJointApprox(s.roughness, NdV, NdL);
		float PDF	= (4 * VdH / NdH);
		
	
		float D		= GGX_PDF.w * NdH /(4* LdH );
		float mip	= getMipFB3(s.roughness, VdH, NdH, SamplesNum);
		vec3 irrS	= envSampleLOD(L, mip);

		integratedSpec		+=	irrS * F * Vis * PDF * NdL ;
		integratedBRDF		+=	F * Vis * PDF * NdL ;
		integratedIrrS		+=	irrS * NdL;
		integratedCos		+=	NdL;
		//UE4 specific
		float Fc 			= pow( 1 - VdH, 5 );
		AB.x				+= (1 - Fc) * Vis * PDF * NdL;
		AB.y				+= Fc * Vis * PDF * NdL;
	}

	integratedSpec	*= 1.0 / float(SamplesNum);

	//- Split Sum
	integratedBRDF	*= 1.0 / float(SamplesNum);
	integratedCos	*= 1.0 / float(SamplesNum);
	integratedIrrS	*= 1.0 / (float(SamplesNum) * integratedCos);
	
	AB				*= 1.0 / float(SamplesNum);
	specIrr			 = integratedIrrS;
	
}

//----------------------------------------------------------------------------------
	vec3 IBLdiffuse(V2F inputs, surface s, int SamplesNum)
{
	//- Diffuse contribution
	vec3 diffuseIrradiance	= envIrradiance(s.normal);
	vec3 integratedDiffuse	= s.ao * diffuseIrradiance * s.baseColor ;

	return integratedDiffuse;
}

//- Shader entry point.
void shade(V2F inputs)
{
	shadingOut Out; 
	surface s;
	vec2 AB;
	vec3 specIrr;
	
  
  //vec4 baseColor = texture(basecolor_tex, inputs.tex_coord);
  //vec3 metallic = texture(metallic_tex, inputs.tex_coord).xyz;
  //vec3 emissiveTex = texture(emissive_tex, inputs.tex_coord).rgb;
   alphaKill(inputs.tex_coord);
  float occlusion = getAO(inputs.tex_coord) * getShadowFactor();
  
  vec3 baseColor	= getBaseColor(basecolor_tex, inputs.sparse_coord);
  float roughness 	= getRoughness(roughness_tex, inputs.sparse_coord);
  float metallic 	= getMetallic(metallic_tex, inputs.sparse_coord);
  vec3 emissiveTex	= pbrComputeEmissive(emissive_tex, inputs.sparse_coord).xyz;
  

  	s.baseColor		= baseColor.xyz;
	s.normal		= computeWSNormal(inputs.tex_coord, inputs.tangent, inputs.bitangent, inputs.normal).xyz;
	s.metallic		= metallic;
	s.F0			= vec3(pow(s.metallic,2.2));
	s.specular		= 0.5;
	s.roughness		= roughness;
	s.roughness		*= s.roughness;
	s.ao			= occlusion;
	
	vec3 V = normalize(camera_pos - inputs.position);
	float NdV = dot(V, s.normal);
	
	//- Trick to remove black artefacts
	//- Backface ? place the eye at the opposite - removes black zones
	if (NdV < 0) 
	{
		V = reflect(V, s.normal);
		NdV = abs(NdV);
	}
	
	s.metallic			= pow(s.metallic,2.2);
	IBLspec(inputs, s, nbSamples, V, NdV, specIrr, AB);
	vec3 specularColor	= 0.08 * s.specular * (1.0 - s.metallic) + s.baseColor * s.metallic;
	Out.specular		= EnvBRDF( specularColor, AB, s.roughness, NdV ) * specIrr * s.ao;
	Out.diffuse 		= IBLdiffuse(inputs, s, nbSamples);
	
	// fragment opacity. default value: 1.0
	alphaOutput(1.0);
	// diffuse lighting contribution. default value: vec3(0.0)
	diffuseShadingOutput(Out.diffuse);
	// specular lighting contribution. default value: vec3(0.0)
	specularShadingOutput(Out.specular);
	// color emitted by the fragment. default value: vec3(0.0)
	emissiveColorOutput( emissive_intensity * emissiveTex );
	// fragment color. default value: vec3(1.0)
	albedoOutput(vec3(1.0));
	// subsurface scatt ering properties, see lib-sss.glsl for details. default value: vec4(0.0)
	sssCoefficientsOutput( vec4(0.0));
	
}

//- Entry point of the shadow pass.
void shadeShadow(V2F inputs)
{
}