// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "RykerPack/DitherShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Header(HDR Settings)][Space(15)][MaterialToggle]_UseHDR("Use HDR?", int) = 1
        [HDR]_HDRColor("HDR Color", Color) = (1, 1, 1, 1)
        _HDRMask("HDR Mask", 2D) = "white" {}
        [MaterialToggle]_UseBaseColor("Use base color as hdr color?", int) = 1
        [MaterialToggle]_UseColorTint("Use HDR color as tint?", int) = 1

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
            sampler2D _HDRMask;

            uniform float4 _LightColor;

			uniform float3 _MainLightPosition;

            int _UseDither;
            int _DitherScale;
            int _UseShadows;
            int _UseHDR;
            int _UseBaseColor;
            int _UseColorTint;
            float _DitherSpread;
            float _ShadowPower;
            float4 _HDRColor;

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
                float4 grabPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenPosition = i.grabPos.xy / i.grabPos.w;
                float dither = GetBayer8(screenPosition.x * _ScreenParams.x/_DitherScale, screenPosition.y * _ScreenParams.y/_DitherScale);

                half nl = max(0, dot(i.worldNormal, _WorldSpaceLightPos0.xyz));
                float4 diff = nl * _LightColor0;
                diff.rgb += ShadeSH9(half4(i.worldNormal, 1));

                diff.rgb *= float3(0.2126, 0.7152, 0.0722);
                fixed shade = float(diff.r + diff.g + diff.b);
                shade = ((shade - 1) * _ShadowPower) + 1;

                if(_UseDither) 
                {
                    shade += _DitherSpread * dither;
                    shade = floor((2.0f - 1.0f) * shade + 0.5) / (2.0f - 1.0f);
                }

                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 ogCol = col;
                fixed4 HDR = fixed4(1, 1, 1, 1);

                if(_UseShadows) 
                {
                    col *= shade * _LightColor0;
                }

                if(_UseHDR)
                {
                    HDR.rgb = lerp(_HDRColor.rgb, ogCol, _UseBaseColor);
                    HDR.rgb = lerp(HDR, _HDRColor.rgb * ogCol, _UseColorTint);

                    HDR.a = _HDRColor.a;
                    float4 colorMask = tex2D(_HDRMask, i.uv);
                    
                    col = lerp(col, HDR, colorMask);
                }
                return col;
            }
            ENDCG
        }
    }
}
