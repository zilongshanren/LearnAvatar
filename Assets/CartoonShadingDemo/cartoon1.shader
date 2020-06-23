// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "zilong/cartoon1"
{

	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

		_MainColor("Main Color", Color) = (1,1,1)
		_ShadowColor ("Shadow Color", Color) = (0.7, 0.7, 0.8)
		_ShadowRange ("Shadow Range", Range(0, 1)) = 0.5
		_ShadowSmooth("Shadow Smooth", Range(0, 1)) = 0.2

		_RampTex ("Texture", 2D) = "white" {}

		[Space(10)]
		_OutlineWidth ("Outline Width", Range(0.01, 2)) = 0.24
		_OutLineColor ("OutLine Color", Color) = (0.5,0.5,0.5,1)

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		//双色阶实现
		Pass
		{
			Tags {"LightMode"="ForwardBase"}
			
			Cull Back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

			sampler2D _MainTex; 
			float4 _MainTex_ST;
			half3 _MainColor;
			half3 _ShadowColor;
			half _ShadowRange;

			sampler2D _RampTex;

			half _ShadowSmooth;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 mainTex = tex2D(_MainTex, i.uv);
				half4 col = 1;

				half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
				half3 worldNormal = normalize(i.worldNormal);
				half3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

				half halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;

				//hard
				// half3 diffuse = halfLambert > _ShadowRange ? _MainColor : _ShadowColor;

				//smooth 
				half ramp = smoothstep(0, _ShadowSmooth, halfLambert - _ShadowRange);
				half3 diffuse = lerp(_ShadowColor, _MainColor, ramp);

				//ramp texture
				// half 

				diffuse *= mainTex;
				col.rgb = _LightColor0 * diffuse;

				return col;
			}
			ENDCG
		}
	}
}
