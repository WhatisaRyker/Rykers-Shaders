Shader "Hidden/OKColor/PostProcess"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        [IntRange]_NumOfColors ("Number of colors", Range(1, 32)) = 8
        _LightnessRange("Range available to lightness", Range(0, 1)) = 0.788
        _LightnessOffset("Offset of range available to lightness", Range(0.001, 1)) = 0.37
        _InitSat("Initial Saturation", Range(0, 1)) = 0.707
        _ChromaRange("Range available to chroma", Range(-1, 1)) = 0.541
        _ChromaOffset("Offset of range available to chroma", Range(0, 1)) = 0.568
        _DitherSpread("Dither Spread", Range(0, 1)) = 0.038
        [IntRange]_DitherScale("Dither Scale", Range(0,16)) = 3
    }
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "./include/Okhsv.cginc"
            #include "./include/Bayer.cginc"

            float IsStereo(){
            #if UNITY_SINGLE_PASS_STEREO
            return 2.0;
            #else
            return 1.0;
            #endif
            }

            int _NumOfColors;

            sampler2D _MainTex;
            sampler2D _ScreenTex;

            float _InitSat;
            float _LightnessRange;
            float _LightnessOffset;
            float _ChromaRange;
            float _ChromaOffset;

            float _DitherSpread;
            int _DitherScale;

            float3 getNumColor(float val) {
                float3 outColor = float3(0, 0, 0);
                float lightness = _LightnessRange * val;
                
                return okhsv_to_srgb(float3(frac(_ChromaOffset + (_ChromaRange * val)), _InitSat, lightness + (_LightnessOffset * (1 - _LightnessRange))));
            }

            fixed4 frag (v2f_img i) : COLOR
            {
                float2 screenPosition = i.uv;
                float dither = GetBayer8(screenPosition.x * _ScreenParams.x/_DitherScale, screenPosition.y * _ScreenParams.y/_DitherScale);
                // sample the texture
                float3 prod = tex2D(_MainTex, screenPosition).rgb * float3(0.2126, 0.7152, 0.0722);
                prod.r = float(prod.r + prod.g + prod.b);
                float4 col = float4(prod.r, prod.r, prod.r, 1);

                col.rgb = getNumColor(col);

                col.rgb = col.rgb + _DitherSpread * dither;
                col = floor((_NumOfColors - 1.0f) * col + 0.5) / (_NumOfColors - 1.0f);

                return col;
            }
            ENDCG
        }
    }
}
