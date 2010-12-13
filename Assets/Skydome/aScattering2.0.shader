// Upgrade NOTE: replaced 'glstate.matrix.mvp' with 'UNITY_MATRIX_MVP'

///Skydome shader by Martijn Dekker aka Pixelstudio
///if you have questions just drop me a mail at martijn.pixelstudio@gmail.com
///Version 1.0

Shader "aScattering 2.0" {
	Properties {
		DirectionalityFactor("DirectionalityFactor",float) = 0.50468
		SunColorIntensity("SunColorIntensity",float) = 1.468
		tint("tint",float) = 1
		fade("Cloud fade height",float) = 0
		cloudSpeed1("cloudSpeed1",float)=1
		cloudSpeed2("cloudSpeed2",float)=1.5
		plane_height1("cloud plane height 1",float)=12
		plane_height2("cloud plane height 2",float)=13
		noisetex ("noise texture", 2D) = "white" {}
		starTexture ("starTexture", 2D) = "white" {}
		LightDir("LightDir",Vector) = (-0.657,-0.024,0.7758)
		vBetaRayleigh("vBetaRayleigh",Vector) = (0.0008,0.0014,0.0029)
		BetaRayTheta("BetaRayTheta",Vector) = (0.0001,0.0002,0.005)
		vBetaMie("vBetaMie",Vector) = (0.0012,0.0016,0.0023)
		BetaMieTheta("BetaMieTheta",Vector) = (0.0009,0.0012,0.0017)
		g_vEyePt("g_vEyePt",Vector) = (0,13.397,0)
		g_vSunColor("g_vSunColor",Vector) = (0.6878,0.5951,0.4217)
		wind_direction("winddirection",Vector) = (0.8736,1.2048,1.2365,0.3)
	}

	SubShader {
	Pass {
		Cull Front
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		float3 g_vEyePt;
		float3 vBetaRayleigh;
		float3 BetaRayTheta;
		float3 vBetaMie;
		float3 BetaMieTheta;
		float3 LightDir;
		float3 g_vSunColor;
		float DirectionalityFactor;
		float SunColorIntensity;
		float cloudSpeed1;
		float cloudSpeed2;
		float tint;
		float plane_height1;
		float plane_height2;
		float fade;
		float4 wind_direction;
		float4 cloudProperties;
		sampler2D noisetex;
		sampler2D starTexture;

		struct vertex_output {
			float4 position 		: POSITION;
			float4 color 			: COLOR;
			float2 uvcoords1 		: TEXCOORD0;// Cloud layer01
			float intensity 		: TEXCOORD1;// Cloud intensity
			float2 uvcoords2 		: TEXCOORD2;// Cloud layer02
			float2 skydomecoluv 	: TEXCOORD3;// UV for the cloud layer
			float orgposz 			: TEXCOORD4;
			float2 starUV 			: TEXCOORD5;
		};

		float3 BetaR(float Theta){
			return BetaRayTheta*(3.0f+0.5f*Theta*Theta);
		}

		float3 BetaM(float Theta){
			float g =DirectionalityFactor;
			return(BetaMieTheta*pow(1.0f-g,2.0f))/(pow(1+g*g-2*g*Theta,1.5f));
		}

		float3 Lin(float Theta,float SR,float SM){
			return ((BetaR(Theta)+BetaM(Theta))*(1.0f-exp(-(vBetaRayleigh*SR+vBetaMie*SM))))/(vBetaRayleigh + vBetaMie );
		}

		vertex_output vert(appdata_base Input) {
			vertex_output OUT;
			
			//mul( iPos, g_mWorld );
			//float3 vPosWorld = Input.vertex;
			float3 vPosWorld = mul(UNITY_MATRIX_MV,Input.vertex);
			
			//float3 ray = vPosWorld - g_vEyePt;
			float3 ray =  ObjSpaceViewDir(Input.vertex);
			float far = length(ray) ;
			ray = normalize(ray);
			float Theta = dot(ray, LightDir);
			float SR =(1.05f-pow(ray.y,0.3f)) * 2000;
			float SM=far*0.05f;
			float3 L=Lin(Theta, SR, SM );
 
			//cloud stuff
			float3 normVect=normalize(Input.vertex)/100;
			OUT.orgposz=abs(Input.vertex.y);
			float2 vectLength1=float2(normVect.z,normVect.x)*plane_height1;
			float2 vectLength2=float2(normVect.z,normVect.x)*plane_height2;
			float t1=_Time*cloudSpeed1;
			float t2=_Time*cloudSpeed2;
			OUT.uvcoords1.xy=0.9*vectLength1+t1/10*wind_direction.xy*OUT.orgposz;
			OUT.uvcoords2.xy=0.4*vectLength2+t2/10*wind_direction.zw*OUT.orgposz;
			float fadeheight=fade/64;
			OUT.starUV=Input.texcoord * 20;
			OUT.position=mul(UNITY_MATRIX_MVP,Input.vertex);
			OUT.intensity=max(normVect.y-fadeheight,0);
			OUT.color.rgb=L*g_vSunColor*SunColorIntensity;
			OUT.color.a=1.0f;
			return OUT;
		}
		float4 frag (vertex_output IN): COLOR {
			float4 color:COLOR;
			float4 noise1=tex2D(noisetex,IN.uvcoords1.xy/IN.orgposz);
			float4 noise2=tex2D(noisetex,IN.uvcoords2.xy/IN.orgposz);
			float4 stars=tex2D(starTexture,IN.starUV.xy);
			float4 cloud_color=(noise1*noise2);
			float intensity=1-exp(-512*pow(IN.intensity,1));
			stars*=1-saturate(g_vSunColor.z* 4 + cloud_color.a*2);
			float cloud_alpha = max(noise1.a, noise2.a);
			stars*= cloud_alpha *2;
			color=stars;
			color+=(g_vSunColor.z+tint)*cloud_color.z*(intensity)*cloud_color;
			color+=IN.color;
			color.a=1.0;
			return color;
		}
		ENDCG
		}
	}
FallBack "None"
}