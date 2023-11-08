Shader "RykerPack/OKColor/Object Posterization"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        //_DitherTex ("Dither Noise", 2D) = "white" {}
        [IntRange]_NumOfColors ("Number of colors", Range(1, 32)) = 8
        _LightnessRange("Range available to lightness", Range(0, 1)) = 0.788
        _LightnessOffset("Offset of range available to lightness", Range(0.001, 1)) = 0.37
        _InitSat("Initial Saturation", Range(0, 1)) = 0.707
        _ChromaRange("Range available to chroma", Range(-1, 1)) = 0.541
        _ChromaOffset("Offset of range available to chroma", Range(0, 1)) = 0.568
        _DitherSpread("Dither Spread", Range(0, 1)) = 0.038
        [IntRange]_DitherScale("Dither Scale", Range(0,16)) = 3
        [MaterialToggle]_UseShadow("Use Shadow?", int) = 1
        _ShadowPower("Shadow Power", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "./include/Okhsv.cginc"
            #include "./include/Bayer.cginc"

            float IsStereo(){
            #if UNITY_SINGLE_PASS_STEREO
            return 2.0;
            #else
            return 1.0;
            #endif
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            int _NumOfColors;

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                fixed4 diff : COLOR0;
                float4 grabPos : TEXCOORD1;
            };

            sampler2D _DitherTex;
            float4 _DitherTex_TexelSize;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _InitSat;
            float _LightnessRange;
            float _LightnessOffset;
            float _ChromaRange;
            float _ChromaOffset;

            float _DitherSpread;
            int _DitherScale;
            float _ShadowPower;
            int _UseShadow;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);

                if(_UseShadow) {
                    half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                    o.diff = nl * _LightColor0;

                    o.diff.rgb += ShadeSH9(half4(worldNormal,1));
                }
                
                return o;
            }

            float3 getNumColor(float val) {
                float3 outColor = float3(0, 0, 0);
                float lightness = _LightnessRange * val;
                
                return okhsv_to_srgb(float3(frac(_ChromaOffset + (_ChromaRange * val)), _InitSat, lightness + (_LightnessOffset * (1 - _LightnessRange))));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenPosition = i.grabPos.xy / i.grabPos.w;
                float dither = GetBayer8(screenPosition.x * _ScreenParams.x/_DitherScale, screenPosition.y * _ScreenParams.y/_DitherScale);
                // sample the texture
                float3 prod = tex2D(_MainTex, i.uv).rgb * float3(0.2126, 0.7152, 0.0722);
                prod.r = float(prod.r + prod.g + prod.b);
                float4 col = float4(prod.r, prod.r, prod.r, 1);
<<<<<<< Updated upstream
                col *= ((i.diff - 1) * _ShadowPower) + 1;

                
=======
                if(_UseShadow) {
                    col *= ((i.diff - 1) * _ShadowPower) + 1;
                }
                //float dith = tex2D(_DitherTex, screenPosition);
    	        //float mixAmt = frac(col) < dith;
                //float3 c1 = getNumColor(col);
                //float3 c2 = getNumColor(min(col + (1 / _NumOfColors), 1));
                //col.rgb = lerp(c1, c2, mixAmt);
>>>>>>> Stashed changes
                col.rgb = getNumColor(col);

                col.rgb = col.rgb + _DitherSpread * dither;
                col = floor((_NumOfColors - 1.0f) * col + 0.5) / (_NumOfColors - 1.0f);

                return col;
            }
            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
