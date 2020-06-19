// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "BenHuai/MiaoBian2"
{
	Properties
	{
		_Outline ("OutlineWidth", Range(0, 0.5)) =  0.1
		_OutlineColor ("OutlineColor", Color) = (1, 1, 1, 1)


		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_LightTex ("Light Tex", 2D) = "white" {}

		_AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)

		_WrapDiffuse("WrapDiffuse",  Range(0, 1)) = 0.5
		_ShadeEdge0("ShadeEdge0",  Range(0, 1)) = 0.925
		_ShadeEdge1("ShadeEdge1",  Range(0, 1)) = 1

		_SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
		_SpecularRange("SpecularRange",  Range(0, 1)) = 0.15
		_Glossiness("Glossiness", Range(0.01, 256)) = 8

		[HDR]_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimAmount("Rim Amount", Range(0, 1)) = 0.042
		_RimThreshold("Rim Threshold", Range(0, 10)) =6
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
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			sampler2D _LightTex;
			float4 _MainTex_ST;

			float _WrapDiffuse, _ShadeEdge0, _ShadeEdge1;

			float4 _AmbientColor;

			float _Glossiness;

			float _SpecularRange;
			float4 _SpecularColor;

			float _RimThreshold, _RimAmount;
			float4 _RimColor;
			
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			}; 
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : NORMAL;
				float2 uv : TEXCOORD0;
				float3 viewDir : TEXCOORD1;
				SHADOW_COORDS(2)
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				o.pos = UnityObjectToClipPos( v.vertex);
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
				o.worldNormal  = UnityObjectToWorldNormal(v.normal);
				// o.viewDir = UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex));
				o.viewDir = WorldSpaceViewDir(v.vertex);
				
				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			float4 frag(v2f i) : SV_Target { 
				half4 color = tex2D(_MainTex, i.uv) * _Color;
				float4 imgTex = tex2D(_LightTex, i.uv);
				float3 normal = normalize(i.worldNormal);
				float3 viewDir = normalize(i.viewDir);

				// float ndotl = max(0, dot( normal,  _WorldSpaceLightPos0 ));
				float ndotl = dot( normal,  _WorldSpaceLightPos0 );


				float wrapLambert = (ndotl * _WrapDiffuse + 1 - _WrapDiffuse) + imgTex.g;
				float shadow = SHADOW_ATTENUATION(i);
				float shadowStep = smoothstep(_ShadeEdge0, _ShadeEdge1, wrapLambert * shadow);

				half4 diffuse = lerp(_AmbientColor, _LightColor0, shadowStep);

				float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
				float ndoth = dot(normal, halfVector);
				float specularIntensity = pow(ndoth, _Glossiness) * imgTex.r;
				float specularRange = step(_SpecularRange, specularIntensity + imgTex.b);
				half4 specular = specularRange * _SpecularColor;

				float rimDot = pow(1 - dot(viewDir, normal), _RimThreshold);
				float rimIntensity = rimDot;
				rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
				half4 rim = rimIntensity * _RimColor;

				
				// return  (diffuse + specular) * color;
				// return diffuse * color;
				// return rim * color;
				return (diffuse + specular + rim) * color;
			}
			
			ENDCG
		}

		Pass
		{
			Tags {
				"LightMode" = "ForwardBase"
			}

			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_base
			
			#include "UnityCG.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float4 vertColor: Color;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
			};

			half _Outline;
			half4 _OutlineColor;
			
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				float4 pos = UnityObjectToClipPos(v.vertex);
				float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.tangent.xyz);

				float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz)) * pos.w;//将法线变换到NDC空间

				float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y)); //将近裁剪面右上角位置的顶点变换到观察空间

				float aspect = abs(nearUpperRight.y / nearUpperRight.x);//求得屏幕宽高比

				ndcNormal.x *= aspect;

				pos.xy += 0.01 * _Outline * ndcNormal.xy;

				o.pos = pos;
				return o;

				
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return _OutlineColor;
			}
			ENDCG
		}
	}
}
