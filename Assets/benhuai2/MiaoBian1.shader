Shader "BenHuai/MiaoBian1"
{
	Properties
	{
		_Outline ("OutlineWidth", Range(0, 0.5)) =  0.1
		_OutlineColor ("OutlineColor", Color) = (1, 1, 1, 1)


		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_LightTex ("Light Tex", 2D) = "white" {}

		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01

	}
	SubShader
	{

		Pass
		{
			name "OUTLINE"
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

				//calculate in clip space
				o.pos = UnityObjectToClipPos(v.vertex.xyz);
				float3 normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));
				float2 offset = TransformViewToProjection(normal.xy);
				o.pos.xy += offset * o.pos.z * _Outline;

				//calculate in view space
				// float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
				// float3 normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));
				// normal.z = -0.2; //防止内凹模型背面遮挡正面
				// pos = pos + float4(normalize(normal), 0) * _Outline;
				// o.pos = mul(UNITY_MATRIX_P, pos);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return _OutlineColor;
			}
			ENDCG
		}

		Pass 
		{
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;

			fixed4 _Specular;
			fixed _SpecularScale;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			}; 
			
			struct v2f {
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				o.pos = UnityObjectToClipPos( v.vertex);
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
				o.worldNormal  = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			float4 frag(v2f i) : SV_Target { 
			
				
				return fixed4(1.0, 1.0, 1.0, 1.0);
			}
			
			ENDCG
		}
	}
}
