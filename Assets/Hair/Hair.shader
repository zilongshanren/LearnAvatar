// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "zilong/Hair"
{
	Properties
	{
		_MainTex ("Diffuse Texture", 2D) = "white" {}
		_MainColor ("Main Color", Color) = (1,1,1,1)
		_NormalTex ("NormalTexture", 2D) = "white" {}
		_Cutoff ("Cutoff", float) = 0.5

		_ShiftMap ("SpecularShift Map", 2D) = "white" {}

		_Specular ("Specular Amount", Range(0, 5)) = 1.0 

		_SpecularColor ("Specular Color1", Color) = (1,1,1,1)
		_SpecularColor2 ("Specular Color2", Color) = (0.5,0.5,0.5,1)

		_SpecularMultiplier ("Specular Power1", float) = 100.0
		_SpecularMultiplier2 ("Specular Power2", float) = 100.0
		
		_PrimaryShift ( "Specular Shift1", float) = 0.0
		_SecondaryShift ( "Specular Shift2", float) = .7
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"	
			#include "AutoLight.cginc"	
			#pragma target 3.0

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;

			};

			sampler2D _MainTex;
			
			float4 _MainTex_ST;
			float _Cutoff;
			float4 _MainColor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 albedo = tex2D(_MainTex, i.uv);
				clip(albedo.a -_Cutoff);

				half4 finalColor = half4(0, 0, 0, albedo.a);
				finalColor.rgb += (albedo.rgb * _MainColor.rgb) * _LightColor0.rgb;
				return finalColor;
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"	
			#include "AutoLight.cginc"	
			#pragma target 3.0

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;  
				float4 TtoW1 : TEXCOORD2;  
				float4 TtoW2 : TEXCOORD3;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler2D _NormalTex;
			float4 _NormalTex_ST;
			float4 _MainTex_ST;
			float _Cutoff;
			float4 _MainColor;
			sampler2D _ShiftMap;

			half _SpecularMultiplier, _PrimaryShift, _Specular, _SecondaryShift, _SpecularMultiplier2;
			half4 _SpecularColor,_SpecularColor2;

			
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv, _NormalTex);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				//construct TBN matrix
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);


				return o;
			}

			float StrandSpecular(float3 T, float3 V, float L, float exponent)
			{
				float3 H = normalize(L + V);
				float dotTH = dot(T, H);
				float sinTH = sqrt(1.0 - dotTH * dotTH);
				float dirAtten = smoothstep(-1.0, 0.0, dot(T, H));

				return dirAtten * pow(sinTH, exponent);
			}

			fixed3 ShiftTangent ( fixed3 T, fixed3 N, fixed shift)
			{
				return normalize(T + shift * N);
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 albedo = tex2D(_MainTex, i.uv);
				half3 diffuseColor = albedo.rgb * _MainColor.rgb;

				
				fixed3 bump = UnpackNormal(tex2D(_NormalTex, i.uv.zw));
				//Nornal to tangent space, equal  mul(TBN, bump);
				fixed3 worldNormal = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldTangent = normalize(half3(i.TtoW0.x, i.TtoW1.x, i.TtoW2.x));
				fixed3 worldBinormal = normalize(half3(i.TtoW0.y, i.TtoW1.y, i.TtoW2.y));			

				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

				fixed3 spec = tex2D(_ShiftMap, i.uv).rgb;
				
				half shiftTex = spec.g;
				half3 t1 = ShiftTangent(worldBinormal, worldNormal, _PrimaryShift + shiftTex);
				half3 spec1 = StrandSpecular(t1, worldViewDir, worldLightDir, _SpecularMultiplier)* _SpecularColor;

				half3 t2 = ShiftTangent(worldBinormal, worldNormal, _SecondaryShift + shiftTex);
				half3 spec2 = StrandSpecular(t2, worldViewDir, worldLightDir, _SpecularMultiplier2)* _SpecularColor2;

				fixed4 finalColor = 0;
				finalColor.rgb = diffuseColor;
				finalColor.rgb += spec1 * _Specular;
				finalColor.rgb += spec2 * _SpecularColor2 * spec.b * _Specular;
				finalColor.rgb *= _LightColor0.rgb;
				finalColor.a = albedo.a;
				
				return finalColor;
			}
			ENDCG
		}
	}
}
