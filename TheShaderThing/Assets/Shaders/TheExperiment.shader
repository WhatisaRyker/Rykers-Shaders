Shader "RykerPack/TheExperiment"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Size ("SizeThing", float) = 1
        _Flatten ("Flatten", float) = 1
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
            float _Size;
            float _Flatten;

            v2f vert (appdata v)
            {
                v2f o;
                float dist = distance(_WorldSpaceCameraPos, mul(unity_ObjectToWorld, float4(0.0,0.0,0.0,1.0)));
                float4 relPos = mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, v.vertex));
                float4 objectOrigin = mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(0.0,0.0,0.0,1.0)));
                float4 distToOrigin = objectOrigin - relPos;
                relPos.z = (((_Flatten * distToOrigin.z)) + dist);
                v.vertex = mul( unity_WorldToObject, mul(unity_CameraToWorld, relPos));
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
