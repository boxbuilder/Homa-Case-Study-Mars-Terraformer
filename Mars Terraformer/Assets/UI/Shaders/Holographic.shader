//////////////////////////////////////////////
/// 2D Shader Collection - by VETASOFT 2018 //
//////////////////////////////////////////////
/// optimized and improved by nick79 2020

//////////////////////////////////////////////

Shader "2DShaderCollection/Holographic"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_Hologram_Value_1("_Hologram_Value_1", Range(-1, 1)) = 1
		_Hologram_Speed_1("_Hologram_Speed_1", Range(0, 4)) = 1
		_SpriteFade("SpriteFade", Range(0, 1)) = 1.0

		// required for UI.Mask
		[HideInInspector]_StencilComp("Stencil Comparison", Float) = 8
		[HideInInspector]_Stencil("Stencil ID", Float) = 0
		[HideInInspector]_StencilOp("Stencil Operation", Float) = 0
		[HideInInspector]_StencilWriteMask("Stencil Write Mask", Float) = 255
		[HideInInspector]_StencilReadMask("Stencil Read Mask", Float) = 255
		[HideInInspector]_ColorMask("Color Mask", Float) = 15
	}

	SubShader
	{
		Tags {"Queue" = "Transparent" "IgnoreProjector" = "true" "RenderType" = "Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }
		ZWrite Off Blend SrcAlpha OneMinusSrcAlpha Cull Off

		// required for UI.Mask
		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp]
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"

			struct appdata_t{
			float4 vertex   : POSITION;
			float4 color    : COLOR;
			float2 texcoord : TEXCOORD0;
		};

		struct v2f
		{
			float2 texcoord  : TEXCOORD0;
			float4 vertex   : SV_POSITION;
			float4 color    : COLOR;
		};

		sampler2D _MainTex;
		float _SpriteFade;
		float _Hologram_Value_1;
		float _Hologram_Speed_1;

		v2f vert(appdata_t IN)
		{
			v2f OUT;
			OUT.vertex = UnityObjectToClipPos(IN.vertex);
			OUT.texcoord = IN.texcoord;
			OUT.color = IN.color;
			return OUT;
		}


		inline float Holo1mod(float x,float modu)
		{
			return x - floor(x * (1.0 / modu)) * modu;
		}

		inline float Holo1noise(sampler2D source,float2 p)
		{
			float _TimeX = _Time.y;
			float sample = tex2D(source, float2(0.2, 0.2 * cos(_TimeX)) * _TimeX * 8.0 + p * 1.0).x;
			return sample * sample;
		}

		inline float Holo1onOff(float a, float b, float c)
		{
			float _TimeX = _Time.y;
			return step(c, sin(_TimeX + a*cos(_TimeX*b)));
		}

		// Define a variable to control the frequency of the glitch effect
		//float glitchFrequency = 4.0; 

		float4 Hologram(float2 uv, sampler2D source, float value, float speed)
		{
			float _TimeX = _Time.y * speed;
			float2 look = uv;

			
			//float xsync =(look.y - Holo1mod(_TimeX / 4.0, 1.0));
			float sintime2 = sin(_TimeX * 100.0);

			//float window = 1.0 / (1.0 + 20.0 * xsync * xsync);// * glitchIntensity;
			//look.x += sin(look.y * 30.0 + _TimeX) / (50.0 * value) * Holo1onOff(4.0, 4.0, 0.3) * (1.0 + cos(_TimeX * 80.0)) * window;
			//vsync lost vfx:
			//float vShift = 0.4 * Holo1onOff(2.0, 3.0, 0.9) * (sin(_TimeX) * sintime2 + (0.5 + 0.1 * sintime2 * cos(_TimeX)));
			//look.y = Holo1mod(look.y + vShift, 1.0);
			
			float4 videox = tex2D(source, look);
			float2 scalinefx = float2(0.05, 0.0) * Holo1onOff(2.0, 1.5, 0.9);

			float4 video = float4(
				tex2D(source, look - scalinefx).r, 
				videox.g, 
				tex2D(source, look + scalinefx).b, 
				videox.a);

			video += Holo1noise(source, uv * float2(0.5, 1.0) + float2(6.0, 3.0)) * value * 3.0;
			//video += Holo1noise(source, uv * 2.0) / 2.0;
			float vigAmt = 3.0 + 0.3 * sin(_TimeX + 5.0 * cos(_TimeX * 5.0));
			float2 uvDisp = uv - 0.5;
			uvDisp*=uvDisp;
			float vignette = (1.0 - vigAmt * uvDisp.y) * (1.0 - vigAmt * uvDisp.x);
			video.r *= vignette;
			video *= (12.0 + Holo1mod(uv.y * 30.0 + _TimeX, 1.0)) / 13.0;
			video.a += frac(sin(dot(uv.xy * _TimeX, float2(12.9898, 78.233))) * 43758.5453) * 0.5;
			video.a *= 0.3 * video.a * vignette * 2.0 * tex2D(source, uv).a;
			video.a *= 1.2;
			return video;
		}

		float4 frag (v2f i) : COLOR
		{
			float4 _Hologram_1 = Hologram(i.texcoord,_MainTex,_Hologram_Value_1,_Hologram_Speed_1);
			float4 FinalResult = _Hologram_1;
			FinalResult.rgb *= i.color.rgb;
			FinalResult.a = FinalResult.a * _SpriteFade * i.color.a;
			return FinalResult;
		}

		ENDCG
		}
	}
	Fallback "Sprites/Default"
}
