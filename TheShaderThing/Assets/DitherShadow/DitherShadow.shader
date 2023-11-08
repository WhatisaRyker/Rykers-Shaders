// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "RykerPack/DitherShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Header(Shadow Settings)][Space(15)][MaterialToggle]_UseShadows("Use shadows?", int) = 1
        [MaterialToggle]_UseDither("Use dither on shadows?", int) = 1
        _DitherSpread("Dither Spread", Range(0, 0.5)) = 0.18
        [IntRange]_DitherScale("Dither scale", Range(1, 6)) = 1
        _ShadowPower("Shadow Power", Range(0, 1)) = 1

        [Header(Outline Settings)][Space(15)][MaterialToggle]_UseOutline("Use outline?", int) = 1
        _OutlineWidth("Outline width", Range(0.0001, 0.1)) = 0.02
        [HDR]_OutlineColor("Outline Color", Color) = (1, 1, 1, 1)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            ZWrite Off
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _OutlineColor;
            float _OutlineWidth;
            int _UseOutline;

            struct v2f 
            {
                float4 vertex : SV_POSITION;
            };

            struct appdata 
            {
                float4 vertex : POSITION;
            };

            v2f vert (appdata v) 
            {
                v2f o;
                if(_UseOutline)
                    v.vertex.xyz += _OutlineWidth * normalize(v.vertex.xyz);

                o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
                return _OutlineColor;
            }
            
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "include/Bayer.cginc"
             
            sampler2D _MainTex;
            float4 _MainTex_ST;

            uniform float4 _LightColor;

			uniform float3 _MainLightPosition;

            int _UseDither;
            int _DitherScale;
            float _DitherSpread;
            float _ShadowPower;



            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 diff : TEXCOORD1;
                float4 grabPos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                

                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                o.diff = nl * _LightColor0;
                o.diff.rgb += ShadeSH9(half4(worldNormal, 1));

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenPosition = i.grabPos.xy / i.grabPos.w;
                float dither = GetBayer8(screenPosition.x * _ScreenParams.x/_DitherScale, screenPosition.y * _ScreenParams.y/_DitherScale);

                float3 diff = i.diff.rgb * float3(0.2126, 0.7152, 0.0722);
                fixed shade = float(diff.r + diff.g + diff.b);
                shade = ((shade - 1) * _ShadowPower) + 1;
                if(_UseDither) 
                {
                    shade += _DitherSpread * dither;
                    shade = floor((2.0f - 1.0f) * shade + 0.5) / (2.0f - 1.0f);
                }

                fixed4 col = tex2D(_MainTex, i.uv);
                col *= shade * _LightColor0;
                return col;
            }
            ENDCG
        }
    }
}
