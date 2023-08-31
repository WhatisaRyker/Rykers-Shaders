Shader "RykerPack/RandomFractal"
{
    Properties
    {
        _CubingScale ("Cubing Scale", float) = 1
        _Displacement ("Displacement Scale", float) = 1
        _TimeScale ("Time Scale", float) = 1
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

            float IsStereo(){
            #if UNITY_SINGLE_PASS_STEREO
            return 2.0;
            #else
            return 1.0;
            #endif
            }

            float _CubingScale;
            float _Displacement;
            float _TimeScale;
            float2 direction[4]  = {
                float2(0, 1),
                float2(0, -1),
                float2(-1, 0),
                float2(-1, 0)
            };

            float2 rand_2_10(in float2 uv) {
                float noiseX = (frac(sin(dot(uv, float2(12.9898,78.233) * 2.0)) * 43758.5453));
                float noiseY = (frac(sin(dot(uv, float2(33.4567,45.3573) * 2.0)) * 34576.9347));
                return float2(noiseX, noiseY);
            }

            float random (float2 uv)
            {
                return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.546793);
            }
 

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            float roundedTime() 
            {
                return round(_Time * (_TimeScale * 60));
            }

            float2 CubePositions(float2 screenPosition) 
            {
                float node_9184 = (_ScreenParams.g/_ScreenParams.r)/IsStereo();
                float2 Scales = float2(_CubingScale, _CubingScale * node_9184);
                float2 closestPoint = (round(Scales * screenPosition) / Scales);
                float2 newPoint = float2(0,0);
                closestPoint += ((frac(rand_2_10(closestPoint)) - 0.5) * (_Displacement/500));
                float2 originalPoint = closestPoint;

                for(int i=0; i < 4; i++) {
                    newPoint = originalPoint + ((Scales * direction[i]));
                    newPoint += ((frac(rand_2_10(newPoint)) - 0.5) * (_Displacement/500));
                    if(distance(newPoint, screenPosition) < distance(closestPoint, screenPosition)) {
                        closestPoint = newPoint;
                    }
                }

                return closestPoint;
            }

            float3 maxSaturation(float3 colorValue) 
            {
                colorValue = colorValue - min(colorValue.r, min(colorValue.g, colorValue.b));
                colorValue = (1 / max(colorValue.r, max(colorValue.g, colorValue.b))) * colorValue;
                return colorValue;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = normalize(float4 (random(CubePositions(i.screenPos.xy / i.screenPos.w) * roundedTime()), random(CubePositions(0.7364545646 + (i.screenPos.xy / i.screenPos.w)) * roundedTime()), random(CubePositions(0.234786845 + (i.screenPos.xy / i.screenPos.w)) * roundedTime()), 1));
                col.rgb = maxSaturation(col.rgb);
                return col;
            }
            ENDCG
        }
    }
}
