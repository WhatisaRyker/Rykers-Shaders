Shader "Unlit/PixilateShader"
{
    Properties
    {
        [Range]_Downsize("Downsizes", range(0, 0.5)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        GrabPass {
            "_Sample"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"

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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 grabPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _Sample;
            float _Downsize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.grabPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;
                float2 sceneUVs = (i.grabPos.xy / i.grabPos.w);
                float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1) );
                float node_735 = trunc((distance(_WorldSpaceCameraPos,objPos.rgb)/_Downsize));
                float node_9184 = (node_735*((_ScreenParams.g/_ScreenParams.r)/IsStereo()));
                float3 emissive = tex2D( _Sample, float2(floor(sceneUVs.r * node_735) / (node_735 - 1),floor(sceneUVs.g * node_9184) / (node_9184 - 1))).rgb;
                return float4(emissive, 1);
            }
            ENDCG
        }
    }
}
