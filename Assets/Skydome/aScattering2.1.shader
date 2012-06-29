// Upgrade NOTE: replaced 'glstate.matrix.mvp' with 'UNITY_MATRIX_MVP'

///Skydome shader by Martijn Dekker aka Pixelstudio
///if you have questions just drop me a mail at martijn.pixelstudio@gmail.com
///Version 1.0

///Color correction by Jon Apgar jon.apgar@hotmail.com

Shader "aScattering 2.1" {
	Properties {
		DirectionalityFactor("DirectionalityFactor",float) = 1.5
		SunColorIntensity("SunColorIntensity",float) = 0.7
		tint("tint",float) = 1.9
		fade("Cloud fade height",float) = 0.033
		cloudSpeed1("cloudSpeed1",float)= 0.06
		cloudSpeed2("cloudSpeed2",float)= 0.02
		plane_height1("cloud plane height 1",float)=18
		plane_height2("cloud plane height 2",float)=41
		noisetex ("noise texture", 2D) = "white" {}
		starTexture ("starTexture", 2D) = "white" {}
		curveTexture ("curveTexture", 2D) = "white" {}
		LightDir("LightDir",Vector) = (-0.657,-0.024,0.7758)
		vBetaRayleigh("vBetaRayleigh",Vector) = (0.0008,0.0014,0.0029)
		BetaRayTheta("BetaRayTheta",Vector) = (0.0001,0.0002,0.005)
		vBetaMie("vBetaMie",Vector) = (0.0012,0.0016,0.0023)
		BetaMieTheta("BetaMieTheta",Vector) = (0.0009,0.0012,0.0017)
		g_vEyePt("g_vEyePt",Vector) = (0,13.397,0)
		g_vSunColor("g_vSunColor",Vector) = (0.6878,0.5951,0.4217)
		wind_direction("winddirection",Vector) = (0.8736,1.2048,1.2365,0.3)
		hueShift("hueShift",float) =0
		satM("saturationMultiplier",float) =1
		satT("saturationTranspose",float) =0
		briM("brightnessMultiplier",float) =1
		briT("brightnessTranspose",float) =0
	}

	SubShader {
	Pass {
		Cull Front
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma target 3.0
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
		float satM;
		float satT;
		float briM;
		float briT;
		float hueShift;


		sampler2D noisetex;
		sampler2D starTexture;
		sampler2D curveTexture;

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

		float3 RGBtoHSV(in float3 RGB)
		{
			float3 HSV = float3(0,0,0);
	
			HSV.z = max(RGB.r, max(RGB.g, RGB.b));
			float M = min(RGB.r, min(RGB.g, RGB.b));
			float C = HSV.z - M;
		
			if (C != 0)
			{
				HSV.y = C / HSV.z;
				float3 Delta = (HSV.z - RGB) / C;
				Delta.rgb -= Delta.brg;
				Delta.rg += float2(2,4);
				if (RGB.r >= HSV.z)
					HSV.x = Delta.b;
				else if (RGB.g >= HSV.z)
					HSV.x = Delta.r;
				else
					HSV.x = Delta.g;
				HSV.x = frac(HSV.x / 6);
			}
			return HSV;
		}

		float3 Hue(float H)
		{
			float R = abs(H * 6 - 3) - 1;
			float G = 2 - abs(H * 6 - 2);
			float B = 2 - abs(H * 6 - 4);
			return saturate(float3(R,G,B));
		}

		float3 HSVtoRGB(float3 HSV)
		{
			return ((Hue(HSV.x) - 1) * HSV.y + 1) * HSV.z;
		}

		float3 Saturate(float3 rgb, float h, float s, float b,float st, float bt) {
			float3 hsv = RGBtoHSV(rgb);
			hsv.x = fmod(hsv.x+h,360);
			hsv.y = clamp(hsv.y*s +st,0,1);
			hsv.z = clamp(hsv.z*b +bt,0,1);
			return (HSVtoRGB(hsv));
			return rgb;
		}
		
		float3 Curve(float3 rgb) {
		
			#if !defined(SHADER_API_OPENGL)
			rgb.r = tex2D(curveTexture, float2(rgb.r,0)).r;
			rgb.g = tex2D(curveTexture, float2(rgb.g,0)).g;
			rgb.b = tex2D(curveTexture, float2(rgb.b,0)).b;
			#endif 
			return rgb;
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
			OUT.color.rgb=Saturate(Curve(L*g_vSunColor*SunColorIntensity),hueShift,satM,briM,satT,briT);
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
			//color+=(g_vSunColor.z+tint)*cloud_color.z*(intensity)*cloud_color;
			color+= tint*cloud_color.a*(intensity)*float4(Saturate(g_vSunColor,0,1.5,1,0,0),1);
			color+=IN.color;
			color.a=1.0;
			return color;
		}
		ENDCG
		}
	}
FallBack "None"
}