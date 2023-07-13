Shader "Unlit/DepthOfField"
{
    Properties
    {
        [IntRange]_BlurQuality("Blur Quality", Range(0, 100)) = 3
        [Range]_BlurRadius("Blur Intensity", Range(0, 5)) = 4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        GrabPass 
        {
            "_RenderTexture"
        }

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
                float focusDistance : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _RenderTexture;
            float4 _MainTex_ST;

            float _BlurQuality;
            float _BlurRadius;

            float4 randomCirclePoint(float4 input, float4 seed, float intensity) 
            {
                float Pi = 6.28318530718;
                float3 output = ((hashOld33(seed.xyz)));
                input.xyz += float3(output.x * cos(output.y * Pi), output.x * sin(output.y * Pi), 0) * (intensity / 100);
                return input;
            }

            float GetFocusDistance() //sampler2D texture, float scanRadius, float scanPoints 
            {
               return UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, float2(0.5, 0.5)))
            }

            float4 GetBlurAndColor(sampler2D texture, float depthWeight, float depthIntensity, float blurLeniency) 
            {

            }

            float4 ApplyBlur (sampler2D Texture, fixed4 uv)
            {
                    float Pi = 6.28318530718; // Pi*2

                // GAUSSIAN BLUR SETTINGS {{{
                float Directions = 16; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
                float Quality = _BlurQuality; // BLUR QUALITY (Default 4.0 - More is better but slower)
                float Radius = _BlurRadius / 10; // BLUR SIZE (Radius)
                // GAUSSIAN BLUR SETTINGS }}}
                // Pixel colour
                float4 Color = tex2Dproj(Texture, uv) / (Quality * Directions);

                // Blur calculations
                for( float d =0.0; d < Pi; d += Pi/Directions) {
                    for(float i=1.0 / Quality; i <= 1.0; i += 1.0 / Quality) {
	            		Color += clamp(tex2Dproj( Texture, uv + float4(cos(d),sin(d), 0, 0)*Radius*i), 0, 1) / (Quality * Directions);
                    }
                }	
                return Color;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.focusDistance = GetFocusDistance();
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col;
                return col;
            }
            ENDCG
        }
    }
}
