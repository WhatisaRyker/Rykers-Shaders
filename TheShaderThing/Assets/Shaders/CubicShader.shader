Shader "RykerPack/CubicShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CubingScale ("Cubing Scale", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _CubingScale;

            float4 CubePositions(float4 vertexPos) {
                return (round(_CubingScale * vertexPos) / _CubingScale);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = CubePositions(v.vertex);
                o.vertex = UnityObjectToClipPos(o.vertex);
                o.vertex = CubePositions(o.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
