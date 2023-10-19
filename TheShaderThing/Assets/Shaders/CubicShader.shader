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

        Pass
        {
            Tags {"LightMode" = "ShadowCaster"}
            ZWrite On
            CGPROGRAM
            #pragma vertex vert_shadow
            #pragma fragment frag_shadow
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityShadowLibrary.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;


            struct v2f_shadow
            {
                V2F_SHADOW_CASTER_NOPOS UNITY_POSITION(pos);
                float2  uv : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            v2f_shadow vert_shadow(appdata_tan v)
            {
                v2f_shadow o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            float4 frag_shadow(v2f_shadow i) : SV_Target
            {
                fixed4 texcol = tex2D(_MainTex, i.uv);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
