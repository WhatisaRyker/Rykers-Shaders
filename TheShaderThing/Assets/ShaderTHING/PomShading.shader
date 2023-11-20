Shader "RykerPack/PomShading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [IntRange]_VoronTiling("Voronoise Tiling", Range(0, 100)) = 50
        _VoronOffset ("Voronoise Offset", Range(0, 1)) = 1
        _VoronBlur ("Voronoise Blur", Range(0, 1)) = 1
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
            #include "Include/voronoise.cginc"

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

            int _VoronTiling;
            float _VoronOffset;
            float _VoronBlur;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float vorn = voronoise(i.uv * _VoronTiling, _VoronOffset, _VoronBlur);

                // sample the texture
                float4 col = float4(vorn, vorn, vorn, 1);

                return col;
            }
            ENDCG
        }
    }
}
