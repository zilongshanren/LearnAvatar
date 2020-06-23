// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "zilong/hero"
{
	Properties
	{
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}

		_NormalMap ("Normal Map", 2D) = "white" {}

		_EmissionMap ("Emission Map", 2D) = "white" {}

		_RimMaskTex ("Rim Mask", 2D) = "white" {}

		_AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)

		_SpecularSizeTex("SpecularSizeTex", 2D) = "white" {}
		_SpecularAreaTex("SpecularAreaTex", 2D) = "white" {}

		_EmissionScale("Emission Scale", float) = 0.5


		_WrapDiffuse("WrapDiffuse",  Range(0, 1)) = 0.5
		_ShadeEdge0("ShadeEdge0",  Range(0, 1)) = 0.925
		_ShadeEdge1("ShadeEdge1",  Range(0, 1)) = 1

		_SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
		_SpecularRange("SpecularRange",  Range(0, 1)) = 0.15
		_Glossiness("Glossiness", Range(0.01, 256)) = 8

		[HDR]_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimAmount("Rim Amount", Range(0, 1)) = 0.042
		_RimThreshold("Rim Threshold", Range(0, 10)) =6

		[Toggle]_EmissionToggle("Emission Toggle", Int) = 0
		[Toggle]_SpecularExponentToggle("SpecularExponent Toggle", Int) = 0
		[Toggle]_SpecularAreaToggle("SpecularArea Toggle", Int) = 0
		[Toggle]_RimMaskToggle("RimMask Toggle", Int) = 0
	}
	SubShader
	{



		Pass 
		{
			Tags { 
				"LightMode"="ForwardBase" 
				"PassFlags" = "OnlyDirectional"
			}
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fwdbase

			#pragma shader_feature  _EMISSIONTOGGLE_ON
			#pragma shader_feature  _SPECULAREXPONENTTOGGLE_ON
			#pragma shader_feature  _SPECULARAREATOGGLE_ON
			#pragma shader_feature  _RIMMASKTOGGLE_ON

			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			sampler2D _SpecularSizeTex;
			sampler2D _SpecularAreaTex;
			sampler2D _NormalMap;
			sampler2D _EmissionMap;
			sampler2D _RimMaskTex;

			float4 _MainTex_ST;

			float _WrapDiffuse, _ShadeEdge0, _ShadeEdge1;

			float4 _AmbientColor;

			float _Glossiness;

			float _SpecularRange;
			float4 _SpecularColor;

			float _RimThreshold, _RimAmount;
			float4 _RimColor;
			
			float _EmissionScale;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			}; 
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : NORMAL;
				float2 uv : TEXCOORD0;
				float3 viewDir : TEXCOORD1;
				float3 tangentWorld : TEXCOORD2;
				float3 binormalWorld : TEXCOORD3;
				SHADOW_COORDS(4)
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				o.pos = UnityObjectToClipPos( v.vertex);
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
				o.worldNormal  = UnityObjectToWorldNormal(v.normal);
				// o.viewDir = UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex));
				//deprecated
				o.viewDir = WorldSpaceViewDir(v.vertex);
				o.tangentWorld = normalize(mul(unity_ObjectToWorld, half4(half3(v.tangent.xyz), 0)));
				o.binormalWorld = normalize(cross (o.worldNormal, o.tangentWorld) * v.tangent.w);
				
				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			float4 frag(v2f i) : SV_Target { 
				half4 color = tex2D(_MainTex, i.uv) * _Color;
				// normal in tangent space
				fixed3 norm	= UnpackNormal(tex2D(_NormalMap, i.uv));

				// float3 normal = normalize(i.worldNormal);
				float3x3 TBNMatrixTranspose = float3x3
				(
				i.tangentWorld,
				i.binormalWorld,
				i.worldNormal
				);
				float3 normal = normalize(mul(norm, TBNMatrixTranspose));
				// normal = i.worldNormal;


				float3 viewDir = normalize(i.viewDir);

				// float ndotl = max(0, dot( normal,  _WorldSpaceLightPos0 ));
				float ndotl = dot( normal,  _WorldSpaceLightPos0 );


				float wrapLambert = (ndotl * _WrapDiffuse + 1 - _WrapDiffuse) ; //+ imgTex.g;
				float shadow = SHADOW_ATTENUATION(i);
				float shadowStep = smoothstep(_ShadeEdge0, _ShadeEdge1, wrapLambert * shadow);

				half4 diffuse = lerp(_AmbientColor, _LightColor0, shadowStep);

				float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
				float ndoth = dot(normal, halfVector);
				// float specularIntensity = pow(ndoth, _Glossiness);
				#ifdef _SPECULAREXPONENTTOGGLE_ON
					_Glossiness = tex2D(_SpecularSizeTex, i.uv).a * _Glossiness;
				#endif

				float specularIntensity = pow(ndoth, _Glossiness);
				#ifdef _SPECULARAREATOGGLE_ON
					_SpecularRange = tex2D(_SpecularAreaTex, i.uv).a;
				#endif
				half4 specular = saturate(specularIntensity * _SpecularRange)  * _SpecularColor;



				float rimDot = pow(1 - saturate(dot(viewDir, normal)  ), _RimThreshold);

				#ifdef _RIMMASKTOGGLE_ON
					rimDot *= tex2D(_RimMaskTex, i.uv).r;
				#endif

				float rimIntensity = rimDot ;
				rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
				half4 rim = rimIntensity * _RimColor;


				#ifdef _EMISSIONTOGGLE_ON
					//add emissioni
					color += tex2D(_EmissionMap, i.uv) * _EmissionScale;
				#endif
				
				// return  (diffuse + specular) * color;
				// return diffuse * color;
				// return rim * color;
				return float4((diffuse  + specular + rim) * color.rgb, color.a);
				
				// return color;
			}
			
			ENDCG
		}
	}
	FallBack "Diffuse"
}
