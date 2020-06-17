Shader "Avatar/Benhuai2"
{
	Properties
	{

		_Color ("Main Color", Color) = (1, 1, 1, 1)
		_ShadowColor ("Shadow Color", Color) = (0.8, 0.8, 1, 1)
		_SpecularPower ("Specular Power", Float) = 20
		_EdgeThickness ("Outline Thickness", Float) = 1
				
		_MainTex ("Diffuse", 2D) = "white" {}
		_FalloffSampler ("Falloff Control", 2D) = "white" {}
		_RimLightSampler ("RimLight Control", 2D) = "white" {}
		_SpecularReflectionSampler ("Specular / Reflection Mask", 2D) = "white" {}
		_EnvMapSampler ("Environment Map", 2D) = "" {} 
		_NormalMapSampler ("Normal Map", 2D) = "" {} 

	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" 
			"RenderType" = "Transparent"
		"IgnoreProjector" = "True" }

		Blend SrcAlpha OneMinusSrcAlpha

		LOD 100
		Cull Front

		Pass
		{
			CGPROGRAM
			#pragma vertex vert 			
			#pragma fragment frag 
			#include "UnityCG.cginc" 

			// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
			
			// Outline shader
			
			// Material parameters
			float4 _Color;
			float4 _LightColor0;
			float _EdgeThickness = 1.0;
			float4 _MainTex_ST;
			
			// Textures
			sampler2D _MainTex;
			
			// Structure from vertex shader to fragment shader
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			// Float types
			#define float_t  half
			#define float2_t half2
			#define float3_t half3
			#define float4_t half4
			
			// Outline thickness multiplier轮廓厚度乘数
			#define INV_EDGE_THICKNESS_DIVISOR 0.00285  //INV_边缘_厚度_除数
			
			// Outline color parameters 轮廓的颜色参数
			#define SATURATION_FACTOR 0.6   //饱和因素
			#define BRIGHTNESS_FACTOR 0.8   //亮度因素
			
			// Vertex shader
			v2f vert( appdata_base v )
			{
				v2f o;
				
				o.uv = TRANSFORM_TEX( v.texcoord.xy, _MainTex );
				
				//【裁剪空间的顶点】转换顶点
				half4 projSpacePos = UnityObjectToClipPos( v.vertex );
				//【裁剪空间的法线】把法线从模型空间转化到裁剪空间
				// half4 projSpaceNormal = normalize( UnityObjectToClipPos( half4( v.normal, 0 ) ) );
				//【缩放的法线】边缘厚度*INV_边缘_厚度_除数*裁剪空间的法线  （其实就是沿着法线方向放大了一圈）
				// half4 scaledNormal = _EdgeThickness * INV_EDGE_THICKNESS_DIVISOR * projSpaceNormal; // * projSpacePos.w;
				
				//【后移】法线Z轴加一点点
				// scaledNormal.z += 0.00001;
				//顶点+缩放后的扁平的法线
				// o.pos = projSpacePos + scaledNormal;
				o.pos = projSpacePos;
				
				return o;
			}
			
			// Fragment shader
			float4 frag( v2f i ) : COLOR
			{
				//【漫反射贴图】对原贴图采样
				float4_t diffuseMapColor = tex2D( _MainTex, i.uv );
				
				//【最大通道】比较原贴图的三个通道，取值最大的
				float_t maxChan = max( max( diffuseMapColor.r, diffuseMapColor.g ), diffuseMapColor.b );
				//获取漫反射贴图
				float4_t newMapColor = diffuseMapColor;
				
				//最大通道减小1
				maxChan -= ( 1.0 / 255.0 );
				//【获取最高通道】取（0，1）之间（（漫反射贴图-小于最大通道一点）*255），最后只有最大通道是1，其他通道都是0
				float3_t lerpVals = saturate( ( newMapColor.rgb - float3( maxChan, maxChan, maxChan ) ) * 255.0 );
				//【最高通道不变，加深其他通道】用最大通道 插值 饱和因素*漫反射贴图 和 漫反射贴图，值最高的分量颜色保持不变，其他分量通常是对原分量乘以变暗系数SATURATION_FACTOR后的结果
				newMapColor.rgb = lerp( SATURATION_FACTOR * newMapColor.rgb, newMapColor.rgb, lerpVals );
				
				//【返回最终】（亮度因素*加深后的通道*漫反射贴图，漫反射贴图的透明通道）*颜色*逐像素光源颜色
				// return float4( BRIGHTNESS_FACTOR * newMapColor.rgb * diffuseMapColor.rgb, diffuseMapColor.a ) * _Color * _LightColor0; 
				return diffuseMapColor;
			}
			
			ENDCG
		}
	}
}
